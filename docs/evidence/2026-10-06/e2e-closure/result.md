# Android E2E closure attempt — 2026-10-06

Milestone: **OPEN**. No authenticated two-account E2E case was executed or marked PASS. This report supersedes the environment blockers in the 2026-10-05 report, not its historical test evidence. No UI/product source was changed, no goldens regenerated, no fake account/token/repository used.

## Environment and scope

- Repository: `D:\stampcard`; mobile: `apps/mobile`.
- Firebase DEV: `inkstamp-dev`, display name `Inkstamp Development`, project number `648356618900`, project state ACTIVE. Verified using `firebase projects:list` and mobile `firebase_options.dart` / `firebase.json`. No `.firebaserc` exists; every cloud command specified the project explicitly.
- Android: `InkStamp_E2E_API_36_1`, serial `emulator-5554`, model `sdk_gphone64_x86_64`, actual API 36, timezone `Asia/Bangkok` (UTC+07, matching the requested local offset).
- Original `Medium_Phone_API_36.1` / `Medium_Phone.avd` was preserved, including userdata/snapshots. Previous measured free space: 393M. No uninstall, clear-data, wipe, snapshot deletion or repeated Flutter install fallback was performed.
- Separate clean AVD created on D: with a 12G data partition. After boot: 11G free; after app installation: **9.4G free** (`df -h /data`: 12G total, 2.0G used, 18%). Original AVD capacity itself is not fixed; future testing must use the new AVD.
- APK built with `flutter build apk --debug --no-pub --target-platform android-x64 --dart-define=MEDIA_GATEWAY_BASE_URL=http://127.0.0.1:8787`. DEMO_MODE was not enabled. `adb install -r` succeeded and `com.inkstamp.app/.MainActivity` became the resumed activity. This proves installation/launch, not successful Firebase sign-in or full app initialization.
- Baseline was verified before environment changes. Existing unrelated dirty-worktree changes were preserved.

## Firestore deployment

Authorized DEV-only command:

```powershell
firebase deploy --only 'firestore:rules,firestore:indexes' --project inkstamp-dev --non-interactive
```

Exit 0: Rules compiled/uploaded/released; indexes deployed for `(default)`. No Functions deployment, billing change, public Worker deployment or production mutation. The user's current explicit Rules/index deployment request takes precedence over older no-deployment DEV operating notes.

Read-only Firestore API verification after deployment confirmed **all five indexes READY** (initially CREATING; queries were not tested against incomplete indexes):

| Collection group | Index ID | State |
|---|---|---|
| friendships | CICAgJim14AK | READY |
| deliveries | CICAgOjXh4EK | READY |
| stamps | CICAgJj7z4EK | READY |
| deliveries | CICAgJjF9oIK | READY |
| stamps | CICAgJiUpoMK | READY |

CLI credentials were used in-process only for admin read checks, never as app ID tokens. Rules tests rerun after deployment: **7/7 PASS**, and again at final verification: **7/7 PASS**. Local Rules tests are not an authenticated mobile query E2E result.

## Gateway smoke evidence

Wrangler 4.125.0, existing DEV project configuration, no remote bindings. Used the Cloudflare/Wrangler skill workflow for local-only operation and secret handling. Cloudinary configuration keys are present and non-placeholder; values were not printed or persisted. Presence/health does not prove Cloudinary credentials work.

```powershell
# Working directory: D:\stampcard\workers\media-gateway
.\node_modules\.bin\wrangler.cmd dev --local --ip 127.0.0.1 --port 8787 --log-level warn --show-interactive-dev-session false
adb -s emulator-5554 reverse tcp:8787 tcp:8787
```

Sanitized observed responses:

```text
Host GET /health: HTTP 200
Emulator GET /health via adb reverse: HTTP 200
Body: {"status":"ok","service":"inkstamp-media-gateway"}
Host POST /v1/media/upload-signatures, no Authorization: HTTP 401
Body: {"error":"Authentication is required."}
```

Emulator smoke used a real HTTP request via Android `toybox nc`; no fixture gateway was substituted. Upload route reachability/auth rejection PASS; valid-token acceptance, App Check, Cloudinary upload/delete, signed delivery download and callable publish remain **BLOCKED**.

At handoff the local gateway is running at `http://127.0.0.1:8787`; it is not publicly exposed. It must remain running/restart for later tests, and adb reverse must be recreated if the emulator restarts. No scheduled monitor was created.

## Account and backend blockers

1. User confirmed no two dedicated Google DEV accounts exist. App uses Google Sign-In; creating Firebase Admin users or Auth-emulator identities does not reproduce that path. No personal Google account was used. Creating usable Google accounts can require human verification/OTP; user must complete those steps and sign A/B into the emulator without sending passwords/tokens to chat.
2. `firebase functions:list --project inkstamp-dev --json` failed. A sanitized authenticated read of Cloud Functions v2 in `asia-southeast1` returned **403 SERVICE_DISABLED** for `cloudfunctions.googleapis.com`: API has not been used or is disabled. Deployed callable inventory/readiness therefore not verified. Do not infer this means zero deployed Functions; the API cannot list them. No API enablement, billing upgrade or Functions deployment was attempted.
3. Source configuration requires review once the DEV backend is approved: `functions/src/config/runtime.ts` declares `asia-southeast1`; Flutter friend/stamp repositories use `FirebaseFunctions.instance` without an explicit region. This is a source-level configuration risk, not a reproduced authenticated E2E failure; no change was made under the verified-bugs-only constraint.
4. Debug App Check must be configured by the authorized DEV project owner for authenticated callable testing. No debug token was extracted, printed or saved; App Check enforcement was not weakened.

## Required E2E case register

Environment **E1** for every row: `inkstamp-dev` + local gateway, new AVD `InkStamp_E2E_API_36_1`, `sdk_gphone64_x86_64`, API36, UTC+07. Evidence for every row: this file, sections Account/backend blockers and Gateway smoke. No delivery/stamp IDs or real capture screenshots exist for this run. **B1** = real A/B sessions missing and callable backend not ready; **B2** = B1 plus gateway authorization/revocation gaps. Actual "not executed" is not a failure observation and not PASS. Earlier automated coverage remains separate.

| ID | Scenario / A-B role | Env | Expected | Actual / notes | Status |
|---|---|---|---|---|---|
| AUTH-A | A Google sign-in/profile | E1 | Dedicated authenticated A, valid profile | Not executed; no account | BLOCKED — B1 |
| AUTH-B | B Google sign-in/profile | E1 | Dedicated authenticated B, valid profile | Not executed; no account | BLOCKED — B1 |
| FG-01 | A searches B | E1 | Correct B found | Not executed | BLOCKED — B1 |
| FG-02 | A requests B | E1 | One request created | Not executed | BLOCKED — B1 |
| FG-03 | B incoming request | E1 | Correct sender A | Not executed | BLOCKED — B1 |
| FG-04 | B accepts A | E1 | Both become friends | Not executed | BLOCKED — B1 |
| FG-05 | A repeats request | E1 | No duplicate request | Not executed | BLOCKED — B1 |
| FG-06 | A adds B Close Friend | E1 | Persists after navigation/restart | Not executed | BLOCKED — B1 |
| FG-07 | A removes B Close Friend | E1 | State updates/persists | Not executed | BLOCKED — B1 |
| FG-08 | B rejects A, safe separate state | E1 | Request rejected per policy | Not executed; no pair reset attempted | BLOCKED — B1 |
| FG-09 | A blocks B | E1 | Backend block policy enforced | Not executed | BLOCKED — B2 |
| FG-10 | A unblocks B | E1 | No automatic restoration of old deliveries/friendship | Source policy only; not executed | BLOCKED — B2 |
| FG-11 | A QR invite, B opens | E1 | Correct invite target/flow | Not executed | BLOCKED — B1 |
| FG-12 | B opens A deep link | E1 | Correct user/invite resolved | Not executed | BLOCKED — B1 |
| CAM-01 | A front/rear capture, flash supported | E1 | Real hardware path, permission/capture work | Not executed this run; previous hardware subset not reused as A/B proof | BLOCKED — B1 |
| CAM-02 | A processed capture | E1 | 1440 square + 512 thumb, orientation/crop correct, EXIF stripped | Not executed on new authenticated session | BLOCKED — B1 |
| CUSTOM-01 | A Preview selects only B | E1 | Real photo/friends; ALL default then unselected; send enabled | Not executed | BLOCKED — B1 |
| CUSTOM-02 | A sends once to B | E1 | One upload/publish; progress; one delivery; return to Camera | Not executed; valid auth/upload/publish unverified | BLOCKED — B1 |
| DRAFT-01 | A successful send cleanup | E1 | Successful draft files removed | Not executed | BLOCKED — B1 |
| DUP-01 | A repeated send interaction | E1 | Exactly one memory/delivery | Not executed | BLOCKED — B1 |
| INBOX-01 | B receives A custom stamp | E1 | One unread stamp, A identity/thumb/time correct | Not executed | BLOCKED — B1 |
| DETAIL-01 | B opens stamp | E1 | Shared Detail, correct full image/identity/title/time | Not executed | BLOCKED — B1 |
| READ-01 | B returns/reopens/restarts | E1 | Read state persisted, no duplicate writes | Not executed | BLOCKED — B1 |
| CAL-01 | B month/day/Detail | E1 | Real received memory grouped correctly, same Detail | Not executed | BLOCKED — B1 |
| CAL-02 | A/B UTC-local midnight boundary | E1 | UTC→UTC+07 date/month correct | Automated case exists, no controlled real timestamp created | BLOCKED — B1 |
| ALL-01 | A sends ALL, B receives | E1 | Exactly one delivery per eligible friend | Not executed; no additional friends | BLOCKED — B1 |
| RETRY-01 | A gateway failure then retry | E1 | Error/draft retained; same draft retry, one publish/delivery; cleanup on success | Not executed; gateway not interrupted without a real session | BLOCKED — B1 |
| BLOCK-01 | A blocks B, B checks old/new content | E1 | Historical deliveries revoked, B excluded from new audience/delivery, unavailable Detail | Source policy only; no runtime proof | BLOCKED — B2 |
| REVOKED-01 | B opens old delivery after A block | E1 | Graceful unavailable UI, no media access leak | Gateway lacks delivery status check; real case not executed | BLOCKED — B2 |
| LIMIT-01 | B opens valid media beyond first100 | E1 | Authorized historical media remains readable | First-page-only scan verified in source; no 101-delivery fixture created | BLOCKED — B2 |

## Block/revoked policy and gateway limit review

- Implemented backend case is **block**: `functions/src/modules/moderation/moderation-functions.ts` revokes available deliveries both directions, removes both Close Friends edges, and sets blocked friendship. Unblock removes the relationship but does not restore old deliveries or friendship. This is inspected policy, not a runtime PASS.
- Inbox/Calendar repositories filter available deliveries; recipient Detail checks available status. Rules allow the owner to read delivery metadata even when revoked. Existing automated tests cover unavailable UI/read protection; they do not prove media revocation.
- Gateway `workers/media-gateway/src/data/firestore_media_authorizer.ts:24` requests `pageSize=100` from a user's delivery subcollection and never follows `nextPageToken`. This is a per-account first-page authorization scan per request, **not** a daily quota/global cap. Normal accumulation beyond100 can leave valid older media unauthorized (403), independently of paginated Inbox/Calendar.
- Same authorizer gathers media IDs without examining delivery `status`. A revoked delivery's IDs can still be authorized by this code. The sender's own-path prefix short-circuit also does not consult stamp status. Previously issued signed URLs/cached bytes need an explicit revocation policy; no leak-free claim is made.
- Separate publicIds request-size limit (1–50) is not the first100 issue and was not removed. No DEV bypass or production safety change was made. These authorization gaps are release blockers requiring focused reproduction/regression/fix under the approved scope, not a fabricated E2E PASS.

## Final regression

| Verification | Baseline | Final | Notes |
|---|---|---|---|
| Flutter analyzer | Clean | Clean, zero issues | `flutter analyze --no-pub` |
| Full Flutter | 75/75 PASS | 75/75 PASS | `flutter test --no-pub` |
| Camera/Preview/goldens focused | 21/21 PASS | 21/21 PASS | Camera directory, post_capture_screen_test.dart, visual_ui_test.dart |
| Rules emulator | 7/7 PASS | 7/7 PASS | `firebase emulators:exec --only firestore --project inkstamp-rules-test 'npm --prefix functions run test:rules'`; JAVA_HOME Android Studio JBR |
| Functions unit suite | 9 PASS, 7 skipped | 9 PASS, 7 skipped | Skipped7 are Rules, executed separately above; not counted twice |
| Gateway unit suite | 14/14 PASS | 14/14 PASS | `npm test` |
| Gateway TypeScript | — | PASS | `npm run build` (`tsc --noEmit`) |
| Android DEV APK | — | Build/install/launch PASS | No uninstall fallback; not A/B E2E |

Five PNG goldens were not edited/regenerated. Final SHA256 inventory:

```text
calendar.png 0F77ADCEAD873CE9DD8C1AD2E7F2718488CEF6B365E3752C8963BB531BC75C44
camera.png   5E253257687011AFA0A3E586E8B29ACD0CAB6E67BB1504E52A3CCD623243BD2A
feed.png     8E87C1F3D7FDD1DD21B2C371ECE1B0A3F837823AF9C02E348BC0ABBE1AA477C3
preview.png  536930BAE1A9FAD93AD2F320D3D1513AC94F47AE33BAC526B85B17C2D218C13E
profile.png  0401AAC4DC89E99B39B53E877DFB1C33D8B52042F723A3B342B965906FAC8892
```

## Changed artifacts and closure decision

This run: `testcase.md`, this report, environment screenshot `emulator-app-launch.png`; external AVD configuration `C:\Users\ngong\.android\avd\InkStamp_E2E_API_36_1.ini` and `D:\InkStampE2E\avd\InkStamp_E2E_API_36_1.avd\config.ini`. Build/emulator/tool-generated artifacts also exist; no product source edit or verified E2E bug fix. Existing previous-phase modifications remain untouched. Firebase Rules/index cloud deployment is a material DEV environment change.

**OPEN**: needs dedicated human-verified Google A/B sessions, authorized DEV callable backend/API/deployment and debug App Check setup, region alignment verification, real authenticated gateway/upload/publish, all core cases above, and gateway pagination/revocation hardening with regression evidence. No production-ready claim and no new product phase started.

Reference workflow sources: [Firestore deployment](https://firebase.google.com/docs/rules/manage-deploy), [index readiness](https://firebase.google.com/docs/firestore/query-data/indexing), [local Wrangler dev](https://developers.cloudflare.com/workers/wrangler/commands/#dev). Actual PASS results above come from commands, not documentation.
