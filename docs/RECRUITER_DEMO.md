# InkStamp Recruiter Demo

## Fastest Demo Path

For a recruiter, start with the [overview](PORTFOLIO_OVERVIEW.md) and [real/source-labeled visuals](portfolio/MEDIA_INDEX.md), or watch a presenter-led session. No admin account or password sharing is needed to understand the project. A demo recording is not yet available.

For the presenter, the following assumes an already configured workstation; first-time credential setup is not promised to take five minutes.

1. Start local Functions and the media gateway using the commands below.
2. Launch the guarded DEV app; open Get started → Sign in.
3. Select **Login as Test A**; enter its locally configured password privately.
4. After login, open the existing Friends route using the local URI helper below, then **Find friends** → search `test_b`. If necessary send a request; log in as B, reopen Friends, open pending requests and accept A, then switch back to A. If already accepted, verify the relationship rather than sending another request.
5. Open Máy ảnh and capture a photo.
6. In Post-Capture select B, then use Check to send. Wait for confirmation/return to Camera.
7. Cá nhân → scroll to **DEV: Logout / switch test account** → Sign in → **Login as Test B**.
8. Khoảnh khắc → top-right **Hộp thư** icon → refresh Inbox → open A's latest stamp; point out unread/read.
9. Open Lịch, select today's date and open the same memory.
10. Optionally open Friends → B's profile → **Block user**. For unblock, open the existing Blocked users route below. Revoke is backend/E2E-verified; the current Detail menu has no sender-revoke control. Show its existing evidence rather than inventing a menu action or running an admin mutation live.

Post-test A/B friendship may be removed and old deliveries revoked. Prepare/accept the friendship through normal UI before presenting. Never claim unblock restores the old relationship or memories.

### Local Route Helpers

The current four-tab shell has no visible Friends launcher; these existing authenticated routes need presenter navigation. Android's custom-scheme manifest and GoRouter paths were inspected, and the Friends VIEW intent was delivered successfully to the installed app during documentation verification. This verifies intent handling, not an authenticated screen walkthrough or production App Links. Invoke **after login**, since ordinary auth guards redirect signed-out users; generic Friends links are not promised to resume after login.

```powershell
adb -s emulator-5554 shell am start -a android.intent.action.VIEW -d inkstamp:///friends com.inkstamp.app
```

The existing blocked-users route can likewise be addressed by its declared path; this specific intent was not separately run:

```powershell
adb -s emulator-5554 shell am start -a android.intent.action.VIEW -d inkstamp:///settings/blocked-users com.inkstamp.app
```

Resolve this navigation friction before an unguided public demo; no UI wiring or new route was added in this documentation task.

## Workstation Setup

Use a dedicated booted Android emulator (verified ID `emulator-5554`), Flutter/Android SDK, Node 22, Firebase CLI and internet. Replace the device ID only if yours differs. Only authorized maintainers should access `inkstamp-dev`; it is not an open recruiter sandbox.

Configure privately, **before** running the demo:

| File / prerequisite | Purpose |
|---|---|
| `apps/mobile/android/app/google-services.json` | Authorized DEV Android registration for `com.inkstamp.app` |
| `apps/mobile/lib/firebase_options.dart` | Matching DEV Flutter Firebase options |
| `workers/media-gateway/.dev.vars` | Local Cloudinary values; copy the [empty template](../workers/media-gateway/.dev.vars.example), fill privately |
| `.env.dev-test-auth.json` | Private A/B passwords from trusted provisioning; Git-ignored, never printed/committed |
| Firebase CLI authorized session | Local Functions/scripts access real DEV resources; keep CLI credentials private |

See [DEV Auth](DEV_TEST_AUTH.md) for maintainer-only provisioning (`provision-dev-test-users.mjs`). This documentation task does not run provisioning, seed fixtures, reset quotas or mutate the backend. Do not improvise test passwords, reset existing users or ask a recruiter to receive admin credentials.

From the repository root, install existing locked dependencies:

```powershell
npm --prefix functions ci
npm --prefix workers/media-gateway ci
cd apps/mobile
flutter pub get
cd ../..
```

Terminal 1, root:

```powershell
npm --prefix functions run build
$env:DEV_BACKEND_MODE='functions_emulator'
$env:MEDIA_GATEWAY_BASE_URL='http://127.0.0.1:8787'
firebase emulators:start --only functions --project inkstamp-dev
```

Terminal 2, root:

```powershell
cd workers/media-gateway
.\node_modules\.bin\wrangler.cmd dev --local --ip 127.0.0.1 --port 8787 --log-level warn --show-interactive-dev-session false
```

Terminal 3, root:

```powershell
adb -s emulator-5554 reverse tcp:5001 tcp:5001
adb -s emulator-5554 reverse tcp:8787 tcp:8787
cd apps/mobile
flutter run -d emulator-5554 --dart-define=APP_ENV=dev --dart-define=ENABLE_DEV_TEST_AUTH=true --dart-define=BACKEND_MODE=functions_emulator --dart-define=MEDIA_GATEWAY_BASE_URL=http://127.0.0.1:8787
```

Only Functions is emulated. Auth, Firestore and Cloudinary remain live DEV resources. No deployment or billing upgrade is part of this flow. Do not rebuild Functions during a demo/test run.

## APK Alternative

Build from `apps/mobile` with the ordinary entry point:

```powershell
flutter build apk --debug --dart-define=APP_ENV=dev --dart-define=ENABLE_DEV_TEST_AUTH=true --dart-define=BACKEND_MODE=functions_emulator --dart-define=MEDIA_GATEWAY_BASE_URL=http://127.0.0.1:8787
```

With backend/reverse ports ready, from repository root:

```powershell
adb -s emulator-5554 install -r apps/mobile/build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 shell am start -n com.inkstamp.app/.MainActivity
```

The APK is a debug portfolio build, not a production release or offline sharing app. Generated binaries stay outside the public Git presentation; no APK copy is added under `artifacts/`.

## Recommended 2–3 Minute Sequence

| Time | Show | Explain |
|---|---|---|
| 0:00–0:25 | Camera; switch lens/tab and return | Native camera ownership/lifecycle, not a static fixture |
| 0:25–1:00 | Capture, choose B, send | Real 1440/512 processing; preview/audience/send on one screen |
| 1:00–1:50 | Switch to B; Inbox → Detail → Calendar | Authorized delivery, unread/read and local-date grouping |
| 1:50–2:15 | Profile/collection, prepared test table | State/repository separation; exact test counts, not additive totals |
| 2:15–2:45 | Explain retry and revoke evidence | Stable idempotency; privacy limits; DEV scope |

Timing is a presentation plan, not a measured performance guarantee. Pre-login/prepare the relationship first; use screen sharing or recorded evidence if host resources/network are unreliable.

## What to Point Out

Minimalist reference-driven UI; one-screen Post-Capture; real Friend Graph/media authorization; cleanup of processed drafts; stable request identity after response loss; timestamp/ID cursor pagination; explicit security/lifecycle tests. Do not imply original ownership of supplied photo/design assets.

For technical interviews, the existing A/B runner also verifies ALL, retry, revoke and block. See [backend setup/evidence](BACKEND_DEV_UNBLOCK.md) before any authorized replay: it writes controlled DEV test data, uses a temporary proxy and replaces the installed APK with a test harness. It is **not** a read-only recruiter demo command; restore the ordinary APK afterwards.

## Known Demo Constraints

Google E2E is DEFERRED; production is NOT READY. Full sharing needs configured local services and internet. Blocking may remove your prepared relationship; don't perform it before the main send flow. Revoke cannot erase saved copies and has CDN/bearer/tombstone limits. The last backend replay passed but needed System UI Wait under host memory pressure; later Camera-only stress did not. [Hardening evidence](evidence/2026-10-10/release-hardening/result.md).

Stop the local backend terminals with Ctrl+C after presenting. A UI-only run with `DEMO_MODE=true` is available in the [root README](../README.md#running-the-demo), but must be described as fixture data, not real E2E.
