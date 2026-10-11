# Inbox + Calendar integration — 2026-10-05

Implemented and verified locally; production two-account E2E remains **open**.
The frozen Camera, Preview and other design-reference PNGs were not edited.

## Architecture and APIs

Reuse `Stamp` as the shared domain object. No parallel InboxItem/memory model,
new Firestore collection, callable, social feature, bottom tab, or image-cache
package was added. Delivery document ID equals the stamp ID in the existing
publisher. Sender name is the delivery-time snapshot; avatar uses initials
because this delivery schema contains no avatar reference. Caption is optional;
the current publisher does not produce one, so it is not fabricated.

`StampRepository` now additionally exposes:

- `fetchReceivedPage({StampCursor? after, int limit = 25}) -> StampPage`
- `fetchMonth(DateTime start, DateTime end) -> List<Stamp>`
- `getById(String id) -> Stamp?`
- `markDeliveryRead(String id) -> void`

`StampPage` contains shared stamps and a timestamp/ID continuation cursor.
Firebase and the in-memory/demo repository implement these methods. The latter
is not the production data source when Firebase initialization succeeds.

Inbox has a small History header entry, compact thumbnail rows, unread dot and
stronger sender weight, semantic read labels, refresh/reopen, inline error/retry,
subtle progress, empty state and load-more. No realtime listener was introduced.
`InboxController` guards overlapping page loads/read updates and ignores results
from a previous account. Successful read IDs are remembered for that session.

All entry points continue using `/stamp/:stampId` and `StampDetailScreen`.
Its auto-disposed lookup resolves by repository ID, not by the first History
page. It reads the caller's delivery first; revoked/unavailable delivery returns
null. Otherwise it attempts an own stamp lookup under the existing sender-only
rule. Missing/unauthorized records, inactive stamps and missing full-media
references produce `Stamp không còn khả dụng.`. Network lookup failures have
explicit retry. Media loading failures have a safe placeholder/text, not a
broken-image widget. A size constraint also prevents the Detail artwork from
overflowing a short viewport.

## Firestore and read state

Existing structure remains:

- `stamps/{stampId}`: senderId, senderName, status, createdAt, media public IDs,
  frame/paper, audience/recipients and reply metadata.
- `users/{recipientId}/deliveries/{stampId}`: stampId, senderId/name, status,
  createdAt, media references, frame/paper, isSeen and existing reaction field.

Own published stamps require `status == active`; received archive entries
require delivery `status == available`. Inbox orders server `createdAt` DESC,
then document ID DESC for deterministic ties. Here delivery `createdAt` is the
server delivery time; no client-guessed received timestamp or new deliveredAt
field is introduced. Fetch 26 documents, expose 25, and derive continuation
from the last exposed document. Filtering is inside the query, so revoked rows
do not shorten a page after fetching it. History also uses the first received
page. Collection retains its existing all-own-active-stamps behavior, not a
25-stamp cap. History's received portion is a recent window; older received
memories are accessible through paginated Inbox and independent Calendar.

Only after an authorized Detail lookup resolves and its content is rendered is
`isSeen: true` persisted asynchronously. This means the memory document is
loaded; it does not wait for every image byte to decode. An unavailable lookup
does not mark read. Read-write failure does not block viewing or falsely clear
unread; reopening retries. Read state is monotonic and idempotent.

Rules now allow only the authenticated delivery owner to update `isSeen` to
boolean true on an available delivery. The document diff must contain only
`isSeen`; sender, timestamp, media, status and all other protected fields remain
server-owned. Create/delete stay forbidden. No read permission was broadened:
owners can still read their delivery metadata (including revoked records),
but the mobile repository excludes unavailable records from archive queries.

New composite indexes in `firebase/firestore.indexes.json`:

- deliveries: status ASC, createdAt DESC (implicit document-ID DESC tie order).
- stamps: senderId ASC, status ASC, createdAt DESC.

**Deployment prerequisite:** deploy reviewed Rules and indexes through the
existing authorized Firebase release workflow and wait for indexes to build
before production E2E. They were tested locally, not deployed by this phase.
The Firestore emulator does not establish production composite-index readiness.
Functions publish/delivery source and media gateway source were not changed.

## Calendar rule, timezone and caching

Calendar means the current user's accessible archive: own active published
stamps plus available received deliveries, deduplicated by stable stamp ID.
It does not include mock entries in production, saved posts from a new model,
or another user's global stamps. A sender uses stamp creation time and a
recipient uses delivery creation time; a delivery crossing midnight can appear
on a different local day from the sender's own stamp.

Construct visible-month bounds with local `DateTime(year, month)` and
`DateTime(year, month + 1)`; send these instants as Firestore timestamps with
the half-open range `[start, end)`. Do not add a fixed 30-day duration or group
raw UTC year/month/day. Group by `createdAt.toLocal()`; format day/time locally.
The timezone is the viewing device's current timezone, not the sender's stored
captureLocalDate/timezoneOffsetMinutes. Host verification used UTC+07:00:
26 September 00:30 local corresponds to 25 September 17:30 UTC.

The shared `calendarMonthProvider` caches visited months in the session's
ProviderContainer. Selecting a day filters that loaded month without reads.
The current month initially selects today; moving to another month clears the
selected day, returning to the current month selects today. Day cells reuse
the first thumbnail and display the count when multiple memories exist.

A small publication signal invalidates only the matching month after a
successful publish; it does not initialize/fetch History to show Calendar.
Refresh explicitly invalidates the visible month (also useful after a new
delivery or block). No polling or Firestore subscriptions were added. Account
changes invalidate month data; stale data is not displayed while a new account
reloads. Signed-media URL caching is also scoped to the session; abandoned URL
providers auto-dispose and HTTP clients close with their repository. Existing
authenticated gateway URL resolution, four-minute repository cache and Flutter
image caching are reused. All list/grid/archive previews request only thumbnail
public IDs; only Detail requests the full public ID.

Calendar, Detail and media URL providers disable automatic error retries;
retry is explicit, avoiding background repeat reads on permission/network
errors. Failed Inbox refresh keeps previously loaded rows. Failed month refresh keeps
safe same-session prior data where available and offers retry. This is modest
in-process caching with the existing Firestore native persistence, **not full
offline support**, process-death cache recovery, or immediate revocation of
previously downloaded images. There is no persisted month-summary database.

## Existing block policy and release limitations

Existing `blockUser` changes the relationship to blocked, removes Close Friends
membership and revokes historical available deliveries **in both directions**.
`unblockUser` removes the blocked relationship; it does not restore revoked
deliveries or automatically re-establish friendship. Own published stamps
remain in the sender's archive. This phase consumes that status, not a separate
UI-only friendship/block algorithm. Revocation updates are batched after the
relationship change, so there is a propagation interval, not atomic all-history
revocation. Stale cache needs refresh. Sender profile names remain snapshots;
there is no additional profile-read permission to inspect a deleted account.

Inspected gateway limitation, intentionally not altered in this mobile phase:
`FirestoreRestMediaAuthorizer` currently reads only the first 100 delivery
documents, ignores delivery status, and allows own public-ID prefixes. Therefore
older delivery media can fail authorization even when the month metadata loads;
revoked delivery metadata can still authorize its media. Existing signed URLs
and downloaded bytes are not immediately revoked. **The mobile filtering and
7 Rules tests are not proof of end-to-end media revocation.** Fix and test this
gateway authorization gap before treating block/media access as production-safe
or exposing the Worker publicly. Durable Object work remains a separate
prerequisite; no public Worker exposure was attempted.

Other limits: the legacy Collection/own-History query still reads all own active
stamps (not used for Calendar/Inbox loading). Visited-month cache is not a bounded disk/LRU cache, month queries
fetch all matching documents within that month, and a timezone change while
running is not separately observed (restart/refresh after changing device
timezone). No realtime receive updates; reopen/refresh Inbox or refresh Calendar.
No iOS, Apple Sign-In, camera styling or unrelated backend refactor was done.

## Verification and modified files

Before changes: full Flutter suite **59/59 PASS**. Final analyzer is clean,
Flutter **75/75**, focused regression **21/21**, goldens **5/5**, Rules **7/7**,
Functions **9/9** and unchanged gateway **14/14** PASS. Final results and evidence
are recorded in `docs/evidence/2026-10-05/inbox-calendar-result.md` and
`testcase.md`; reference goldens were not regenerated. The former clamp-day
test was updated to assert the explicitly requested no-arbitrary-selection
behavior, not removed. Widget/repository tests use controlled repositories;
Rules tests use the real local Firestore emulator. Neither proves production
two-account E2E.

Phase-specific mobile files (under `apps/mobile/`):

- `lib/features/stamps/domain/repositories/stamp_repository.dart`
- `lib/features/stamps/data/repositories/firebase_stamp_repository.dart`
- `lib/features/stamps/data/repositories/in_memory_stamp_repository.dart`
- `lib/features/stamps/data/repositories/cloudinary_delivery_repository.dart`
- `lib/features/stamps/presentation/controllers/stamp_timeline_controller.dart`
- `lib/features/stamps/presentation/controllers/stamp_publication_controller.dart` (new)
- `lib/features/inbox/presentation/controllers/inbox_controller.dart` (new)
- `lib/features/inbox/presentation/screens/inbox_screen.dart`
- `lib/features/inbox/presentation/screens/stamp_detail_screen.dart`
- `lib/features/archive/presentation/controllers/memory_view_controller.dart`
- `lib/features/archive/presentation/screens/calendar_screen.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/core/widgets/memory_photo.dart`, `lib/core/widgets/stamp_artwork.dart`
- `test/features/inbox/inbox_calendar_test.dart` (new)
- `test/features/stamps/post_capture_flow_test.dart` (extended test repository)
- `test/features/archive/memory_interactions_test.dart` (selection contract)

Other phase files: `firestore.rules`, `firebase/firestore.indexes.json`,
`functions/test/firestore-rules.test.ts`, this document, the evidence summary,
`testcase.md` and the cross-phase note in `docs/INTERACTION_PHASE.md`.
There were extensive pre-existing workspace changes; this list identifies only
files touched for Inbox/Calendar, not all changes reported by Git.

## Prepared real E2E procedure (not yet executed)

Prerequisites: two authorized A/B sessions, deployed reviewed Rules/indexes,
reachable authenticated dev gateway, and safe emulator installation capacity.
Use a dev-only reachable address for Android (e.g. host alias 10.0.2.2), never
expose the Worker publicly to unblock testing. Do not print account tokens.

1. A/B become accepted friends. A captures and sends custom B. Record IDs and
   server timestamps without secrets. B reopens Inbox: verify exactly one new
   row, sender initials/name, thumbnail, received time and unread semantics.
2. B opens shared Detail: verify full photo; return and refresh; isSeen remains
   true. Restart/relogin B to verify backend persistence rather than local state.
3. A sends ALL. B receives exactly once; verify every additional eligible test
   recipient if available, with no delivery to blocked/non-friends.
4. B opens Calendar, refreshes the known month, verifies local day/count and
   Detail ID. Verify a server UTC time across local midnight with approved test
   data; never edit production timestamps just to manufacture evidence.
5. Block either direction. Refresh both archives: old received records are
   revoked, cannot open through repository Detail; own stamps remain. Verify
   actual gateway media behavior separately and record the known gap, not a
   presumed security PASS. Unblock: historical revoked records stay revoked.
6. Exercise offline loaded views, retry, older Inbox pages and older Calendar
   months, including more than 100 deliveries when gateway is corrected.

Android device: `Medium_Phone_API_36.1`, emulator-5554,
sdk_gphone64_x86_64, actual SDK **36**. AVD has a 6G data partition. At this phase
check `/data` was 5.8G total / 5.2G used / **393M available (94%)**. System
`pm trim-caches 1073741824` completed but did not improve available capacity;
the app cache/code_cache were only 8K each. No app data clear/uninstall, AVD wipe,
partition edit or APK installation was performed. There is no identified large
disposable APK in Download/tmp; Android Studio's temporary files were preserved.
Before installation, back up test state and expand the AVD safely while stopped
or identify disposable files with the user. Do not run Flutter's uninstall
fallback. Local gateway health remained unavailable and no A/B sessions were
supplied. Thus Inbox, Calendar and Friend Graph/send-receive **real E2E remain
NOT RUN**; the global milestone cannot close. The next development phase can
continue, but deployment/security/E2E release gates are still outstanding.
