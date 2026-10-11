# InkStamp — CV Project Description

Use the following as editable contribution wording, not proof of sole authorship. Keep only work you personally performed and can explain. UI implementation follows supplied HTML/PNG references; do not claim original ownership of those designs/photos.

## 1. One-line CV Version

Developed a Flutter Android stamp-sharing app with native camera/image processing, Firebase and Cloudflare/Cloudinary integration, and verified A/B DEV E2E flows.

## 2. Three-bullet CV Version

- Implemented a camera-first Flutter flow with Riverpod state management, a single-screen preview/audience/send interaction, and 1440×1440 / 512×512 image processing with EXIF removal.
- Integrated authenticated friend sharing, Inbox/read state and Calendar memories; verified custom/ALL delivery, cursor pagination, retry idempotency, block/unblock and revoke in real Firebase DEV A/B E2E.
- Added lifecycle/privacy/failure-handling regression coverage: 114 Flutter tests, 5 unchanged golden references, 20 rapid Camera tab transitions and separately verified backend/security suites.

The 114 is the Flutter suite count, not a sum with its focused/DEV-auth reruns. Backend evidence: Functions 29/29, gateway 36/36, Rules 7/7 and pagination 8/8. Avoid claiming all checks are independent tests or every product behavior is production-verified.

## 3. Interview Explanation

“InkStamp turns an in-app photo into a stamp shared with a small friend audience. I worked on [replace with your actual contribution]. The app uses Flutter/Riverpod and repository contracts, Firebase Auth/Firestore, callable Functions and a media Worker that authorizes authenticated Cloudinary assets.

“Two engineering examples I can explain are camera ownership across async tab changes and retry after a server commit whose response never reaches the client. The first uses serialized operations and generations; the second keeps stable media/request IDs and atomically writes a publish ledger and deliveries.

“The Android DEV flow has real A/B evidence, not just mocked UI. It remains a local-backend portfolio demo: Google Sign-In E2E is deferred, production signing/deployment are not complete, and revoke cannot erase saved copies. I would finish those gates and device/scale validation before calling it a release.”

## Claims to Avoid

Do not say production-ready, deployed to Play, public real-time social network, proven at scale, millions of users, instantaneous media erasure or independently designed every asset. Do not claim reaction/push/Apple production coverage merely because UI/dependencies exist.

[Project overview](PORTFOLIO_OVERVIEW.md) · [Interview notes](INTERVIEW_NOTES.md) · [Verified evidence](evidence/2026-10-10/release-hardening/result.md)
