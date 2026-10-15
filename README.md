# InkStamp

InkStamp is a minimalist social camera app that turns photos into collectible postage-stamp memories and shares them with friends. Built with Flutter, it currently supports a verified Android DEV workflow—not a production release.

## Overview

Capture a moment, preview its perforated stamp edges, choose your audience and send. Received memories appear in Inbox; moments can be revisited through History, Calendar and your Profile collection.

New photos become **1440×1440 PNGs with real transparent stamp edges**, plus **512×512 thumbnails**. The shape is part of the image itself, not a decorative UI frame. Older square memories remain supported.

## Key Features

- Native camera capture, orientation correction and metadata cleanup.
- Stamp-shaped processing and Post-Capture Preview.
- Audience selection: all accepted friends or selected friends.
- Friend Graph: username search, requests, accept/reject and Close Friends.
- Inbox with unread/read states, History, Calendar and Profile collection.
- Retry with a stable send identity and transactional, idempotent publishing.
- Block/unblock and sender revoke logic, with the limitations below.
- Debug DEV sample capture through the same processing and publishing pipeline.
- Automated unit, widget, golden, backend and Android E2E coverage.

## Screens / Preview

Real Android emulator screenshots from the dark DEV app. Sample photos use the shared capture, processing, upload and publish flow. Camera shows an optional DEV static sample preview; native Camera remains the default.

<table>
  <tr><th>Stamp Output</th><th>Camera</th></tr>
  <tr>
    <td><img src="docs/readme-assets/preview-stamp.png" width="280" alt="Post-Capture Preview of a Kyoto temple with transparent stamp edges and capture date"></td>
    <td><img src="docs/readme-assets/camera-screen.png" width="280" alt="Camera controls and crop guide over a DEV sample photo"></td>
  </tr>
  <tr>
    <td>A processed photo with baked stamp edges, ready to share.</td>
    <td>Choose a DEV photo, then capture with the normal shutter.</td>
  </tr>
  <tr><th>History</th><th>Calendar</th></tr>
  <tr>
    <td><img src="docs/readme-assets/history-screen.png" width="280" alt="Dark History displaying published stamps with capture time, title and sender"></td>
    <td><img src="docs/readme-assets/calendar-screen.png" width="280" alt="Dark Calendar with real stamp thumbnails and selected-day memories"></td>
  </tr>
  <tr>
    <td>Published moments with compact time and name overlays.</td>
    <td>Browse memories by date and open their details.</td>
  </tr>
</table>

<details>
  <summary>Profile / Collection</summary>
  <p><img src="docs/readme-assets/profile-collection.png" width="280" alt="Dark Profile collection containing real perforated stamps"></p>
  <p>New stamps alongside compatible older square photos.</p>
</details>

Screenshots were captured on **2026-10-15** and preserve the Vietnamese UI and DEV account labels. Calendar shows the selected-day section after scrolling. Capture date uses **DD.MM.YYYY** inside the stamp; optional title, location and capture time travel with each memory. The server still assigns publish time. [Current evidence and file list](docs/evidence/2026-10-15/dev-presentation/RESULTS.md).

## Main User Flow

~~~text
Camera → Capture / DEV Sample → Stamp Processing → Preview
       → Select Audience → Publish → Inbox / History / Calendar / Profile
~~~

Preview, audience selection and sending share one Post-Capture screen.

## Tech Stack

| Area | Technologies |
|---|---|
| Mobile | Flutter, Dart, Riverpod, GoRouter, native camera plugin |
| Images | Dart image library, normalized alpha mask, app-private draft files |
| Authentication / data | Firebase Auth, Firestore, Security Rules and indexes |
| Business logic | TypeScript, Firebase callable Functions, Admin SDK, Zod |
| Media | Cloudinary authenticated assets, Cloudflare Worker gateway |
| Verification | Flutter test / integration_test, Vitest, Firebase emulators, Android Emulator / ADB |

## Current Test Status

Automated suites and static analysis were rechecked on **2026-10-15**. Counts overlap and must not be added together.

| Check | Result |
|---|---|
| Flutter, including Camera / processing / Preview / archive regression | 144/144 PASS |
| Enabled DEV-auth | 7/7 PASS |
| DEV sample capture | 10 PASS, 1 intentional opposite-build skip |
| Firestore Rules | 7/7 PASS |
| Cursor pagination | 8/8 PASS |
| Functions | 31 PASS; 15 emulator-only cases skipped in the ordinary suite and run separately as Rules/pagination |
| Media gateway | 39/39 PASS |
| Analyzer | 0 issues |
| Golden screenshots | 5 PASS; included in Flutter results |
| Android Camera lifecycle | 1 PASS; 20 rapid tab switches, native/Preview/static background-resume, native alpha outputs and draft cleanup |

Android DEV presentation E2E passed **1/1**, checking four real published sample memories, full/thumbnail dimensions and transparency, recipient metadata, legacy images and native capture/discard. These are DEV functional checks, not production or physical-device performance certification. [Results and scope](docs/evidence/2026-10-15/dev-presentation/RESULTS.md).

## Running the App

### Prerequisites

- Flutter **3.47.1** (the CI baseline), Android SDK and a booted emulator.
- Node.js **22**, Firebase CLI, and Java **21** for Firestore emulator tests.
- Authorized DEV Firebase access; matching local `apps/mobile/android/app/google-services.json` and `apps/mobile/lib/firebase_options.dart`.
- Private Cloudinary configuration in `workers/media-gateway/.dev.vars`, starting from [the empty template](workers/media-gateway/.dev.vars.example).
- Privately configured DEV test accounts if using the guarded A/B login. See [DEV authentication](docs/DEV_TEST_AUTH.md).

A fresh clone needs this private setup for real sharing. Never commit credentials, signing keys or generated APKs.

Install dependencies from the repository root:

~~~powershell
npm --prefix functions ci
npm --prefix workers/media-gateway ci
cd apps/mobile
flutter pub get
cd ../..
~~~

Start local Functions in one terminal, from the root:

~~~powershell
npm --prefix functions run build
$env:DEV_BACKEND_MODE='functions_emulator'
$env:MEDIA_GATEWAY_BASE_URL='http://127.0.0.1:8787'
firebase emulators:start --only functions --project inkstamp-dev
~~~

Start the media gateway in another terminal:

~~~powershell
cd workers/media-gateway
.\node_modules\.bin\wrangler.cmd dev --local --ip 127.0.0.1 --port 8787 --log-level warn --show-interactive-dev-session false
~~~

Run the app in a third terminal, initially from the root. Replace `emulator-5554` if your device ID differs; `adb` must be on PATH.

~~~powershell
adb -s emulator-5554 reverse tcp:5001 tcp:5001
adb -s emulator-5554 reverse tcp:8787 tcp:8787
cd apps/mobile
flutter run -d emulator-5554 --dart-define=APP_ENV=dev --dart-define=ENABLE_DEV_TEST_AUTH=true --dart-define=BACKEND_MODE=functions_emulator --dart-define=MEDIA_GATEWAY_BASE_URL=http://127.0.0.1:8787
~~~

Only Functions runs locally: **Auth, Firestore and Cloudinary remain live DEV services**. Internet and authorized access are required. This setup retains Firebase **Spark** and does not deploy Functions or enable billing. Do not rebuild Functions while a demo/E2E run is active. [Backend details](docs/BACKEND_DEV_UNBLOCK.md).

### Optional Sample Capture

Add JPEG/PNG/WebP/GIF/BMP/TIFF photos to `apps/mobile/assets/image_test/`, stop and rebuild the app, then tap **DEV sample capture** on Camera. Select a photo to preview it, then press the normal shutter. Choose **Camera thật** in the same picker to return to native Camera. No filename list or code change is needed. HEIC/HEIF requires conversion; animated sources use their first frame. Cancel or an empty folder leaves the real camera available.

Optional `demo_metadata.json` in that folder maps image filenames to `title`, `locationLabel` and a local `HH:mm` time on the current day. Missing or invalid entries use the actual capture time and omit the optional labels. Photo discovery does not depend on this file.

The action requires debug mode and `APP_ENV=dev`; it is disabled in profile/release. **Asset files can still be bundled in release APKs**, so remove personal photos before public binary distribution. [Sample capture details](docs/DEV_SAMPLE_CAPTURE.md).

For UI-only exploration, run `flutter run --dart-define=APP_ENV=dev --dart-define=DEMO_MODE=true` from `apps/mobile`. This uses in-memory fixtures, not real sharing or backend E2E.

## Project Status

The core Android DEV capture → processing → sharing → viewing flow is implemented and verified in the documented environment. README previews use real app screenshots. Google Sign-In E2E is deferred, and the production environment/release is **not ready**.

## Known Limitations

- No completed real Google Sign-In E2E or production signing/configuration, App Links and release/R8 smoke verification.
- Friends screens exist, but the current tab shell has no Friends launcher. After login, DEV navigation can use `adb -s emulator-5554 shell am start -a android.intent.action.VIEW -d inkstamp:///friends com.inkstamp.app`.
- Revoke is backend/E2E-verified; Detail has no manual sender-revoke action. It denies new authorization and attempts media deletion, but cannot erase saved bytes/screenshots or immediately invalidate every previously issued URL/CDN cache.
- Images are center-cropped to square before masking; no focal-point editor or automatic conversion of old memories.
- PNG is larger than JPEG. Very noisy inputs may reduce RGB precision to fit the existing 5 MiB upload ceiling; alpha and dimensions are retained.
- Physical-device, accessibility, process-death draft recovery and production/load-performance verification remain limited or unrun.

See [release boundaries](docs/RELEASE_HARDENING.md), [architecture](docs/ARCHITECTURE.md), [Security](SECURITY.md) and [License](LICENSE).
