# Photo Presentation — DEV Verification

Verified 2026-10-11 on the existing Android emulator. This is a photo-layout refinement, not a Camera/navigation/UI redesign or backend change.

## Actual Memories

All four existing personal sample assets went through the app's DEV picker, real processor, Post-Capture Preview, Test B audience selection and real upload/publish/delivery. No History/Profile database fixtures were injected.

| Source | Composition | Published stamp |
|---|---|---|
| `china.jpg` | Night tower/branches | `1f4a8050-ef24-42da-b721-b01699e6b5e9` |
| `fish.jpg` | Food/bowl | `ed765de5-aaef-44ad-8463-774a889ed6a6` |
| `hoian.jpg` | Street, architecture and colorful walls | `5f833e27-5eab-4ad4-9b15-98d76e1e0d53` |
| `sashimi.jpg` | Food/red plate | `c388c1d0-3c5a-4a24-af26-568c54b00cab` |

Real files were asserted as 1440×1440 / 512×512 with cleared EXIF. Four new stamps are retained for demo; subsequent before/after replays reused these exact IDs. A missing A/B friendship was established through normal request/accept APIs, not direct database writes. Auth A/B worked. The native shutter also captured into Preview; that extra draft was discarded, not published. No block/revoke/delete/reset/seed was run in this phase.

## Findings and Changes

| Screen | Before | After / source |
|---|---|---|
| History | 0.79 portrait container cropped square photos horizontally; 512 thumbnail upscaled; empty caption created a blank pill | Square image; full processed 1440 source; empty pill omitted. Existing time/name/28-character ellipsis title retained |
| Profile | Tall image region re-cropped square thumbnails | Same three columns/thin frames; explicit square image and predictable tile height; 512 thumbnail, existing one-line title |
| Detail | Full square image and stamp border already correct once decoded | Kept unchanged; verified all four full images and received B Detail |
| Calendar | 31×21 cell and 1.33 day-image containers cropped square thumbnails | 21×21 small thumbnail and square day image; 512 source, existing calendar/navigation unchanged |
| Shared image widget | Network decode had no explicit placeholder | Reused `MemoryPhoto`; stable subtle placeholder during decode and clean asset-error fallback; existing authorization/retry preserved |

There is no extra crop version, original-image shortcut, new publish logic or separate fake collection. `BoxFit.cover` remains appropriate for square processed images in square boxes; it does not stretch or perform an additional aspect-ratio crop there.

## Real Screenshot Comparison

| View | Before: fully loaded | After |
|---|---|---|
| History | [before](evidence/2026-10-11/photo-presentation/before-loaded/history.png) | [after](evidence/2026-10-11/photo-presentation/after/history.png) |
| Collection | [before](evidence/2026-10-11/photo-presentation/before-loaded/profile.png) | [after](evidence/2026-10-11/photo-presentation/after/profile.png) |
| Detail — same sashimi stamp | [before](evidence/2026-10-11/photo-presentation/before-loaded/detail-0.png) | [after](evidence/2026-10-11/photo-presentation/after/detail-0.png) |
| Calendar | [before](evidence/2026-10-11/photo-presentation/before-loaded/calendar.png) | [after](evidence/2026-10-11/photo-presentation/after/calendar.png) |
| B Inbox | [before](evidence/2026-10-11/photo-presentation/before-loaded/inbox-b.png) | [after](evidence/2026-10-11/photo-presentation/after/inbox-b.png) |
| Received B Detail | [before](evidence/2026-10-11/photo-presentation/before-loaded/detail-b.png) | [after](evidence/2026-10-11/photo-presentation/after/detail-b.png) |

`detail-1/2/3.png` in both replay folders cover Hội An, bowl and night tower respectively. Screenshots are unedited device captures. Calendar is scrollable: its first viewport only shows the upper portion of the day-entry photo, not a crop in the image box. The [ordinary DEV scrolled Calendar](evidence/2026-10-11/photo-presentation/after/ordinary-calendar-day.png) shows the entire square photo. Existing older native-camera memories remain visible; collection counts are DEV data, not usage metrics.

The first creation replay passed 1/1 in 7:06 but its initial capture wait could match an outgoing screen; some Detail PNGs were loading. Those files remain in `before/` as diagnostics, **not completed visual evidence**. The scoped-image wait was repaired. The authoritative loaded baseline replay passed 1/1 in 0:51; the after replay passed 1/1 in 1:02. All three retained safe logs are in their respective folders. No System UI ANR/Wait intervention was needed in these runs.

## Regression

| Suite | Final result |
|---|---|
| Full Flutter | 122/122 PASS |
| Enabled DEV-auth | 7/7 PASS |
| DEV sample capture | 9 PASS; 1 deliberate opposite-configuration skip |
| Focused Camera/Post-Capture/visual/archive regression | 46/46 PASS |
| Photo/source/layout targeted archive tests | 8/8 PASS (four existing + four added) |
| Rules | 7/7 PASS |
| Pagination | 8/8 PASS |
| Functions | 29/29 PASS; 15 emulator-only cases skipped here and passed as Rules/pagination |
| Gateway | 36/36 PASS |
| Analyzer | No issues |
| Visual goldens | All five pass: feed/profile/calendar deliberately updated; Camera/Preview unchanged |

Overlapping suites are not additive. One full-suite attempt failed because the taller Calendar photo moved a caption target below the viewport; the test now pumps after its existing scroll before tapping, retaining Detail/read assertions. The final full rerun passed 122/122. Rules CLI initially selected system Java 11; the successful run used the existing Gradle JDK 21, against isolated `inkstamp-rules-test` / `inkstamp-pagination-test` emulator data, not DEV cloud records.

Three original affected golden files are preserved in `evidence/2026-10-11/photo-presentation/golden-before/`. Only those three were regenerated with individually filtered visual tests. Camera SHA256 remains `5E253257687011AFA0A3E586E8B29ACD0CAB6E67BB1504E52A3CCD623243BD2A`; Preview remains `536930BAE1A9FAD93AD2F320D3D1513AC94F47AE33BAC526B85B17C2D218C13E`.

## Files / Reproduction

Product changes: `home_screen.dart`, `settings_screen.dart`, `calendar_screen.dart`, `memory_photo.dart`. Tests: `memory_interactions_test.dart`, `inbox_calendar_test.dart`, new `integration_test/photo_presentation_test.dart`; the existing safe E2E runner adds an opt-in photo-review mode. No Camera, router, processor, backend, Rules or gateway product code was changed.

From the prepared root workstation with local Functions/gateway already running:

```powershell
node functions/scripts/run-backend-e2e.mjs --photo-review
node functions/scripts/run-backend-e2e.mjs --photo-review --reuse-photos --before-photos
node functions/scripts/run-backend-e2e.mjs --photo-review --reuse-photos
```

The first command creates real new memories. Reuse commands assume the latest four own stamps are the four samples: verify IDs against the safe logs; do not use them blindly on unrelated data. `--before-photos` selects an evidence folder, not old application code. Actual before screenshots above were captured before product edits.

The runner transfers credentials into private app storage and removes them in `finally`; no secret is written into these reports. Test builds use port 5002 temporarily, so restore an ordinary DEV APK afterwards using the normal [demo build/install steps](RECRUITER_DEMO.md). The ordinary APK was rebuilt, installed and launched after this phase, without the test proxy configuration. Its [fully loaded History](evidence/2026-10-11/photo-presentation/after/ordinary-dev-history-loaded.png) confirms the retained real memories outside the integration harness; `ordinary-dev-launch.png` is only an initial loading diagnostic.

## Remaining Boundaries

All current source photos are portrait-shaped; there is no standalone portrait-person or landscape source file in this set. Existing processor tests cover portrait/landscape normalization, but no new real landscape/person memory is claimed. The unchanged processor center-crops originals to square: screen layout cannot recover content already removed there. No focal-point feature was added.

Original low-light softness remains; this is not an AI enhancement or sharpening task. Date cells are intentionally tiny. Long existing UUID metadata in Profile/Calendar and existing avatar/header styling were left alone. No full physical-device, extreme-text-scale, production auth or production performance certification is claimed. Personal image assets still require a redistribution/privacy review before public release.
