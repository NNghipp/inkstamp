# Contributing to Inkstamp

Inkstamp currently follows a solo-developer Git flow, but every change should
remain reviewable and reversible.

## Workflow

1. Branch from `develop`.
2. Use a focused branch name such as `feature/week-02-firebase-auth`.
3. Keep screens, business rules and SDK adapters in their correct layers.
4. Add or update tests.
5. Run all quality gates.
6. Open a pull request into `develop`.
7. Merge `develop` into `main` only at a reviewed milestone.

## Clean-code rules

- Domain code must not import Flutter or Firebase.
- Screens render state and dispatch actions only.
- Repository contracts belong in `domain`.
- SDK implementations belong in `data`.
- DTOs must be mapped before reaching presentation.
- Do not hardcode routes, collection names, colors or spacing.
- Every asynchronous screen supports loading, empty, error and retry states.
- A routable screen lives in its own file.
- Do not log tokens, media URLs or private user content.

## Required checks

```bash
cd apps/mobile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

cd ../../functions
npm run lint
npm test
npm run build
```

## Commit style

Use an imperative, scoped subject:

```text
feat(auth): add Firebase Google sign-in adapter
fix(stamps): prevent duplicate publish retries
test(friends): cover request rejection
docs(repo): document Week 1 milestone
```

