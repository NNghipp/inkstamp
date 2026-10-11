# Inbox/Calendar verification evidence — 2026-10-05

This is an execution-result summary from the local tool outputs, not a raw
terminal transcript or production screenshot. Host timezone: UTC+07:00.

## Observed commands and results

Working directory `D:\stampcard\apps\mobile`:

- Before implementation, `flutter test`: exit 0, **59 tests passed**.
- Final `flutter analyze --no-pub`: exit 0, **No issues found**.
- Final `flutter test --no-pub`: exit 0, **75 tests passed** (59 baseline + 16
  added Inbox/Calendar tests). An intermediate media-reference widget test
  exposed automatic Riverpod error retries/pending timers; explicit-retry
  policy was applied and the full suite rerun successfully. No test was removed.
- Camera/Preview/golden regression command:
  `flutter test --no-pub test/features/camera test/features/stamps/post_capture_screen_test.dart test/visual_ui_test.dart`:
  exit 0, **21 passed**. The final full suite also includes all of these tests.
- **5 golden tests PASS** without `--update-goldens` or PNG edits.

Backend verification:

- From repository root, use existing Android Studio JBR Java instead of the
  default Java 11: set process `JAVA_HOME=D:\android_studio\jbr` and prepend its
  `bin` to process PATH. No global environment configuration was changed.
- `firebase emulators:exec --only firestore --project inkstamp-rules-test "npm --prefix functions run test:rules"`:
  exit 0, **7/7 Rules tests PASS**, local Firestore emulator started/stopped.
- From `functions`, `npm test`: exit 0, **9 Functions tests PASS**. Seven Rules
  tests are skipped by this command when FIRESTORE_EMULATOR_HOST is absent;
  their actual passing execution is the separate emulator command above.
- From `functions`, `npm run lint`: exit 0.
- From `workers/media-gateway`, `npm test`: exit 0, **14/14 PASS**.
- Repository `git diff --check`: exit 0.

## Added automated coverage

`apps/mobile/test/features/inbox/inbox_calendar_test.dart` has 16 tests:

1. Equal-timestamp cursor ordering, 25/25/1 pages and no duplicate/missing IDs.
2. In-memory repository read persistence, ID lookup outside first page and range.
3. Inbox newest-first, pagination, refresh and duplicate read-update suppression.
4. Inbox fetch error/retry, loaded data retained offline and failed read retry.
5. Repository-enforced unavailable filtering in Inbox/Calendar/Detail (controlled
   repository policy, not proof that the deployed gateway revokes media).
6. Exact `[monthStart, monthEnd)` range, multiple/day, empty day and cache reuse;
   Calendar initialization makes **zero History reads**.
7. Matching-month publish invalidation, unrelated-month cache retention and
   explicit retry after month fetch error.
8. UTC/local midnight grouping: host local 26 Sep 00:30 is UTC 25 Sep 17:30.
9. Inbox/month cache reset when switching A/B simulated sessions.
10. Today for current month; no arbitrary selected day for another month.
11. Unread semantics/dot, thumbnail-only row, same Detail ID/full-media reference,
    no read before pending ID lookup resolves, persistent read on return.
12. Failed mark-read leaves Detail usable and retries on reopening.
13. Inline Inbox error retry and minimal empty state.
14. Widget load-more action adds 30 unique rows and ends pagination.
15. Unavailable Detail/lookup retry, with **zero read writes** on unavailable ID.
16. Calendar inline retry and photo-first shared Detail navigation.

Existing `memory_interactions_test.dart` retains History/Collection Detail
navigation and Calendar date/month tests. Its clamp test now asserts the
requested no-forced-selection behavior, preserving test count.
Firestore tests additionally exercise owner-only monotonic `isSeen`, reject
protected-field changes/other-user writes/revoked updates, and check authorized
Inbox and month query shapes. Production index creation is not tested by the
emulator and was not deployed here.

## Reference PNG fingerprint inventory

SHA256 recorded after the phase; this inventory is not a Git-baseline hash diff.
Golden image comparisons passed against these existing, unmodified PNGs.

| File under apps/mobile/test/goldens | SHA256 |
|---|---|
| calendar.png | 0F77ADCEAD873CE9DD8C1AD2E7F2718488CEF6B365E3752C8963BB531BC75C44 |
| camera.png | 5E253257687011AFA0A3E586E8B29ACD0CAB6E67BB1504E52A3CCD623243BD2A |
| feed.png | 8E87C1F3D7FDD1DD21B2C371ECE1B0A3F837823AF9C02E348BC0ABBE1AA477C3 |
| preview.png | 536930BAE1A9FAD93AD2F320D3D1513AC94F47AE33BAC526B85B17C2D218C13E |
| profile.png | 0401AAC4DC89E99B39B53E877DFB1C33D8B52042F723A3B342B965906FAC8892 |

These verify frozen design fixtures, not every dynamic loading/unread/error
state and not live delivery against the design HTML. No new camera hardware
test or production visual E2E was run in this phase; prior camera hardware
results remain in `camera-hardware-result.md`.

## Android and real E2E status

AVD Medium_Phone_API_36.1, emulator-5554, sdk_gphone64_x86_64, SDK 36. AVD
configuration points to `C:\Users\ngong\.android\avd\Medium_Phone.avd` with
`disk.dataPartition.size=6G`. `/data`: 5.8G total, 5.2G used, 393M free, 94%.
App cache and code_cache: 8K each. `/sdcard/Download`: 8K; `/data/local/tmp`:
11M including Android Studio helper/temp files, which were not deleted.

`adb shell pm trim-caches 1073741824` completed, but `/data` remained 393M
available. It did not measurably solve installation capacity. No app/session
data was cleared, no uninstall/reinstall was attempted, no AVD was wiped or
resized, and no APK from this new phase was installed. The earlier installed
normal app remains; emulator observation is not proof of the new Inbox build.

Local `http://127.0.0.1:8787/health` remained unavailable. Two authorized A/B
sessions were not provided. Therefore the following are **NOT RUN**:

- Real custom/ALL send → B Inbox thumbnail/time/unread → Detail → persisted read.
- Real received-memory Calendar day/count/local-date/Detail.
- Real Friend Graph and historical block/media-authorization E2E.

The global Friend Graph/send-receive milestone remains open. Known gateway
first-100-deliveries/status-check limitations and remaining security/release
gates are explicitly described in `docs/INBOX_CALENDAR_PHASE.md`. No public
Worker deployment or Durable Object work was performed.
