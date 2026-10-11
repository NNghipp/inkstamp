# Backend unblock evidence

Updated 2026-10-08 (Asia/Saigon). Folder date follows the requested evidence path.

**CORE ANDROID E2E: CLOSED (verified DEV path). GOOGLE AUTH E2E: DEFERRED.
PRODUCTION RELEASE: NOT READY.**

Final full real-UI A/B run: PASS1/1, elapsed5:01, exit0, completed20:56:07 UTC+7.
Authoritative safe log: `e2e-2026-10-08T13-56-07-107Z.log`.
All required Friend Graph/custom/ALL/Inbox/read/Detail/Calendar/retry/revoke/block
gates passed together, with real cloud Auth, DEV Firestore, real Camera,
authenticated Cloudinary uploads and production repository implementations.
No fake repository/auth/publish was used. Local callable/gateway and fault proxy
were intentionally DEV-only; no deployed Functions, billing change or Google E2E.

Screenshots: custom/all/retry Camera return, received Inbox/Detail, selected-day
Calendar, revoked Detail. Calendar and revoked Detail inspected visually; revoked
screen shows only unavailable state (no image/sender). Signed full-image HTTP200
and unsigned image denial verified in the test, independently of early image-loading
screenshots. Old signed URL after sender deletion returned404; block residual
signed-URL/cache window is not claimed eliminated.

## Verified regression — 2026-10-08

| Suite | Actual result |
|---|---|
| Flutter full suite | PASS 98/98, including two Camera lifecycle and four current-UID auth stream regressions |
| Enabled DEV-auth | PASS 7/7 |
| Camera / post-capture / visual regression | PASS 24/24 after both lifecycle regression additions |
| Firestore Rules emulator | PASS 7/7 |
| Firestore cursor pagination emulator | PASS 8/8 |
| Functions unit tests | PASS 29/29; 15 emulator-only tests skipped here, passed separately above |
| Gateway | PASS 29/29; TypeScript clean |
| Functions build / ESLint | PASS |
| Flutter analyzer | No issues found |
| Existing five PNG goldens | SHA256 unchanged; no golden updates |
| Live callable authentication | Real cloud Firebase token accepted; missing/forged signature rejected with HTTP 401 |

Regression selection now contains 24 cases, not the historical 21; actual test output is the source of the count.

### Backend-phase files

Mobile: new `lib/core/config/functions_backend.dart`, debug manifest/network-security resource; Firebase authentication/friend/stamp repository callable factories; Cloudinary upload/delivery App Check selection; shared pagination validation; integration `backend_e2e_test.dart`; backend guard/pagination tests. Camera controller/screen lifecycle sequencing and its regression tests changed only after real lifecycle failures, not for visual redesign. New `features/authentication/data/repositories/current_auth_profiles.dart` + `test/features/authentication/current_auth_profiles_test.dart` guard stale auth/profile events after UID switch; common auth stream wiring updated, Google sign-in methods/DEV login guards unchanged.

Functions: `package.json` build entry point; `src/config/callable-security.ts`; shared `require-auth.ts` and awaited callers; friendships/moderation; stamp publish/manage/revoke-media; callable-auth/stamp-backend/friend-block-policy/delivery-pagination tests; secure probe, fixture seeder, E2E runner and fault proxy scripts.

Gateway (earlier backend continuation): authenticated upload signature endpoint/type; paginated available-delivery and active-owner authorizer; focused signature/authorizer/worker tests. Docs: this report, `BACKEND_DEV_UNBLOCK.md`, `testcase.md`. Ignored local runtime credentials/config are not source artifacts. Other dirty files existed before this backend phase and are not claimed as these changes.

## Implementation and scope

Callable blocker: Spark project has no deployed callable Functions. Local entry point also previously pointed at a nonexistent build file. Selected Functions Emulator with real DEV Firebase Auth/Firestore and the existing local gateway, not a duplicate business backend. No billing upgrade, Functions deployment, Rules relaxation, Google auth work, or UI redesign.

Gateway previously consumed only the first REST delivery page and ignored delivery status. It now follows `nextPageToken`, accepts available deliveries only, and checks active owned stamps. Mobile keeps 25-row cursor pagination with timestamp + document-ID ordering; invalid cursors are rejected. Real DEV pagination fixtures: 126 controlled rows, identical timestamps; fixtures are not real camera publishes. Product fan-out remains at most 50 recipients, distinct from lifetime Inbox pagination.

Publish atomically creates stamp, request ledger, and deterministic deliveries; a retry returns the original stamp. Sender revoke retains IDs/status timestamps and retries authenticated full/thumbnail deletion through the existing gateway. Block clears friendship/Close Friends and revokes historical deliveries; unblock restores neither friendship nor old content. A blocked peer cannot replace the original blocker.

Production security remains enforced. Local mode explicitly verifies real Firebase ID tokens (including revoked/disabled user checks) because emulator context alone is insufficient. Local App Check bypass is restricted to explicit DEV emulator mode/project; it is not production attestation evidence.

Previously issued media URLs/cache have a residual window (signed URL up to 300 seconds; client cache four minutes). Block does not destroy shared assets. Sender revoke attempts authenticated asset deletion, but CDN invalidation and already-saved bytes cannot be guaranteed retractable.

## Historical Android A/B attempts

First 2026-10-08 real-UI run: Friend Graph PASS, then overall FAIL due to `CameraException(Disposed CameraController)` during Camera → Preview. The preview was visible, but custom send did not complete. Fix: detach preview and wait for that frame before disposing native controller; no Camera visual change. Regression and a new disposal-order test are being rerun before the next Android attempt. Safe output is written to `e2e-safe-output.log` on completion; later runs also retain timestamped logs. No secrets or signed media URLs are retained in those logs.

Second real-UI run: Friend Graph PASS, visible real Preview, no disposed-controller exception; overall FAIL waiting for URL `/camera/preview`. GoRouter's imperative `push` does not reflect that URL by default. The integration test now checks actual visible Preview/Camera widgets and taps Calendar day semantics; production router behavior is unchanged. Third attempt in progress.

Third/fourth attempts: Friend Graph and actual custom Camera → Preview recipient B → authenticated upload → publish → Camera return → draft cleanup PASS (see `custom-camera-return.png`); overall FAIL at the next B login, before pagination began. Lifecycle review found synchronous provider mutation during Camera unmount; suspend on widget disposal now runs in a microtask. A dedicated widget-unmount regression was added. These partial successes do not close the remaining gates.

Fifth attempt: real Friend Graph, custom send, B login, 126 cloud fixture pagination, gateway authorization beyond100, Inbox unread/read persistence, shared Detail and protected media download PASS; unsigned media URL denied. Real Calendar day tap/date/thumbnail PASS, but opening shared Detail by tapping repeated sender-name text timed out. Overall FAIL. Next attempt targets the exact stamp's archive photo and scrolls it into view; no production UI change. `calendar-selected-day.png` was visually inspected and shows the actual UTC+7 day/real thumbnail.

Sixth attempt: all preceding gates including actual Calendar day-tap → exact shared Detail PASS. Overall FAIL with a Flutter automation assertion while selecting ALL on the next Preview, before ALL publish. Recipient automation now targets the explicit labelled button semantics, with safe Flutter diagnostic logging. ALL/retry/revoke/block remain pending a complete real-UI run.

Seventh attempt identified the ALL failure: test-only `container.listen(postCaptureControllerProvider)` kept an auto-dispose provider alive after Preview closed, retaining `sent` and the `Đã gửi` button label. Production UI normally releases that provider. Removed this artificial listener, not reset/mock business state. Previous real-UI gates remain partial PASS; next complete attempt pending.

Eighth attempt: custom/pagination/Inbox/read/Detail/Calendar again PASS; actual ALL upload/publish/cleanup and Camera return completed (`all-camera-return.png`). Overall FAIL on next Camera readiness, after automation immediately navigated Home and reopened Camera while native reinitialization could still be in flight. Next run waits for ready after each Preview return and stays on Camera between ALL and retry, matching consecutive-capture use. Rapid tab-switch/native initialization overlap remains a separate release-hardening concern; not claimed verified by this core path.

Ninth attempt: real-UI ALL exactly-one delivery and real commit/lost-response retry exactly-one stamp/delivery PASS, including ready Camera return/cleanup. Revoke transaction, double cleanup, owner fresh-URL403, recipient Inbox/Calendar/detail repository hiding, fresh resolver denial and old-URL denial passed before UI assertion. Overall FAIL because the global sender-name finder counted unrelated Home content behind a transition; unavailable Detail itself was visible. Scoped that assertion to the actual Detail subtree and waited for transition. Final negative callable assertions now require `permission-denied`, not any exception.

Tenth attempt failed a ready-session assertion during repeated A/B login, before capture. Independent Auth REST login/probe still PASS. Inspection identified a stale-auth-event risk: old profile results/errors or queued null events could clear the new UID's session. Shared auth profile stream now drops stale events/errors and preserves genuine current-user errors/logout; four targeted tests PASS (full98/98, analyzer clean). Google sign-in methods/DEV guards untouched.

Controlled fixture maintenance before the next attempt: explicit `--reset-test-a-friend-quota` with project/known A/B UID/profile validation reset ONLY Test A's current DEV `friendRequests.count` from19 to0, preserving other quota fields, product20/day limit, and all other users/projects. Original document saved in `test-a-quota-before-*.json`; reset uses update-time precondition. This is trusted admin test-fixture setup, not a client quota bypass or production behavior.126 pagination fixtures reseeded; still not real publishes.

Previous repository/controller-oriented run passed Friend Graph, custom capture/upload/publish, 126-row pagination, Inbox/read/Detail/media download, Calendar date, ALL, lost-response retry, and sender revoke (old asset URL HTTP 404). The final unblock timed out after a Functions watcher restart: overall FAIL, not a completed Core gate. A later real-UI run was interrupted; no PASS is claimed for it.

The failures above are historical attempts, not the final result. The subsequent
full run passed all gates together and closed Core for this DEV configuration.

Ordinary DEV APK restored: debug build (normal Pub/plugin regeneration), adb
install-r Success, launched normal Welcome → Sign in; actual DEV A/B controls
visible (`ordinary-dev-apk.png`, `ordinary-dev-sign-in.png`). Local Functions5001
and gateway8787 remain running on loopback with adb reverse; fault proxy5002 closed.
Runtime credential file absent; evidence logs contain zero password/JWT matches.
Emulator `/data` has8.8G free; original AVD untouched. APK:
`D:/stampcard/apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`.
SHA256 `7223B898A9A22D09DD57A8B41969B0C6EC009CCE81015145E8063139D409A5BA`.
Final analyzer clean and `git diff --check` passed. No billing/API enablement,
deployment, release approval or Google/Apple auth test was performed.

Remaining release blockers:
production backend/region/gateway/App Check configuration, Google auth, rapid
tab-switch/native initialization hardening and other production release gates.
Media residual/cache/saved-byte limits remain documented. Implementation/configuration
details: [BACKEND_DEV_UNBLOCK.md](../../../BACKEND_DEV_UNBLOCK.md).

## Requested 29-field status register

| # | Field | Result / evidence |
|---|---|---|
| 1 | Callable blocker | No deployed callable path on Spark; previous local build entry point incorrect |
| 2 | DEV backend choice | Local Functions Emulator + existing gateway; real DEV Auth/Firestore |
| 3 | Modified files | Backend-phase file groups above; unrelated dirty work preserved |
| 4 | Gateway pagination | Follow REST nextPageToken; available recipients / active owner only |
| 5 | >100 deliveries | PASS real cloud126 fixtures, tie order/no duplicates/skips; gateway beyond100 PASS; fixtures not camera publishes |
| 6 | Revoke | Existing endpoint/status/revokedAt; sender-only transaction; retry full/thumb gateway cleanup |
| 7 | Block/revoke policy | Revoke historical deliveries both directions; no restore on unblock; old-URL window documented |
| 8 | Idempotency | Atomic stamp/request/delivery commit; deterministic IDs; commit-response-loss retry test |
| 9 | Security | Real ID-token verification; forged/missing rejected; Rules unchanged; strict local-mode guard |
| 10 | Flutter | PASS98/98 |
| 11 | DEV-auth | PASS7/7 |
| 12 | Regression | PASS24/24 |
| 13 | Rules | PASS7/7; cursor emulator separately PASS8/8 |
| 14 | Functions | PASS29/29; build/lint clean; 15 emulator-only skips passed separately |
| 15 | Gateway | PASS29/29; TypeScript clean |
| 16 | Analyzer | No issues found on latest completed analyze |
| 17 | Goldens | Five original SHA256 values unchanged; visual tests PASS |
| 18 | Friend Graph E2E | PASS in final full real-UI run |
| 19 | Custom send E2E | PASS real shutter/Preview/custom B/upload/publish/Camera return/cleanup |
| 20 | ALL E2E | PASS real UI: actual ALL send, ready Camera return/cleanup, exactly one B delivery |
| 21 | Inbox/read/Detail E2E | PASS full real-UI run: unread/read persisted, protected media HTTP200, unsigned URL denied |
| 22 | Calendar E2E | PASS full real-UI run: UTC+7/date, actual selected-day tap and exact shared Detail |
| 23 | Retry E2E | PASS real UI: commit then lost response, preserved draft/files, retry one stamp/delivery |
| 24 | Block E2E | PASS full run; B cannot replace/unblock A's block; no friendship/history restoration |
| 25 | Revoke E2E | PASS full run; sender-only, double cleanup, fresh owner URL403, B hidden/denied, old URL404, unavailable UI no crash |
| 26 | Core Android E2E | CLOSED for documented DEV path |
| 27 | Google Auth E2E | DEFERRED; untouched |
| 28 | Production release | NOT READY |
| 29 | Remaining blockers | Ordinary APK restored; production configuration/auth/release gates, media residual window, rapid Camera-tab hardening |
