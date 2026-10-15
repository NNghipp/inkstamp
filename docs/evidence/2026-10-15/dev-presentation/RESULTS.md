# DEV presentation verification — 15/10/2026

## Implementation

Camera defaults to the native preview. In debug builds with `APP_ENV=dev`, the
existing image action opens the asset picker. Selecting a file changes only the
preview. The normal shutter passes that asset through the shared serialized
capture controller, processor, composer, audience, upload and publish flow.
`Camera thật` clears the selection. The selection is local to the Camera widget;
it is not a persistent camera replacement. Empty folders and unknown filenames
do not require application code changes.

The existing normalized four-sided alpha mask remains the only image mask.
Outputs remain 1440×1440 RGBA PNG and 512×512 RGBA PNG. No source photo was edited.
Date is a presentation overlay inside the stamp safe area, using `DD.MM.YYYY`;
the image bytes retain their transparent edges. Tiny Calendar/Inbox thumbnails
omit date text. Preview places the date above the existing bottom action buttons.

`capturedAt`, `title` and `locationLabel` are optional publish metadata. They are
stored on both the stamp and recipient deliveries. Existing `createdAt` remains
the server publish timestamp (`publishedAt` is a client entity getter). Auth,
Rules, audience resolution, quotas, Calendar queries, sorting and pagination
remain based on their existing contracts. Old records without metadata fall back
to publish time and existing captions. Old square photos keep their compatibility
rendering path; there is no migration.

## Real DEV sample memories

These four photos were published through the normal app UI to the existing B
test account. The optional JSON file supplies labels and a time on today's local
date; these are demo labels, not claims extracted from the original EXIF.

| Source | Title | Capture date | Time | Location |
|---|---|---|---|---|
| japannn.jpg | Cổng đỏ Kyoto | 15.10.2026 | 09:05 | Kyoto |
| mountain.jpg | Núi xa đầu chiều | 15.10.2026 | 14:20 | Nhật Bản |
| sashimi.jpg | Bữa trưa hôm nay | 15.10.2026 | 12:30 | Quán ăn |
| watermachien.jpg | Một góc Nhật Bản | 15.10.2026 | 15:40 | Nhật Bản |

Re-running the presentation driver reuses matching saved metadata instead of
publishing duplicate samples. It still re-captures a Preview and native camera
draft, discards those extra drafts, and verifies persisted deliveries and media.

## Verification

Counts overlap; do not add the focused suites to the full Flutter suite.

| Check | Final result |
|---|---|
| Full Flutter suite, including five goldens | 144 PASS |
| DEV sample suite | 10 PASS, 1 intentional opposite-build skip |
| Enabled DEV-auth | 7 PASS |
| Functions ordinary suite | 31 PASS, 15 emulator-only skips |
| Firestore Rules, real Firestore emulator | 7 PASS |
| Cursor pagination, real Firestore emulator | 8 PASS |
| Media gateway | 39 PASS |
| Functions TypeScript build / ESLint | PASS / PASS |
| Flutter analyzer | 0 issues |
| Android presentation E2E | 1 PASS; 4 real deliveries, 8 full/thumbnail alpha checks, recipient metadata |
| Android native/static lifecycle stress | 1 PASS; 20 rapid tab switches, native/Preview/static Android HOME + resume, native 1440/512 alpha, draft cleanup, clear sample |

No golden files were regenerated for the static-preview/metadata phase. The five
dark-theme baselines were already present from the preceding UI phase and pass
in the full suite. Initial device attempts exposed a System UI ANR, a picker
scroll issue in the harness and a download timeout; their timestamped logs remain
available. Only the final reviewed device captures are used in README.

## Final README assets

All are unmodified real device captures; no application UI was composited.

| Device evidence | README destination |
|---|---|
| camera-sample.png | ../../../readme-assets/camera-screen.png |
| preview-stamp.png | ../../../readme-assets/preview-stamp.png |
| history.png | ../../../readme-assets/history-screen.png |
| calendar-selected-day.png | ../../../readme-assets/calendar-screen.png |
| profile.png | ../../../readme-assets/profile-collection.png |
| detail-0.png | ../../../readme-assets/memory-detail.png |

Inbox B, recipient Detail, native Preview and legacy Detail are additional device
evidence. Screenshot generation waits for actual network images to decode.

Camera, Preview, History, Collection and Detail came from the real-backend
integration run. The final Calendar selected-day view was checked and captured
in the installed ordinary DEV APK after natural scrolling; its overview remains
separate compatibility evidence. The ordinary DEV APK was rebuilt and installed
after the test APKs, with the existing A session retained. The runner removed
private test credentials from app-private files; their absence was verified.

## Files in this phase

Paths below are relative to the repository root. Other dirty files in the working
tree belong to the preceding dark UI phase or existing user work.

```text
README.md
apps/mobile/assets/image_test/README.md
apps/mobile/assets/image_test/demo_metadata.json
apps/mobile/lib/core/widgets/stamp_date_overlay.dart
apps/mobile/lib/core/widgets/memory_photo.dart
apps/mobile/lib/core/widgets/stamp_artwork.dart
apps/mobile/lib/features/camera/data/repositories/dev_asset_capture_source.dart
apps/mobile/lib/features/camera/presentation/controllers/camera_controller.dart
apps/mobile/lib/features/camera/presentation/screens/camera_screen.dart
apps/mobile/lib/features/stamps/domain/entities/stamp.dart
apps/mobile/lib/features/stamps/domain/entities/stamp_draft.dart
apps/mobile/lib/features/stamps/data/repositories/firebase_stamp_repository.dart
apps/mobile/lib/features/stamps/data/repositories/in_memory_stamp_repository.dart
apps/mobile/lib/features/stamps/presentation/controllers/stamp_composer_controller.dart
apps/mobile/lib/features/stamps/presentation/screens/stamp_preview_screen.dart
apps/mobile/lib/features/home/presentation/screens/home_screen.dart
apps/mobile/lib/features/archive/presentation/screens/calendar_screen.dart
apps/mobile/lib/features/archive/presentation/screens/archive_day_screen.dart
apps/mobile/lib/features/archive/presentation/screens/archive_stamp_screen.dart
apps/mobile/lib/features/settings/presentation/screens/settings_screen.dart
apps/mobile/lib/features/inbox/presentation/screens/inbox_screen.dart
apps/mobile/lib/features/inbox/presentation/screens/stamp_detail_screen.dart
apps/mobile/test/features/camera/dev_asset_capture_test.dart
apps/mobile/test/stamp_presentation_metadata_test.dart
apps/mobile/integration_test/photo_presentation_test.dart
apps/mobile/integration_test/camera_lifecycle_stress_test.dart
functions/src/shared/validation/schemas.ts
functions/src/modules/stamps/publish-stamp.ts
functions/test/schemas.test.ts
functions/test/stamp-backend.test.ts
functions/scripts/run-backend-e2e.mjs
functions/scripts/run-camera-hardening.mjs
docs/DEV_SAMPLE_CAPTURE.md
docs/readme-assets/*.png
docs/evidence/2026-10-15/dev-presentation/
```

The asset folder was already registered in pubspec.yaml and remains registered.

## Source integrity

All eight JPEG SHA-256 hashes match the values recorded before these changes:

```text
china.jpg        BA784222B36F4E23092BFB575F5DEABFC8E3159E766D78D383D1A4ECD95B22A9
fish.jpg         F2101FB864B5489196AAEB2866284670F3C7F958F4E72A86AA600544A3A8254B
hoian.jpg        831D4FD9473B16C01FDA75176A3058ACBB1F8233E84906273240AC8EF77483A3
japannn.jpg      4C1E30B949E272A353953394F81F906E967EBD867DB3F3F5C4B077806223A391
mountain.jpg     E67A5CA0972A45FE74EC88B5F210D2BF6AE86BBF9FABA633E2F598505252A0D3
pkl.jpg          8469D7FCC952104C7AA59D1D7DF635619468C405CAC1F23BD4DB396665E9F2C3
sashimi.jpg      7210F80FA7DF8351A56DE65ED792302965ACBD88D3214D283A014FEE9C716F2B
watermachien.jpg 2E3A3DF57FED80E780DA31B8C6A8EF29C68E42B47C369C943D9368C33A05F1AC
```

## Boundaries

Camera keeps its existing 3:4 guide/cover preview while processing center-crops
to square. There is no focal-point editor; preview framing/visual zoom is not a
pixel-exact crop editor. Calendar grouping still uses server publish date, so a
memory captured on a different day can display a different capture date inside
that group. Labels are rendered using the viewing device's local timezone.

Verification uses an Android emulator's native virtual camera, not a physical
phone. PNG retains the existing 5 MiB upload limit and precision fallback.
Profile/release cannot enable the DEV picker, but ordinary Flutter assets can
still be extracted from distributed binaries. Remove personal source photos
before public binary distribution.

Wrangler was used only to run the local media gateway. No billing, production
deployment, Rules change or data migration was performed during verification.
