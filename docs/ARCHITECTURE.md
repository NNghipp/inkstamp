# Inkstamp architecture

## Mobile

The mobile application uses feature-first Clean Architecture. A feature owns
its domain, data and presentation code. Shared UI primitives and technical
utilities live in `core`; app-wide routing and design tokens live in `app`.

```text
Screen -> Riverpod controller -> use case -> repository contract
                                             ^
                                             |
                                   repository implementation
                                             |
                                      external SDK
```

Screens do not import Firebase. Domain entities do not import Flutter. The
in-memory implementations make the visual product runnable before credentials
are available; Firebase implementations can replace them at provider
composition points without changing screens.

## Backend

Callable functions are the only route for privileged social mutations. Direct
client writes are limited to a user's own push-token documents and draft
media. Firestore and Storage otherwise use default-deny rules.

`publishStamp` resolves and validates the audience on the server, records a
request ID for idempotency, copies validated JPEG assets out of the draft
namespace, writes one private delivery per recipient, and sends a metadata-only
push notification.

Recipients read delivery documents in their own user subtree. A Storage rule
checks for that delivery before serving media. The sender reads the private
stamp document. Recipient IDs therefore never need to be exposed to another
recipient.

## Environments

Use separate Firebase projects:

- `inkstamp-dev`
- `inkstamp-staging`
- `inkstamp-prod`

Production functions require App Check. Emulator development may use debug
App Check tokens.

