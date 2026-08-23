# Branching strategy

## Long-lived branches

### `main`

Stable, reviewed milestone snapshots. Android/iOS builds from this branch
should pass the documented quality gates. Store releases and version tags will
be created from `main`.

### `develop`

Integration branch for the next milestone. Feature branches target `develop`,
not `main`.

## Preserved milestone branch

### `feature/week-01-foundation`

The completed Week 1 foundation:

- Inkstamp identity and English-first UI.
- Flutter Clean Architecture and routing.
- Design system and stamp renderer.
- Android/iOS runners and widget spike.
- Firebase backend/rules scaffold.
- Tests, CI and repository documentation.

This branch is retained as a reviewable historical checkpoint.

## Future branch naming

```text
feature/week-02-firebase-auth
feature/week-04-friend-graph
feature/week-06-camera-pipeline
fix/stamp-publish-idempotency
chore/flutter-upgrade
docs/security-model
```

## Merge policy

- Use pull requests into `develop`.
- Prefer squash merge for small focused features.
- Use merge commits when preserving a milestone branch.
- Require formatter, analyzer, tests and backend build to pass.
- Never merge credentials, signing files or generated local configuration.
- Promote `develop` into `main` only after milestone review.

## Tags

Milestone tags use:

```text
week-01-complete
week-02-complete
```

Release tags begin when closed beta packaging starts:

```text
v0.1.0-beta.1
```

