# Inkstamp — Week 1 completion and code review

## Status

**Week 1 is complete. Work stops at this milestone.**

The repository now has a runnable, English-first Flutter foundation, a
feature-first Clean Architecture, separate screen files and routes, Android
and iOS runners, a native widget technical spike, Firebase backend scaffolding,
security rules, tests and CI.

Code created for later product areas is a navigable prototype/scaffold. It is
not counted as production completion of Weeks 2–14.

## Week 1 deliverables completed

- Product identity changed to Inkstamp.
- Android application ID and iOS bundle ID set to `com.inkstamp.app`.
- Custom scheme configured as `inkstamp://`.
- Universal/app-link host configured as `inkstamp.app`.
- Flutter stable project and Android/iOS platform runners generated.
- Feature-first Clean Architecture established:
  - `domain`
  - `data`
  - `presentation/controllers`
  - `presentation/screens`
  - `presentation/widgets`
- Riverpod dependency injection and immutable feature states established.
- GoRouter navigation and separate route files established.
- Every planned screen has a separate file and focused responsibility.
- Inkstamp design tokens, paper texture and code-native stamp renderer added.
- App experience and notification/widget copy changed to English-first.
- Android widget implemented with `AppWidgetProvider` and `RemoteViews`.
- iOS WidgetKit reference implementation and Flutter method-channel bridge added.
- Firebase Functions TypeScript project, Firestore Rules and Storage Rules added.
- CI workflow added for Flutter and backend quality gates.
- Product plan saved as `PLAN.md`.
- Architecture/setup documentation saved under `docs`.

## Prototype scaffolding prepared for later weeks

The following is present so architecture and navigation can be reviewed early,
but still uses in-memory repositories or placeholder device behavior:

- Authentication and onboarding screens.
- Camera simulation, preview, stamp editor and audience selector.
- Inbox, reactions and stamp replies.
- Calendar archive.
- Friends, requests, Close Friends and blocking.
- Settings, privacy, reporting and account deletion screens.
- Callable Firebase Functions for the planned social operations.

These items are not considered production-ready until their scheduled weeks.

## Final verification

| Check | Result |
|---|---|
| Dart formatting | Passed, 78 files checked |
| Flutter analyzer | Passed, no issues |
| Flutter unit/widget tests | Passed, 12 tests |
| TypeScript compiler | Passed |
| ESLint | Passed |
| Backend unit tests | Passed, 8 tests |
| Android debug APK | Built successfully |
| English-first regression tests | Passed |
| Vietnamese runtime copy scan | No unintended Vietnamese UI copy found |

Android artifact:

```text
apps/mobile/build/app/outputs/flutter-apk/app-debug.apk
```

## Bugs found and fixed during review

- Fixed the Welcome screen overflowing on short or landscape viewports.
- Fixed a pending Splash timer causing widget-test leakage.
- Removed an unused permission package that forced an unnecessary Android SDK.
- Disabled Kotlin incremental compilation to avoid cross-drive cache corruption
  when the project and Pub cache live on different Windows drives.
- Replaced the incompatible Glance spike with a dependency-light native
  `AppWidgetProvider` implementation.
- Fixed the inactive Decline friend-request action.
- Fixed profile initials not refreshing while editing a display name.
- Made publish quota consumption idempotent for retry requests.
- Prevented failed publish attempts from leaving permanent request locks.
- Added cleanup of partially copied media after failed publish attempts.
- Changed Storage Rules so revoked deliveries cannot continue reading media.
- Changed block revocation to process all matching deliveries, not only the
  first batch.

## Review findings intentionally left for later milestones

- Mobile repositories are currently in-memory; Firebase mobile adapters are a
  Week 2+ task.
- Apple/Google authentication needs real Firebase credentials and store
  signing configuration.
- The camera screen uses a visual simulation; device capture and image
  processing belong to Weeks 6–7.
- iOS compilation and WidgetKit target integration require macOS/Xcode and have
  not been device-tested.
- Firebase Rules emulator integration tests are not yet part of Week 1.
- Push delivery, App Check enforcement and real widget background refresh need
  staging credentials.
- Android release signing still needs the owner's keystore.
- Firebase Flutter plugins emit a future Kotlin migration warning; current
  debug builds succeed.
- `npm audit` reports seven moderate transitive findings in the current
  Firebase Admin/Google Cloud dependency chain. A forced automatic fix would
  downgrade Firebase Admin and is not applied. Recheck when upstream packages
  release patched dependency versions.

## Milestone map

| Planned period | Current status |
|---|---|
| Week 1: branding, architecture, design system, widget spike | **Complete** |
| Weeks 2–3: production auth and onboarding | Scaffold only |
| Weeks 4–5: production friend graph | Scaffold only |
| Weeks 6–7: real camera and stamp renderer pipeline | Scaffold only |
| Weeks 8–9: mobile upload and delivery integration | Backend scaffold only |
| Week 10: production Inbox/reaction/reply | Scaffold only |
| Week 11: production Calendar/archive | Scaffold only |
| Weeks 12–13: production push and widgets | Technical spike only |
| Week 14: production moderation/privacy/deletion | Backend scaffold only |
| Weeks 15–16: analytics, device QA and beta release | Not started |

## Next milestone entry criteria

Week 2 should not begin until:

- Firebase dev/staging projects are created.
- Apple and Google sign-in credentials are available.
- The owner confirms the final domain and bundle identifiers.
- A macOS/Xcode environment is available for iOS signing and widget testing.

