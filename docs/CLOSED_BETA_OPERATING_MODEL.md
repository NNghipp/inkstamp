# Closed-beta operating model

## Objective

Run a small, invite-only Inkstamp beta without linking a Firebase Cloud Billing
account. This mode validates the mobile experience and domain contracts; it is
not a production launch configuration.

## Allowed cloud services

- Firebase Spark: Authentication, Cloud Firestore within quota, Analytics,
  Cloud Messaging, Crashlytics and App Check in monitoring mode.
- Cloudinary Free: media experimentation only, after explicit account approval.

## Local-only services

- Firebase Functions, Firestore Rules integration and Storage integration run
  through the Firebase Emulator Suite.
- No Functions, Rules, indexes or Storage configuration is deployed to the
  Firebase project in this mode.

## Non-negotiable security rules

- Never place a Cloudinary API secret in Flutter or Git.
- Do not use unsigned public uploads for private stamps.
- Before real people exchange private images, select and approve a trusted
  signature/delivery backend. Until then, media flows remain local/emulator
  test flows.

## Beta limits

- 50 to 200 invited users.
- Maximum 50 friends per account and 30 stamps per day.
- 1440px JPEG no larger than 5 MB plus a 512px thumbnail.
- Review Cloudinary monthly credits and Firebase quota dashboards before each
  beta expansion.
