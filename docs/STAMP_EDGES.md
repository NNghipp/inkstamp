# Baked Stamp Edges — 2026-10-11

## 1. Mask implementation

Native Camera and DEV sample source still hand raw files to the same
`LocalImageProcessingRepository`: decode → bake orientation → center-square
crop → resize → `StampAlphaMask` → encode → private draft files → existing
composer/upload/publish. No Camera lifecycle, navigation or publish duplication.

The reusable normalized alpha mask cuts twelve circular perforations on each
side (radius 2.5% of side length) and rounds the outer corners. Pixel coverage
is antialiased at each resolution. The RGB photo reaches the scalloped boundary;
there is no baked paper border or UI-generated replacement for the alpha shape.
Fully transparent pixels have zero RGB; interior colors/alpha are retained.
The same geometry is applied to both 1440×1440 and 512×512 outputs.

## 2. Final image format

RGBA PNG, filenames ending `_stamp_v1.png`. Lossless encoding is tried first.
The existing 5 MiB upload ceiling remains: unusually noisy photos can reduce RGB
precision progressively while preserving alpha, dimensions and shape; if still
too large, processing fails normally rather than flattening or silently resizing.
EXIF/ICC/text metadata is removed and raw drafts cleaned as before.

Gateway support is narrowly opt-in: `imageFormat: stamp_png_v1` signs `format: png`
and a server-minted `_stamp_v1` public-ID suffix. PNG delivery includes signed
`format: png`; old requests/IDs retain their previous parameters. No Functions,
Firestore schema, authorization, publish, revoke or sharing policy changes.
The mobile uploader supplies `image/png`, rejects an incompatible gateway before
upload and validates PNG format/version in the upload response. Identity suffix
is a presentation/format version, never proof of authorization.

The Cloudflare/Workers skills guided bounded request validation and typed,
local-only gateway verification. Official references inspected:
[Workers practices](https://developers.cloudflare.com/workers/best-practices/workers-best-practices/),
[Cloudinary upload/download API](https://cloudinary.com/documentation/image_upload_api_reference).

## 3. Screens

- Post-Capture Preview: new local stamp uses square dimensions and no white card/shadow.
- History: new processed full image without rectangular paper frame/shadow; existing compact overlays remain.
- Profile: processed stamp thumbnail without extra white tile frame; three columns/text stay unchanged.
- Calendar: stamp thumbnails/day images retain alpha; new day image drops redundant white framing.
- Inbox: existing square 512 thumbnail widget already supports alpha; no screen code change required.
- Memory Detail: `StampArtwork` renders new stamp directly, without extra paper, inset or perforation clip.

## 4. Backward compatibility

Existing square JPEG IDs/paths do not carry the version suffix: their image
sources and framing remain unchanged. No old memory is rewritten/migrated.
Existing delivery authorization and cleanup use the same complete public IDs.
Five existing fixture goldens pass unchanged in this phase; they intentionally
exercise the legacy/reference branch, while mask tests/E2E exercise new images.

## 5. Files changed in this phase

Product mobile files under `apps/mobile/`:

- New `lib/features/camera/data/stamp_alpha_mask.dart`.
- New `lib/core/images/stamp_image_format.dart`.
- `lib/features/camera/data/repositories/local_image_processing_repository.dart`.
- `lib/features/stamps/data/repositories/cloudinary_upload_repository.dart`.
- `lib/core/widgets/stamp_artwork.dart`.
- `lib/features/stamps/presentation/screens/stamp_preview_screen.dart`.
- `lib/features/home/presentation/screens/home_screen.dart`.
- `lib/features/settings/presentation/screens/settings_screen.dart`.
- `lib/features/archive/presentation/screens/calendar_screen.dart`.
- `pubspec.yaml`, `pubspec.lock`: existing `http_parser` made direct for MIME type.

Gateway:

- `workers/media-gateway/src/application/create_upload_signature.ts`.
- `workers/media-gateway/src/domain/cloudinary_delivery.ts`.
- `workers/media-gateway/src/presentation/worker.ts`.

Tests/harness/documentation:

- New mobile `test/features/camera/stamp_alpha_mask_test.dart`.
- Mobile `test/features/camera/local_image_processing_repository_test.dart`,
  `dev_asset_capture_test.dart`, `test/features/stamps/cloudinary_upload_repository_test.dart`.
- Mobile integration tests: `photo_presentation_test.dart`, `camera_hardware_test.dart`,
  `dev_auth_smoke_test.dart`, `backend_e2e_test.dart` updated to decode processed PNG.
- Gateway `test/cloudinary_signature.test.ts`, `test/worker.test.ts`.
- `functions/scripts/run-backend-e2e.mjs`: opt-in `--stamp-edges` evidence/configuration.
- `docs/STAMP_EDGES.md`, `docs/DEV_SAMPLE_CAPTURE.md`, root `README.md`.

## 6. Test results

Verified unit/regression results:

| Suite | Result |
|---|---|
| Full Flutter | 130/130 PASS |
| Enabled DEV-auth | 7/7 PASS |
| DEV sample | 9 PASS, 1 intentional opposite-build skip |
| Camera/Post-Capture/upload/visual/archive regression | 58/58 PASS |
| Rules | 7/7 PASS |
| Pagination | 8/8 PASS |
| Functions | 29 PASS, 15 emulator-only cases skipped and separately covered above |
| Gateway | 39/39 PASS |
| Gateway TypeScript | `npm --prefix workers/media-gateway run build` PASS |
| Analyzer | No issues |
| Goldens | 5 PASS, no regeneration/byte changes in this phase |

Suites overlap; counts are not additive. Tests cover both output dimensions,
all four perforated sides, transparent corners, partial-alpha antialiasing,
opaque/unchanged photo center, noisy-input size limit, real DEV JPG/PNG source
handoff, MIME/versioned upload, incompatible-gateway rejection and legacy frames.
Higher-bit-depth input is normalized to RGBA 8-bit; animated input becomes only
its first still frame, preventing unmasked later frames or extra-frame metadata.
Rules/pagination run against isolated emulator projects, not cloud DEV fixtures.

The initial emulator attempt stopped **before publish** because a screenshot
name contained `.jpg`, forbidden by the test control endpoint. The screenshot
name was sanitized and the failed log retained; this was not a backend upload failure.

The creation replay passed **1/1 in 12:26**, with four sample memories and one
native Camera capture (Android emulator virtual-room scene) actually published
to Test B. All ten delivered full/thumbnail PNGs were decoded and their alpha,
dimensions and opaque centers checked. No direct database injection, migration,
revoke, block, seed or cleanup of existing memories was performed.

| Source | Retained real stamp ID |
|---|---|
| `china.jpg` | `aa0fec18-0709-40c0-9079-e0b067319368` |
| `fish.jpg` | `101dcb39-abf4-4521-a122-b770a1fa055c` |
| `hoian.jpg` | `553f03c1-a476-40ef-9e9d-6020edd077b2` |
| `sashimi.jpg` | `ece3070a-ec10-4a2f-9457-45ee6f816fd3` |
| Native shutter | `8d195de9-ccd3-442f-aac0-79d38a92a9a3` |

Unedited, loaded device evidence from the creation replay:
[sample Preview](evidence/2026-10-11/stamp-edges/preview-china.png),
[native Preview](evidence/2026-10-11/stamp-edges/native-camera-preview.png),
[History](evidence/2026-10-11/stamp-edges/history.png),
[mixed new/old Profile](evidence/2026-10-11/stamp-edges/profile.png),
[new Detail](evidence/2026-10-11/stamp-edges/detail-0.png),
[old square Detail](evidence/2026-10-11/stamp-edges/detail-legacy.png),
[Calendar overview](evidence/2026-10-11/stamp-edges/calendar.png),
[mixed new/old B Inbox](evidence/2026-10-11/stamp-edges/inbox-b.png),
[received Detail](evidence/2026-10-11/stamp-edges/detail-b.png),
[safe creation log](evidence/2026-10-11/stamp-edges/e2e-2026-10-11T11-02-06-485Z.log).
Creation `detail-0..4` correspond to China, bowl, Hội An, red plate and native
capture. Calendar is scrollable; its overview naturally shows only part of the
first day photo. Initial previews show the historical `3:4` facts label; current
code corrects that label to `1:1` for processed stamps without altering fixture goldens.

The initial harness used repeated pure-Dart PNG decoding in a debug emulator;
the current replay checks bytes with the native image decoder used by Flutter,
including all four edges and a bounded download timeout. The creation duration
is a complete harness duration, **not a capture latency measurement**.

Latest-code reuse replay also passed **1/1 in 7:19**, with the same five IDs and
no additional publishes. The extra sample draft was discarded through the
normal UI. [Current Preview with 1:1 label](evidence/2026-10-11/stamp-edges/current/preview-current.png),
[History](evidence/2026-10-11/stamp-edges/current/history.png),
[Profile](evidence/2026-10-11/stamp-edges/current/profile.png),
[native Detail](evidence/2026-10-11/stamp-edges/current/detail-0.png),
[Calendar](evidence/2026-10-11/stamp-edges/current/calendar.png),
[B Inbox](evidence/2026-10-11/stamp-edges/current/inbox-b.png),
[received Detail](evidence/2026-10-11/stamp-edges/current/detail-b.png),
[legacy Detail](evidence/2026-10-11/stamp-edges/current/detail-legacy.png),
[safe current log](evidence/2026-10-11/stamp-edges/current/e2e-safe-output.log).
Current replay `detail-0..4` are native capture, red plate, Hội An, bowl and China.
No System UI ANR/Wait intervention was needed in either successful run.

The ordinary debug DEV APK was rebuilt successfully without `DEV_FUNCTIONS_PORT=5002`
or test entrypoint, using the normal local Functions/gateway configuration. It
was installed with data preserved and cold-launched successfully. The ordinary
[fully loaded History](evidence/2026-10-11/stamp-edges/current/ordinary-dev-history.png)
confirms the retained PNG memories outside the integration harness. Port 5002
reverse mapping and private `dev-test-auth.json` are absent after cleanup; local
Functions 5001 and gateway 8787 remain available. No production deployment or billing change.
The ordinary [scrolled Calendar day](evidence/2026-10-11/stamp-edges/current/ordinary-calendar-day.png)
also shows the entire native-captured stamp, including all four perforated edges.

Reproduction from the prepared workstation (local Functions/gateway running):

```powershell
node functions/scripts/run-backend-e2e.mjs --photo-review --stamp-edges
node functions/scripts/run-backend-e2e.mjs --photo-review --stamp-edges --reuse-photos
```

The first creates five memories; the second assumes the latest five own stamps
match the IDs above, creates/discards an extra sample draft for current Preview,
and publishes nothing. Verify those IDs before reuse on unrelated DEV data.
Runtime credentials are private and removed by the existing runner cleanup.

## 7. Remaining limitations

Originals are still center-cropped to square before masking; scallops remove
a narrow edge band. There is no focal-point editing or old-memory conversion.
PNG can be larger/slower than JPEG; rare high-entropy images may lose some RGB
precision to stay under the unchanged 5 MiB ceiling. No physical-device or
production performance certification. Personal sample assets remain bundled
and require a privacy/license check before distributing an APK.
