<p align="center">
  <img src="docs/assets/inkstamp-mark.svg" width="112" alt="Inkstamp mark">
</p>

<h1 align="center">Inkstamp</h1>

<p align="center">
  <strong>Turn moments into stamps.</strong><br>
  A camera-first private social app for sharing small, collectible moments
  with friends.
</p>

<p align="center">
  <a href="https://github.com/NNghipp/inkstamp/actions/workflows/ci.yml">
    <img src="https://github.com/NNghipp/inkstamp/actions/workflows/ci.yml/badge.svg" alt="CI">
  </a>
  <img src="https://img.shields.io/badge/status-week%201%20complete-96B5CA" alt="Week 1 complete">
  <img src="https://img.shields.io/badge/Flutter-clean%20architecture-02569B" alt="Flutter Clean Architecture">
</p>

## About

Inkstamp turns immediate camera moments into aesthetic digital stamps.
Stamps can be shared privately with all friends, Close Friends or selected
people. Recipients can react with an emoji, reply with another stamp and
revisit shared memories through a calendar archive.

The product is designed around a small private network rather than a public
social feed.

## Product principles

- **Camera first:** moments are captured in the app, not imported from a gallery.
- **Private by default:** every recipient is resolved and authorized explicitly.
- **Simple creation:** one crop, a small set of stamp edges and paper tones.
- **Photo-led responses:** emoji reactions and stamp replies instead of text chat.
- **Collectible memories:** sent and received stamps remain available by date.

## Current milestone

**Week 1 is complete.**

The repository currently provides:

- An English-first Flutter application foundation.
- Feature-first Clean Architecture with separate screen files and routes.
- A navigable in-memory prototype covering the planned MVP screens.
- Code-native paper textures and stamp rendering.
- Android and iOS application runners.
- Android home-screen widget implementation and an iOS WidgetKit spike.
- Firebase Cloud Functions, Firestore Rules and Storage Rules scaffolding.
- Automated formatting, analysis, tests and CI.
- A successfully built Android debug APK in the local development workspace.

The camera, authentication and Firebase mobile repositories are still demo
implementations. See [WEEK_1_REVIEW.md](WEEK_1_REVIEW.md) for the exact
production-readiness boundary.

## Architecture

```text
apps/mobile/lib/
├── app/                       App composition, routing and design system
├── core/                      Shared result types and UI primitives
└── features/
    ├── authentication/
    ├── onboarding/
    ├── camera/
    ├── stamps/
    ├── inbox/
    ├── archive/
    ├── friends/
    ├── notifications/
    ├── widget_sync/
    ├── safety/
    └── settings/
```

Each feature follows:

```text
presentation -> use cases -> domain <- data implementations <- SDKs
```

Screens render state and dispatch user actions. They do not query Firebase,
process images or own business rules.

Backend functions follow:

```text
callable controller -> service/use case -> repository -> Firebase Admin SDK
```

Read the full design in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Technology

- Flutter and Dart
- Riverpod
- GoRouter
- Firebase Authentication, Firestore, Storage, Functions and Messaging
- TypeScript and Zod
- Native WidgetKit on iOS
- Native AppWidgetProvider on Android

## Run the demo

### Mobile

```bash
cd apps/mobile
flutter pub get
flutter run
```

The current app starts in demo mode and does not require Firebase credentials.

### Backend

```bash
cd functions
npm install
npm run lint
npm test
npm run build
```

Detailed platform and Firebase setup instructions are available in
[docs/SETUP.md](docs/SETUP.md).

## Quality gates

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

cd functions
npm run lint
npm test
npm run build
```

At the Week 1 checkpoint:

- Flutter analyzer: no issues.
- Flutter tests: 12 passing.
- Backend tests: 8 passing.
- Android debug APK: builds successfully.

## Branches

- `main`: stable, reviewed milestones.
- `develop`: integration branch for the next milestone.
- `feature/week-01-foundation`: preserved Week 1 implementation branch.

See [docs/BRANCHING.md](docs/BRANCHING.md) for naming, merge and release rules.

## Roadmap

- Weeks 2–3: production authentication and onboarding.
- Weeks 4–5: production friend graph.
- Weeks 6–7: real camera and image-processing pipeline.
- Weeks 8–11: upload, delivery, Inbox and Calendar integration.
- Weeks 12–14: push, widgets, moderation and account deletion.
- Weeks 15–16: analytics, device QA and closed beta.

The full roadmap is documented in [PLAN.md](PLAN.md).

## Security

Do not commit Firebase credentials, signing keys, service accounts, `.env`
files or store certificates. Read [SECURITY.md](SECURITY.md) before connecting
a production Firebase or Apple/Google developer account.

## License

This is a personal, proprietary project. All rights are reserved. See
[LICENSE](LICENSE).

