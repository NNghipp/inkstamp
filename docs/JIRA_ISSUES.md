# Week 2 Jira-ready issue log

Jira synchronization is pending because no Jira connector is available in the
current workspace. `INK` is a provisional project key; replace it with the
actual Jira project key during synchronization.

## Issue summary

| Provisional key | Type | Priority | Status | Summary |
| --- | --- | --- | --- | --- |
| `INK-LOCAL-001` | Bug | Medium | Fixed | Router failed to compile after session redirect refactor |
| `INK-LOCAL-002` | Bug | Medium | Fixed | English-first widget test lacked ProviderScope |
| `INK-LOCAL-003` | Bug | High | Fixed | Media gateway TypeScript files contained Dart syntax |
| `INK-LOCAL-004` | Bug | High | Fixed | Media gateway used the generic upload endpoint for authenticated assets |
| `INK-LOCAL-005` | Security | Highest | Open | Media gateway does not verify Firebase App Check tokens |
| `INK-LOCAL-006` | Security | High | Open | Media gateway has no distributed rate limiting |
| `INK-LOCAL-007` | Task | High | Blocked | Real Firebase Apple/Google authentication needs approved project configuration |
| `INK-LOCAL-008` | Maintenance | Medium | Open | Firebase plugins still apply the legacy Kotlin Gradle Plugin |

## Fix notes

### `INK-LOCAL-001`

- Cause: `app_router.dart` used `BuildContext` without importing Flutter
  material types.
- Fix: added the correct import and reran analyzer/tests.
- Verification: `flutter analyze` and all Flutter tests pass.

### `INK-LOCAL-002`

- Cause: `InkstampApp` became a Riverpod consumer but the existing widget test
  still mounted it without `ProviderScope`.
- Fix: updated the test harness and added an end-to-end in-memory onboarding
  router test.
- Verification: the complete Welcome-to-Camera flow passes.

### `INK-LOCAL-003`

- Cause: the initial Worker draft mixed Dart constructs such as `final`,
  `Future`, `required` and `on Error` into TypeScript.
- Fix: rewrote the application, verifier and presentation layers as strict
  TypeScript.
- Verification: TypeScript build, seven tests and Wrangler dry-run pass.

### `INK-LOCAL-004`

- Cause: the signature response pointed to the generic Cloudinary upload
  endpoint while the spike requires authenticated assets.
- Fix: changed the target to the authenticated image upload endpoint and added
  regression assertions.
- Verification: gateway tests confirm the authenticated URL and ensure the API
  secret is absent from responses.

## Open issue notes

### `INK-LOCAL-005`

Production deployment is blocked until every media-signature request verifies
both a Firebase ID token and a valid App Check token.

### `INK-LOCAL-006`

Production deployment is blocked until a distributed per-user and per-IP rate
limit is designed and tested. Module-level counters are explicitly prohibited
because Worker isolates are reused and not globally consistent.

### `INK-LOCAL-007`

The mobile foundation remains in demo/in-memory mode. Real Apple/Google sign-in
requires owner-approved Firebase projects, app registrations and credentials.
No credential or billing change will be made without explicit approval.

### `INK-LOCAL-008`

The Android debug build succeeds, but Flutter reports that several Firebase
plugins still apply the Kotlin Gradle Plugin and may fail with a future Flutter
release. Recheck compatible Firebase package versions before the next Flutter
upgrade; do not force an incompatible dependency update during this milestone.
