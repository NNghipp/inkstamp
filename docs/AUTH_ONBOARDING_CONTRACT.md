# Authentication and onboarding contract

This document is the Phase 0 review artifact. It defines the contract to be
implemented by the Firebase adapter and callable Functions after approval.

## User document

`users/{uid}` is owned by privileged Functions. It contains only:

```text
uid: string
username: string
usernameNormalized: string
displayName: string
onboardingComplete: boolean
createdAt: server timestamp
updatedAt: server timestamp
```

`usernames/{usernameNormalized}` is the uniqueness index and contains the
owner UID and creation timestamp. It is maintained transactionally alongside
the user document. A username is lowercase and matches `[a-z0-9._]{3,20}`.

## Access policy

- Clients cannot read or write another user's profile, and cannot write any
  user profile or username index directly.
- Callable Functions authenticate the caller, validate inputs and own all
  profile/username mutations.
- Existing default-deny Firestore Rules remain in force until this policy is
  reviewed and covered by emulator tests.

## Session and routing

```text
No authenticated user              -> /welcome
Authenticated user with no profile -> /setup-username
Profile incomplete onboarding      -> /permissions, then /widget-intro
onboardingComplete = true          -> /inbox
```

The router will enforce these redirects in Phase 2 when the Firebase session
stream exists. Screens must not infer authentication from local UI state.

## Failure contract

The data layer maps SDK and callable failures into `AuthenticationFailure`.
Presentation shows a stable message and allows retry; it never receives an SDK
exception directly.
