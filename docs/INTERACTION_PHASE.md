# InkStamp interaction phase — 2026-10-05

The Camera design is frozen. Motion is implemented with Flutter widgets and
central tokens, with no additional animation package. The settled design
goldens remain unchanged.

## Implementation

- Shutter: 0.96 press feedback without delaying capture; 100 ms low-opacity
  flash on the hardware capture → processing event. Both controller and screen
  prevent duplicate capture. Focus points use an optional repository capability
  backed by `CameraController.setFocusPoint`; unsupported hardware is ignored.
- Switch lens: one operation at a time, small icon rotation and preview fade.
  Flash changes retain device capability handling. Grid toggles a passive overlay.
  Live preview fits the actual portrait/landscape camera texture; sample photos
  are limited to the explicit design fixture, not a pretend live feed.
- Preview displays the processed capture, with X and Check inside the photo.
  Entry/discard/selection motion uses shared tokens. Android back and the header
  back button discard through the same cleanup path.
- The existing `StampDraft.audience` and `selectedRecipientIds` are the only
  audience state. ALL is default; tapping a person enters custom selection;
  deselecting the last person leaves an empty custom selection and disables Send.
  The eligible list comes from the existing production Friend Graph provider.
- `PostCaptureController` orchestrates the existing composer, timeline and image
  processor. Widgets own animation and navigation only. Check starts upload and
  callable publish on the same screen; progress occupies the same Check control.
  Sending locks discard, back and recipient changes. Success briefly confirms
  and returns to Camera, then resumes camera resources.
- Failure preserves both processed local files. Timeline keeps each completed
  upload ID and retries the same publish request. After the callable has been
  attempted, recipient selection stays locked on retry because a lost response
  may mean the original request already committed. This avoids duplicate records
  and inconsistent delivery. Pre-call partial uploads can be discarded safely.
- Legacy Editor/Audience/Sending URLs redirect to Preview; Success redirects to
  Camera. These are compatibility aliases, not extra screens in the main flow.
- History, Calendar and Collection read the existing timeline. Media is resolved
  through the authenticated delivery repository. History overlay titles are at
  most 28 Unicode code points with ellipsis. Photos open the existing Detail via
  a short fade/scale; no new Hero file lifecycle is introduced.
- Calendar month/date and collection filter state live in Riverpod controllers.
  Month navigation clamps invalid days; the selected date filters memories.
  Month and list transitions are small and deterministic. Scroll positions use
  PageStorage keys. Bottom tab pages have no transition. Camera resources are
  suspended on navigation; resource safety takes priority over keeping hardware
  alive across tabs.
- Profile filters have 44 dp touch targets. Audience selection exposes selected
  semantics and a check mark, as well as a border. Motion durations become zero
  under `MediaQuery.disableAnimations`; all actions continue to work.
- Detail does not expose local-only archive removal as a backend action. Existing
  Report is offered for other people's stamps; no unsupported Save/Share/Delete
  actions were added.

## Files changed in this phase

New:

- `apps/mobile/lib/app/theme/app_motion.dart`
- `apps/mobile/lib/core/widgets/motion_feedback.dart`
- `apps/mobile/lib/core/widgets/memory_photo.dart`
- `apps/mobile/lib/features/stamps/presentation/controllers/post_capture_controller.dart`
- `apps/mobile/lib/features/archive/presentation/controllers/memory_view_controller.dart`
- `apps/mobile/test/features/stamps/post_capture_flow_test.dart`
- `apps/mobile/test/features/stamps/post_capture_screen_test.dart`
- `apps/mobile/test/features/archive/memory_interactions_test.dart`
- `apps/mobile/integration_test/camera_hardware_test.dart`

Extended:

- `apps/mobile/lib/app/router/app_router.dart`
- `apps/mobile/lib/features/camera/domain/repositories/camera_repository.dart`
- `apps/mobile/lib/features/camera/data/repositories/camera_plugin_repository.dart`
- `apps/mobile/lib/features/camera/presentation/controllers/camera_controller.dart`
- `apps/mobile/lib/features/camera/presentation/screens/camera_screen.dart`
- `apps/mobile/lib/features/stamps/domain/entities/stamp.dart`
- `apps/mobile/lib/features/stamps/data/repositories/firebase_stamp_repository.dart`
- `apps/mobile/lib/features/stamps/presentation/controllers/stamp_timeline_controller.dart`
- `apps/mobile/lib/features/stamps/presentation/screens/stamp_preview_screen.dart`
- `apps/mobile/lib/features/home/presentation/screens/home_screen.dart`
- `apps/mobile/lib/features/archive/presentation/screens/calendar_screen.dart`
- `apps/mobile/lib/features/settings/presentation/screens/settings_screen.dart`
- `apps/mobile/lib/features/inbox/presentation/screens/stamp_detail_screen.dart`
- `apps/mobile/test/features/camera/camera_controller_test.dart`
- `apps/mobile/test/visual_ui_test.dart`

## Verification and remaining E2E

The full Flutter suite passed 59 tests after the flow implementation (the
previous baseline was 45). Final verification is recorded in `testcase.md`.
The final focused Camera/Preview/golden run also passed 21 tests after the live
preview fix. Analyzer reports no issues. Android hardware smoke passed 1/1 on
API 36, with evidence in `docs/evidence/2026-10-05/camera-hardware-result.md`.
Existing camera tests remain, and the new camera duplicate-capture test extends
them. New tests cover audience, publish loading/deduplication/failure/retry,
automatic return, discard, History/Detail, Calendar, Collection and reduced
motion. Design fixtures are explicit only in golden tests; production screens
use providers. No golden PNG has been regenerated in this phase.

Run from `apps/mobile`:

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub integration_test/camera_hardware_test.dart -d emulator-5554
```

Hardware smoke test is a subset of Camera E2E. It does not prove two-account
delivery, App Check, upload, publish, or the Friend Graph.

Remaining production E2E prerequisites:

1. Two authorized test accounts A/B and an authenticated dev media gateway.
   Local `/health` at `http://127.0.0.1:8787` was unavailable on 2026-10-05.
   Android must use the dev gateway address reachable from the emulator.
2. A searches B, sends a request; B accepts. Repeat the rejection scenario.
   Toggle Close Friends, block/unblock, and verify QR and deep-link invitation.
3. A captures via real front/back camera, checks orientation/crop and Preview,
   sends ALL then custom B, and verifies B receives the published stamp/media.
4. Interrupt upload/publish, verify retained draft and retry with the same
   request; verify no duplicate stamp and correct recipients. Check local
   cleanup after success/discard and screenshots/logs with device/API/account
   scenario recorded. Avoid capturing tokens or passwords in evidence.

Known limits: retry state is in-memory, consistent with the current composer;
process-death draft recovery is not introduced. Discard after an ambiguous
publish response must not delete remote media that might already be published.
Such ambiguous or failed-cleanup assets need reconciliation before public
release. Automated focus/flash support does not prove physical flash or real
world orientation on every handset. No Friend Graph or full Camera E2E
milestone is marked complete. `WEEK_2_REVIEW.md` is not advanced without the
required real E2E evidence. Durable Object work remains separate.

An x86_64 debug APK was built and successfully installed over the integration
APK to restore the normal app entry point. Storage constraints on this emulator
require the architecture-specific build. The prior automatic uninstall may
have removed its old session, as recorded in the hardware evidence.
The subsequent latest APK (including the final live-preview/lifecycle guards)
also builds, but its in-place installation is still rejected for insufficient
emulator storage. The emulator retains the earlier normal-app build. The latest
artifact is `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`; free
emulator storage before installing it. No further app uninstall was performed.

The implementation can move into Inbox/Calendar integration, while production
E2E and the outstanding release prerequisites remain open.

Inbox/Calendar follow-up on 2026-10-05 is documented in
`docs/INBOX_CALENDAR_PHASE.md`. It adds persistent delivery reads, limited Inbox
pages and independent local-month archive queries without changing Camera or
the reference goldens. Received History uses a recent window, Collection keeps
all own active stamps, and Calendar/repository-ID Detail access older memories. The
follow-up also records the existing gateway media-authorization gaps, safe
storage checks and the still-open real two-account E2E gates.
