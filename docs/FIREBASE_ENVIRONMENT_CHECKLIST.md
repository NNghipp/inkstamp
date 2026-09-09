# Firebase environment checklist

This checklist is intentionally configuration-only. Do not commit generated
Firebase options, OAuth client secrets, APNs keys, Android keystores or debug
App Check tokens.

## Environments

| Environment | Firebase project | Purpose | Deployment policy |
| --- | --- | --- | --- |
| Development | `inkstamp-dev` | Local development and emulator-connected builds | Manual approval required |
| Staging | `inkstamp-staging` | Internal device testing | Manual approval required |
| Production | `inkstamp-prod` | Customer release | Out of scope for this milestone |

## Console checklist

For a Spark-only development project, enable and configure only the no-cost
services that the milestone needs:

- Firebase Authentication with Apple and Google providers.
- Firebase Cloud Messaging, Analytics and Crashlytics.
- App Check in monitoring mode. Register debug tokens only for development;
  do not enforce App Check until real-device verification is approved.

Cloud Firestore is permitted within its Spark quota. Do not enable Cloud
Functions or provision Cloud Storage in a Spark-only project: both require a
Blaze billing account for production use. Use the local Emulator Suite for
Functions, Storage and Rules integration tests instead.

## Closed-beta media candidate

- Cloudinary is being evaluated as the media provider for closed beta; do not
  treat it as approved or provision Firebase Cloud Storage yet.
- Use a Cloudinary Free account only after the owner approves the account and
  its usage limits.
- Never commit Cloudinary API secrets. The mobile app may hold only public
  configuration supplied by the approved integration.
- Production-quality private media requires signed upload and short-lived
  signed delivery URLs issued by a trusted backend. Do not use an unsigned,
  publicly deliverable preset for private social content.

## Mobile configuration checklist

- Register Android package `com.inkstamp.app` and iOS bundle identifier
  `com.inkstamp.app`.
- Configure Apple Service ID, team identifier, key ID and private key outside
  the repository.
- Configure Google OAuth client IDs for Android, iOS and the required server
  audience outside the repository.
- Run `flutterfire configure` only after the project and both app records are
  approved. Review generated files before committing non-secret configuration.

## Release guardrails

- Never link a Cloud Billing account, enable Cloud Functions, provision Cloud
  Storage or deploy Functions without explicit approval.
- Rules and indexes may be tested only in the local Emulator Suite while this
  project remains Spark-only.
- Keep App Check unenforced in development and staging until device tests pass.
- Use separate Firebase projects; never point a development build at
  production.
- Store all credentials in the approved secret manager or CI secret store,
  never in Git or application source.
