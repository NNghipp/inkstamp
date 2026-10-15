# DEV Sample Capture

Add photos directly to `apps/mobile/assets/image_test/`, then stop and rebuild
the app. The registered asset folder is discovered through Flutter's asset
manifest; no filename list/code edits are required. Keep its README if empty.

Use the normal debug DEV backend/auth configuration from the recruiter guide.
On Camera, tap the top **DEV sample capture** image icon and choose a filename.
The selected image becomes a static preview; press the normal shutter to capture.
Choose **Camera thật** in the picker to restore native preview. Cancel leaves the
current selection untouched. An empty folder shows a message. Real shutter,
flash, lens switching and native preview remain the existing camera path.

## Shared Pipeline

The alternate source copies original asset bytes into an app-private raw draft.
`InkstampCameraController` then uses the same serialized processing/draft handoff
as native capture: orientation, center-square crop, 1440×1440 image, reusable
four-sided perforated alpha mask, 1440×1440 stamp PNG and 512×512 stamp PNG,
metadata removal and raw-file cleanup. The existing Preview route and composer
continue into audience selection and the unchanged upload/publish/delivery flow.
Inbox, Calendar and Memory Detail consume ordinary deliveries; no special mock
publish or authorization bypass is introduced.

Optional `assets/image_test/demo_metadata.json` supplies short `title`,
`locationLabel` and a local `HH:mm` time on today's date. Discovery works without
it. Invalid or absent metadata falls back to the actual capture time and no
labels. `capturedAt`, `title` and `locationLabel` are optional publish metadata;
the server continues to assign `createdAt` (publish time), and Calendar queries,
authorization and Rules are unchanged. New stamp presentations use one capture
date format, `DD.MM.YYYY`, inside the bottom-right safe area. Very small Calendar
and Inbox thumbnails omit date text to stay legible.

Discovery uses the existing `image` library's filename decoders, including
JPEG/PNG/WebP/GIF/BMP/TIFF. HEIC/HEIF needs conversion first. Animated inputs
become a still stamp PNG. Corrupt inputs use normal processing errors/cleanup.

## Build / Privacy Boundary

The compile-time gate requires both debug mode and `APP_ENV=dev`. The UI action,
manifest discovery and controller/raw-source entry points are disabled in
profile/release and non-DEV debug builds. No extra media-storage permissions.

Standard pubspec assets are bundled in APKs regardless of the runtime gate.
Therefore personal asset photos are **not secret storage** and must be removed
before public/release distribution. This change blocks the feature, not binary
extraction of bundled files. Source photos are never edited/deleted by capture;
app-private copies follow existing cleanup, including stale-draft cleanup.

## Original Sample-Source Verification — 2026-10-11

- Default Flutter suite: 118/118 PASS (original 114 plus four new guard/filter/widget tests).
- DEV sample suite: 9 PASS, 1 intentional skip for the opposite non-DEV guard.
- Analyzer: no issues.
- Debug DEV APK built successfully at `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk` (not installed by this task).
- Five original golden PNGs unchanged; no golden regeneration.
- Asset manifest discovers current folder contents without hard-coded names.
- Picker cancel/select → existing Preview route → Camera return verified with widget fixtures.
- Real JPG/PNG processor outputs, metadata cleanup, raw/draft cleanup, corrupt-file rejection and duplicate/stale capture guards verified.

These results are not additive. New sample images were not published to the
real DEV backend in this task; the existing backend flow/tests are reused, not
claimed as a new sample-photo A/B network E2E replay.

The section above records the earlier source-only phase. Subsequent real-photo
verification is recorded in [Photo Presentation](PHOTO_PRESENTATION.md); the
current baked-alpha pipeline and exact latest checks are in [Stamp Edges](STAMP_EDGES.md).

The 15/10/2026 static-preview, optional metadata, real delivery, lifecycle and
README capture results are in [DEV presentation evidence](evidence/2026-10-15/dev-presentation/RESULTS.md).

Run from `apps/mobile`:

```powershell
flutter test --no-pub
flutter test --no-pub --dart-define=APP_ENV=dev test/features/camera/dev_asset_capture_test.dart
flutter analyze --no-pub
```

[Demo/backend setup](RECRUITER_DEMO.md) · [Folder instructions](../apps/mobile/assets/image_test/README.md)
