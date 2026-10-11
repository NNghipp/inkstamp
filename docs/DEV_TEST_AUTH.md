# DEV-only Firebase test authentication

Purpose: run Android app flows with real, deterministic Firebase A/B identities without waiting for Google accounts. **Google Sign-In E2E is DEFERRED**, not PASS, and remains a production release requirement. No Google sign-in implementation or Firestore Rules were weakened.

## Fail-closed guard

There was no existing flavor/environment abstraction. The implementation extends `AuthenticationRepository`, not a parallel auth service. DEV actions require all of:

1. `kDebugMode` (release **and profile** always disabled).
2. Explicit `--dart-define=APP_ENV=dev` (default is `prod`).
3. Explicit `--dart-define=ENABLE_DEV_TEST_AUTH=true` (default false).
4. Real Firebase initialized; no in-memory test-user fallback.
5. Repository checks actual Firebase app project is exactly `inkstamp-dev` and email is exactly Test A or Test B.

`DevAuthPolicy.compiledEnabled` is a compile-time constant used at UI/controller/repository entry. Release rejects the method before touching Firebase, even with malicious DEV defines. The UI is conditionally constructed, not hidden behind a gesture. Runtime passwords are never dart-defines, source constants, APK assets or log fields. The normal production Google/Apple buttons are unchanged.

An instrumented test APK is not a release artifact. Production builds must use the ordinary `lib/main.dart` entrypoint and production Firebase configuration; the current repository's Firebase options still target DEV. Successful release compilation is not production readiness.

## Trusted setup (DEV only)

Prerequisites: authorized Firebase CLI login, global `firebase-tools`, Node and installed `functions` dependencies. No service-account key needs to be committed. The local tooling uses the existing authorized CLI OAuth session and pins all requests to `inkstamp-dev`.

```powershell
# D:\stampcard
node functions/scripts/provision-dev-test-users.mjs --project inkstamp-dev --provision
```

The tool enables email/password only for DEV, creates two Firebase Auth users if absent, and transactionally reserves usernames/provisions matching Firestore profiles (real UID, displayName, usernameNormalized, createdAt, updatedAt, onboarding complete). This is trusted admin fixture provisioning, not a client Rules bypass or publish/delivery implementation. App requests still use ordinary real repositories and user ID tokens. No test-user special cases were added to Friend Graph.

| Role | Email | Username | Display name |
|---|---|---|---|
| A | test-a@inkstamp.dev | test_a | InkStamp Test A |
| B | test-b@inkstamp.dev | test_b | InkStamp Test B |

New passwords are generated cryptographically and written **only** to root `.env.dev-test-auth.json`, already excluded by `.env.*` in `.gitignore`. Passwords are not printed. Existing passwords are not reset; existing usernames/profile ownership conflicts abort rather than overwrite. The run verified idempotent provisioning. If a pre-existing user has no local password, use the Firebase console to reset that dedicated DEV user manually; do not put credentials in chat/docs.

On this Windows workspace the credential file ACL is restricted to the current user and SYSTEM. Keep these credentials local; never commit/upload the file. On another workstation restrict its permissions too. Keep the admin CLI credential store private.

## Build and login

```powershell
# D:\stampcard\apps\mobile
flutter build apk --debug --no-pub --target-platform android-x64 --dart-define=APP_ENV=dev --dart-define=ENABLE_DEV_TEST_AUTH=true --dart-define=MEDIA_GATEWAY_BASE_URL=http://127.0.0.1:8787
```

Install using `adb install -r` on the dedicated roomy test AVD; do not use an uninstall fallback. The sign-in screen adds `Login as Test A` / `Login as Test B` only in an enabled DEV build. Read the appropriate local password privately and enter it in the obscured dialog. No password is persisted by the UI. Cancel makes no auth request.

To switch: open Cá nhân, scroll to `DEV: Logout / switch test account`, logout, return through ordinary onboarding navigation to Sign in, select the other account. Logout clears controller identity immediately and signs out Firebase; password-only users do not initialize Google Sign-In merely to logout. A/B use the existing profile mapping and auth stream/router. Friend Graph resets on UID changes and ignores stale async responses; draft photo/recipient references also reset. Existing Inbox/Calendar/Detail/History/media dependencies remain UID-scoped. No Firestore listener was introduced.

## Automated and real Android smoke

```powershell
# D:\stampcard\apps\mobile
flutter test --no-pub
flutter test --no-pub test/features/authentication/dev_auth_test.dart --dart-define=APP_ENV=dev --dart-define=ENABLE_DEV_TEST_AUTH=true
```

The default suite verifies exclusion with flags off; the flag-enabled run exercises Test A/B controller login, runtime password UI, external auth changes, logout, and cross-session Inbox/Calendar/Friend Graph isolation. Unit repositories are fixtures, **not E2E proof**.

With dedicated `InkStamp_E2E_API_36_1` running as `emulator-5554`:

```powershell
# D:\stampcard
node functions/scripts/run-dev-auth-smoke.mjs
```

The runner installs the integration APK and transfers credentials only after the test starts, via stdin into the app's private `files/dev-test-auth.json` (mode600). It never passes passwords in command arguments, build defines or external/shared storage. The test performs real Firebase email/password A login/profile/UID → rear/front camera capture/processing → logout → B login/profile/UID → logout. Camera asserts1440 image,512 thumbnail,empty EXIF and temporary-file cleanup; camera permission was granted for this fixture, so permission-dialog UX is not covered. It and the runner remove the temporary device credential file. `--no-uninstall` keeps the APK/data; restore the ordinary DEV APK afterwards. Raw SDK/device logs are not persisted or echoed. This smoke does not test Google, send/delivery or the entire UI flow.

Run native Flutter builds/tests sequentially. After an integration debug build, a release build must regenerate platform tooling (use the ordinary build command without `--no-pub`); this Flutter SDK skips regeneration with `--no-pub`, leaving a debug integration-test registrant incompatible with release dependencies. Do not manually patch generated registrants or add test plugins to release to mask that error.

## Spark boundary / remaining gates

On 2026-10-07 the user explicitly chose **keep Spark, no new costs**. Billing read returned `billingEnabled=false`. No billing account was linked, Functions API enabled or Functions deployed. Auth/profile smoke can pass on Spark; Friend search/mutations, normal profile reservation/onboarding and publish use callable Functions and cannot be completed while that backend is unavailable. Do not replace it with mocks/admin publishing or disable App Check to claim core E2E success.

Before later real core E2E, the owner must approve/prepare a supported DEV callable backend (cloud deployment requires Blaze), configure debug App Check, and verify the callable region. Backend source uses `asia-southeast1`, while current mobile repository defaults have no explicit region: this remains a configuration gate, not a fixed or reproduced E2E claim. Existing gateway first100-delivery/status gaps remain release blockers.

Status and exact evidence: `docs/evidence/2026-10-07/dev-auth-e2e/result.md`.

Firebase references: [Flutter password auth](https://firebase.google.com/docs/auth/flutter/password-auth), [trusted user provisioning](https://firebase.google.com/docs/auth/admin/manage-users), [Functions deployment and Blaze requirement](https://firebase.google.com/docs/functions/get-started).
