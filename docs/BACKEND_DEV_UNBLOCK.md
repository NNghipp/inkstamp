# Spark-compatible DEV backend

Verified continuation — 2026-10-08. Core Android E2E CLOSED for the documented DEV path; Google DEFERRED; production NOT READY. Full real Android A/B run passed; see linked evidence for scope and residual limits.

## Dependency inspection and decision

| Operation | Current path | Blocker |
| --- | --- | --- |
| Sign in/profile read | Firebase Auth + own Firestore user | Working A/B cloud DEV smoke |
| Username search | `findUserByUsername` callable | Cloud callable unavailable |
| Request/accept/reject/remove | Friendship callables | Cloud callable unavailable |
| Close Friends | `updateCloseFriends` callable | Cloud callable unavailable |
| Block/unblock | Moderation callables + delivery revocation | Cloud callable unavailable |
| Upload/delete media | Existing gateway + authenticated Cloudinary | Local gateway must be running |
| Publish/fan-out | `publishStamp` callable | Cloud callable unavailable |
| Inbox/read/Calendar/Detail | Own Firestore deliveries + own sent stamps | Reads work, missing real publish fixture |
| Revoke | Existing `deleteStampForEveryone` | Deletes deliveries, marks deleted, incorrectly cleans legacy Storage instead of Cloudinary |
| Delivery URLs | Gateway verified Firebase JWT → Firestore REST authorization | Reads only first 100 documents; fails to check revoked status |

Evaluated in required order:

1. Direct client Firestore writes: rejected. Existing Rules deliberately deny friendship/stamp/delivery creation and profile mutations. Moving orchestration into clients would require substantial Rules expansion.
2. Existing gateway: retained for media. It has no friendship/publish orchestration, so moving callable business logic would duplicate/rewrite the source of truth.
3. New local backend: unnecessary duplicate transport/business logic.
4. Functions Emulator: selected; executes existing callable handlers locally, no cloud Functions deployment or billing change. Real Firebase Auth and controlled `inkstamp-dev` Firestore remain in use (not emulated).

Firebase documents that non-emulated services in a real project remain live. Only DEV A/B data is in scope. Emulator is not equivalent to production IAM or release validation. [Firebase emulator documentation](https://firebase.google.com/docs/emulator-suite/connect_functions).

## Current findings

- Inbox already uses page size 25, `createdAt DESC` + document ID DESC and `startAfter` values, not offsets. Gateway's 100 is a REST list page size, not fan-out limit.
- Product cap is 50 recipients (`maxFriends`). A publish now atomically writes at most 52 documents: stamp + request + 50 deliveries; >100-recipient fan-out is outside current product policy.
- Existing block revokes old available deliveries in batches of 200 both directions; unblock does not restore old deliveries or friendship.
- Existing publish request ID is UUID v5 of sender and uploaded full/thumb IDs; draft upload attempt is retained on retry.
- Found retry hazard: notification failure after successful fan-out deletes stamp/request but leaves recipient deliveries. This must be fixed before claiming retry safe.
- Existing gateway signs Cloudinary authenticated download URLs with 300-second expiry. Previously issued URLs/cached bytes cannot be instantaneously revoked by a Firestore status update. New URL issuance must reject revoked deliveries; existing URL expiry is a residual window, not immediate protection.

## DEV configuration

Only debug + `APP_ENV=dev` + `BACKEND_MODE=functions_emulator` can select local callable transport. Actual Firebase app must be `inkstamp-dev`. Release/profile ignore these defines. Normal production transport is unchanged, including its existing default region; aligning deployed production region with `asia-southeast1` remains a release configuration gate.

```powershell
# D:\stampcard; do not rebuild Functions while an E2E run is in flight
npm --prefix functions run build
$env:DEV_BACKEND_MODE='functions_emulator'
$env:MEDIA_GATEWAY_BASE_URL='http://127.0.0.1:8787'
firebase emulators:start --only functions --project inkstamp-dev

# Separate terminal, D:\stampcard\workers\media-gateway
.\node_modules\.bin\wrangler.cmd dev --local --ip 127.0.0.1 --port 8787 --log-level warn --show-interactive-dev-session false

# D:\stampcard; dedicated existing emulator must be booted
adb -s emulator-5554 reverse tcp:5001 tcp:5001
adb -s emulator-5554 reverse tcp:8787 tcp:8787
node functions/scripts/seed-dev-pagination.mjs --project inkstamp-dev --seed
node functions/scripts/run-backend-e2e.mjs
```

Ignored `functions/.env.local` was created locally with the two non-secret backend settings above. Recreate from the commands if cloning. No credentials are in it. Gateway retains existing ignored `.dev.vars`; never print/commit it. Runtime A/B credentials remain in ignored `.env.dev-test-auth.json`, transferred through ADB stdin to app-private storage and removed after testing. See [DEV test auth](DEV_TEST_AUTH.md).

Normal DEV build flags: `--dart-define=APP_ENV=dev --dart-define=ENABLE_DEV_TEST_AUTH=true --dart-define=BACKEND_MODE=functions_emulator --dart-define=MEDIA_GATEWAY_BASE_URL=http://127.0.0.1:8787`. SDK automatic host remapping is explicitly disabled because this setup uses ADB reverse to 127.0.0.1. Debug Android network config permits HTTP only for localhost/127.0.0.1; release manifest is untouched.

The integration runner temporarily starts a loopback proxy on 5002 (`DEV_FUNCTIONS_PORT=5002`) to simulate losing a response after actual server commit. It forwards the original Firebase ID token, never fabricates auth. Fault controls require a random per-run secret sent only via the private credential file. Proxy/control endpoints are test scripts, not deployed Functions. Normal DEV APK uses 5001, not the proxy. Runner closes proxy/removes its ADB reverse after testing.

## Auth and security

Local Firebase Functions SDK deliberately skips JWT verification. Our shared `requireAuth` independently calls Admin `verifyIdToken(token, true)` in emulator mode, rejects Auth Emulator identities, wrong projects, missing tokens and UID mismatches, and derives UID only from verified claims. Live read-only probe: real A token → B lookup 200; no token / altered signature → 401. No trust in payload UID/email/username.

App Check attestation is not emulated. Only the explicit local DEV mode disables callable attestation and skips client media attestation loading (test runner had no AppCheckProvider). Gateway DEV enforcement remains its existing disabled setting. Cloud callables still enforce App Check, and non-local mobile builds load the normal token. This phase does NOT validate production attestation or IAM.

Rules remain unchanged. Clients cannot create stamps/deliveries/friendships, revoke another sender's stamp, change a delivery sender/status, or mark another inbox read. Unavailable rows remain owner-readable under the existing Rules; their metadata was already delivered. Fresh Detail returns null and does not render image/sensitive metadata.

## Pagination

Inbox preserves 25 rows per page and `createdAt DESC, document ID DESC`. Fetch 26 to calculate `next`, use timestamp + ID values in `startAfter`, no offsets. Removing the cursor document does not invalidate the value cursor. Page sizes outside 1..100 and malformed IDs fail with ArgumentError. A refresh is needed to remove a row already loaded before a later revoke; subsequent queries filter `status=available`.

Gateway now follows Firestore REST `nextPageToken` until all requested IDs are authorized or records exhausted. Only available deliveries authorize media. Repeated tokens and non-OK responses fail closed; request-local deadline bounds scanning. Owner prefix is no longer sufficient: own media requires an active own stamp, queried with exact media ID and `limit=1`. Large scans can still hit runtime/deadline quotas; these are not an intentional 100-item product cap.

Tests separate trusted pagination fixtures from real publishing. 126 clearly labeled delivery fixtures are seeded ONLY to Test B, same timestamp in 2020, with non-existent private media IDs. They prove real cloud/mobile pagination and gateway authorization beyond the first REST page, NOT 126 captures/uploads/publishes. Existing Cloudinary assets are not fabricated; real custom/ALL/retry tests use real captured uploads. Block revokes those fixture rows as part of normal A/B policy; they remain identifiable for audit.

## Publish and idempotency

Existing UUID v5 of sender + full/thumb uploaded IDs is retained; client retry preserves processed draft, uploaded IDs and audience. Request ledger, active stamp and deterministic `users/{recipient}/deliveries/{stampId}` are created in ONE transaction. No intermediate publishing state or cleanup that can orphan deliveries. Concurrent duplicate calls re-read the request ledger inside that transaction. Accepted friendship versions are read in the same transaction to serialize against block. Push failure is logged without deleting committed data. Retrying a revoked request returns the same identity and never re-creates deliveries.

Current friend send/accept use deterministic pair IDs; Close Friends and unblock now read relationship in their write transaction. A blocked peer cannot overwrite `blockedBy` and then unblock to bypass the original blocker.

## Revoke and block

Reuses `deleteStampForEveryone`, no second revoke endpoint. Sender only; missing stamp is not-found; foreign sender is permission-denied. One transaction retains stamp/delivery IDs, sets existing `status=revoked` and `revokedAt`; double revoke preserves original timestamp. Inbox/Calendar hide unavailable rows; Detail shows “Stamp không còn khả dụng.” No new revocation model field was needed.

After committing revocation, the callable reuses existing owner-authenticated gateway `/v1/media/delete` to destroy full + thumbnail authenticated Cloudinary assets with invalidation. It does not duplicate Cloudinary secrets or delete obsolete Firebase Storage paths. Return `mediaDeleted` reports real cleanup outcome; failure does not undo revoked status. Repeating revoke retries cleanup using retained IDs. Production must configure an HTTPS gateway URL/enforcement before shipping; otherwise cleanup reports false.

Block removes both Close Friends edges and revokes historical available deliveries in batches of 200, both directions. Selected/ALL publishing rejects non-accepted peers. Unblock is blocker-only and restores neither friendship nor revoked deliveries. Block does not delete an asset still used by sender/other recipients.

Security limitation: newly signed URLs are denied immediately after completed revoke/block, but previously issued URLs have up to 300-second expiry and the client may cache one for four minutes. Sender revoke additionally attempts asset destruction (live old URL returned 404 in a completed partial run). CDN invalidation timing is not guaranteed; saved image bytes/screenshots cannot be retracted. Block especially retains this signed-URL residual window. Do not claim instantaneous global erasure or production-ready media protection.

## Verification

Final counts/milestone are recorded in [run evidence](evidence/2026-10-07/backend-unblock/result.md). This document describes implementation, not proof that every E2E gate passed.

Latest full run: real UI Friend Graph, custom and ALL send, Inbox/read/Detail,
Calendar day tap/shared Detail, commit-response-loss retry, sender revoke and
block/unblock PASS together (integration1/1).98 Flutter,7 DEV-auth,24 focused
regression,7 Rules,8 cursor emulator,29 Functions and29 gateway tests PASS.
Existing5 PNG goldens unchanged. Camera changes are lifecycle sequencing only;
auth stream discards stale profile/results/errors and queued logout after UID
switch. Fast tab-switch/native initialization overlap remains release-hardening
work, outside this verified consecutive-capture path.

Fixture seeding is explicit: `node functions/scripts/seed-dev-pagination.mjs
--project inkstamp-dev --seed`. Optional `--reset-test-a-friend-quota` resets ONLY
known Test A's current DEV friend-request counter, after saving the original
document, with an update-time precondition. It does not change20/day product
limit, publish quotas, other accounts or other projects. Never use it as normal
client behavior or production provisioning.
