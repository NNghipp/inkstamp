# DEV-auth Android E2E attempt — 2026-10-07

- **CORE ANDROID E2E: OPEN**.
- **PRODUCTION AUTH E2E: DEFERRED** (Google Sign-In A/B not run).
- **PRODUCTION RELEASE: NOT READY**.
- User decision: keep Spark/no new costs. Billing read: false. No billing/API/Functions deployment mutation; only DEV email/password enabled and dedicated Auth users/profiles provisioned. No production mutation.

## Identities / environment

| Role | Real Firebase UID | Email / username |
|---|---|---|
| A | uC6PwltoIQSZ9L54aXDufCxPRLX2 | test-a@inkstamp.dev / test_a |
| B | eZUnkmMGsgQI01NJzSjz8m3oavK2 | test-b@inkstamp.dev / test_b |

DEV project `inkstamp-dev`; AVD `InkStamp_E2E_API_36_1`, serial emulator-5554, model sdk_gphone64_x86_64, actual API36, UTC+07. Restarted existing dedicated AVD, preserved original Medium_Phone AVD. Observed /data after smoke attempts: 9.2G free of12G. No original AVD/session wipe.

Handoff: ordinary debug DEV APK rebuilt with APP_ENV=dev, ENABLE_DEV_TEST_AUTH=true and local gateway URL, installed using `adb install -r` (Success), launched MainActivity. /data **9.0G free** after restoration. Screenshot `dev-app-restored.png` shows restored Welcome; `dev-login-ui.png` shows actual ordinary-app Sign in with Test A/Test B buttons and existing Google/Apple buttons. Screenshots contain no passwords/tokens and are UI/environment evidence, not send/receive proof. The app is left signed out on the DEV sign-in screen.

Profiles contain displayName, username, usernameNormalized, onboardingComplete/onboardingStep, server createdAt/updatedAt. Username documents point to actual UIDs; provisioning rerun preserves passwords and validates ownership. No friend edges/stamps/deliveries were created through admin tooling. Passwords only in ignored local config with restricted ACL; no passwords, auth tokens, private keys or sensitive headers in this evidence.

## Sanitized real Android smoke

Command: `node functions/scripts/run-dev-auth-smoke.mjs` (root).

```text
Private runtime credential transfer completed after test APK installation.
Built build/app/outputs/flutter-apk/app-debug.apk
real DEV Firebase A logout B profile/session smoke
+1: All tests passed!
DEV_AUTH_SMOKE_EXIT=0
```

PASS asserts both real Firebase currentUser UID and InkStamp profile/session stage, then both Firebase and app identity null after each logout. Runs existing FirebaseAuthenticationRepository/SessionController, no mock identity or Auth emulator. Does not exercise the entire production UI or callable/backend flow. Temporary device credential file absent after test/runner cleanup.

Setup attempts were not silently treated as PASS: initial admin configuration payload and credential-helper signature were corrected; first Android smoke failed because runtime credential transfer was ineffective. The runner now uses stdin to a private file, verifies non-empty, and transfers after APK install. First test run used Flutter's default post-test uninstall on the dedicated clean AVD; later runs use `--no-uninstall`. No personal session was present, and no original AVD app was affected. Normal DEV app is restored at handoff.

Release build attempts using --no-pub after integration tests failed on stale debug integration-test plugin registration (including sequential attempts). Local Flutter SDK source confirmed regeneratePlatformSpecificToolingIfApplicable returns early when shouldRunPub=false; release normally filters exclusive dev plugins. Verification therefore uses the normal release build command with tooling regeneration, without modifying generated registrants or adding test plugins to release. A new password-dialog widget test reproduced a controller-after-dispose error; dialog now owns/disposes its controller with its lifecycle, and the regression passes. No frozen Camera/UI golden was changed.

## Case results

For every row: environment is inkstamp-dev, same AVD/model/API36 above; evidence is this file and `docs/DEV_TEST_AUTH.md`. Automated rows are explicitly not real E2E. Callable-dependent rows were not executed, not failed runtime observations. **B1** = user retains Spark; Functions API previously SERVICE_DISABLED and real callables not deployed/available. **B2** = B1 plus unchanged gateway first100/status/revocation gaps.

| ID | A/B role / scenario | Expected | Actual | Status |
|---|---|---|---|---|
| DEV-SETUP | Admin provisions A/B | Real UID/profile/username, local-only credentials | Both created; idempotent rerun | PASS setup |
| DEV-AUTH-A | A login/profile | Real Firebase UID, profile ready | Correct UID, test_a, InkStamp Test A, ready | PASS real Android smoke |
| DEV-LOGOUT-A | A logout | App and Firebase identity null | Both null | PASS real Android smoke |
| DEV-AUTH-B | B after A logout | Correct B profile, no retained A identity | Correct UID, test_b, InkStamp Test B, ready | PASS real Android smoke |
| DEV-LOGOUT-B | B logout | App and Firebase identity null | Both null | PASS real Android smoke |
| GUARD-01 | Release/profile or prod/staging or flag-off | DEV actions unavailable | Policy truth table, default disabled repository and UI tests | PASS automated; build check below |
| GUARD-02 | Wrong project/email | Reject before SDK sign-in | Policy requires exact DEV project/allowlist | PASS automated |
| SWITCH-01 | A→logout→B caches | No cross-account Inbox/Calendar/Friends data | Unit controller integration + stale A friend-load completion rejected | PASS automated, not delivery E2E |
| SWITCH-02 | A draft→logout→B | A photo/recipient references cleared | UID-scoped draft reset asserted in enabled DEV test | PASS automated |
| UI-01 | DEV B button/password dialog | Runtime input invokes existing controller once, no lifecycle exception | Widget regression PASS | PASS automated |
| FG-01 | A searches B | Correct B | Not executed; callable required | BLOCKED B1 |
| FG-02 | A requests B | One request, duplicate prevented | Not executed | BLOCKED B1 |
| FG-03 | B incoming/accept A | Both see accepted friendship | Not executed | BLOCKED B1 |
| FG-04 | A Close Friend add/remove B | Persistent state correct | Not executed | BLOCKED B1 |
| FG-05 | Reject/block/unblock A/B | Current backend policy enforced | Not executed | BLOCKED B1 |
| CAMERA-01 | A real rear/front capture/process | 1440 image,512 thumb,EXIF removed,raw/processed cleanup | Real camera SDK/processor under A's authenticated session; both lenses verified | PASS real Android subset; permission pre-granted |
| CUSTOM-01 | A selects only B/send | One upload/publish/delivery, draft cleanup, Camera return | Not executed; publish requires callable | BLOCKED B1 |
| INBOX-01 | B receives A | Correct sender/thumb/time, one unread item | No real delivery created | BLOCKED B1 |
| DETAIL-01 | B opens received content | Correct shared Detail/media | No real delivery created | BLOCKED B1 |
| READ-01 | B reopen/restart | Persisted unread→read | No real delivery created | BLOCKED B1 |
| CAL-01 | B local day/month/Detail | Correct received-memory grouping | No real delivery created | BLOCKED B1 |
| ALL-01 | A sends ALL→B | Exactly one eligible delivery | Not executed | BLOCKED B1 |
| RETRY-01 | A failed-send/retry | Draft retained, retry one publish/delivery, cleanup | Not executed; no fake success path used | BLOCKED B1 |
| BLOCK-01 | A blocks B/history/audience/new delivery | Backend policy and UI consistent | Source policy only: both-direction revoke, no restoration on unblock | BLOCKED B2 |
| REVOKED-01 | B old content after block | Graceful unavailable UI, no media leak | Gateway still lacks status check; no runtime proof | BLOCKED B2 |
| GOOGLE-01 | Google A/B production provider | Real Google sign-in passes | Not run, explicitly deferred | DEFERRED |

## Changes this phase

- `apps/mobile/lib/features/authentication/domain/dev_auth_policy.dart` — compound constant guard, exact account allowlist.
- Existing authentication interface/Firebase/in-memory repositories — guarded real email/password path, no demo impersonation; password logout without Google initialization; suppress obsolete profile reads after identity changes.
- Existing SessionController — shared repository auth listener, guarded DEV login, clear identity on logout, ignore superseded sign-in completion.
- `presentation/widgets/dev_test_login.dart` and SignInScreen — minimal conditional DEV buttons/runtime password dialog; production buttons unchanged.
- SettingsScreen — conditional DEV logout/switch entry, no default/golden UI change.
- FriendsController — UID-scoped reset and async-generation guards; no test-user business logic.
- StampComposerController — UID-scoped draft reset, preventing A's capture/recipient selections remaining accessible to B. Local stale-file housekeeping remains the existing cleanup policy; this is not send-success cleanup proof.
- `test/features/authentication/dev_auth_test.dart` —7 new automated cases; existing fake repository updated for interface compatibility.
- `integration_test/dev_auth_smoke_test.dart` — real Firebase A/B smoke with private runtime credential loading/removal.
- `functions/scripts/provision-dev-test-users.mjs`, `run-dev-auth-smoke.mjs` — pinned DEV trusted provisioning and secure local runner, not deployed Functions exports.
- This report, `docs/DEV_TEST_AUTH.md`, `testcase.md`.
- Non-sensitive screenshots `dev-app-restored.png`, `dev-login-ui.png`; ignored local credential config is deliberately not part of evidence/source control.

Existing dirty-worktree changes were preserved. No Rules/Functions/gateway product logic edited, no Camera redesign/golden regeneration, no iOS/Apple/DO work. Configuration region mismatch and gateway authorization gaps remain documented, not silently fixed without E2E reproduction.

## Final verification

- Flutter full suite: **82/82 PASS** (75 previous +7 new).
- DEV-flag auth tests: **7/7 PASS**; default suite separately tests disabled path.
- Camera/Preview/golden regression: **21/21 PASS**.
- Rules emulator: **7/7 PASS**.
- Functions: **9 PASS +7 Rules skipped** in plain npm test; those7 executed separately above.
- Gateway: **14/14 PASS**.
- Real Android DEV-auth/camera smoke: **1/1 PASS**, includes A/B profile/UID/logout and A rear/front capture1440/thumb512/empty EXIF/local cleanup. Not successful-send draft cleanup or custom audience E2E.
- Analyzer: zero issues in final run.
- Five PNG goldens untouched; final SHA256 equals 2026-10-06 inventory.

Release guard build / ordinary DEV app restoration observations are recorded below after command completion. A build/absence of DEV strings is supporting evidence, not Google-provider E2E or production certification. Gateway was not running when checked this date (127.0.0.1:8787 connection refused); its14 unit PASS and previous-day health do not prove current authenticated upload readiness.

### Release guard artifact check

Normal `flutter build apk --release --target-platform android-x64 --dart-define=APP_ENV=dev --dart-define=ENABLE_DEV_TEST_AUTH=true` completed successfully (25.5MB) after platform-tooling regeneration, without manually editing generated registrants. Read-only scan of APK `lib/x86_64/libapp.so` found all six DEV markers absent: `DEV only · inkstamp-dev`, `Login as `, `Local test password`, `DEV: Logout / switch test account`, Test A email, Test B email. This supports compile-time exclusion even with DEV flags passed to release. The constant guard and repository rejection are the security mechanism; string absence alone is not a proof of all release behavior. This DEV-project/debug-signed build was not deployed/released and does not satisfy Google E2E or production Firebase/signing setup. Subsequent ordinary DEV APK includes the additional composer UID reset; release marker verification concerns the unchanged auth guard.

## Remaining gates

Core E2E remains OPEN because Friend Graph, custom/ALL publish, delivery/read/Calendar, retry and block/revoked cannot run on the currently unavailable callable backend while the owner retains Spark. Google E2E remains DEFERRED independently. Production release stays NOT READY, also requiring approved backend environment/region, debug App Check for DEV testing, gateway pagination/revocation fixes and actual core evidence. No paid workaround, Rules/App Check bypass, Auth emulator fake users or admin publish/delivery was used.
