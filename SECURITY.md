# Security policy

## Supported code

Security fixes are applied to `main` and the current active milestone branch.
Prototype code on older feature branches may not receive fixes.

## Reporting a vulnerability

Do not open a public GitHub issue for a vulnerability or leaked credential.
Contact the repository owner privately through GitHub instead and include:

- A concise description.
- Affected component and branch.
- Reproduction steps.
- Potential impact.
- A suggested mitigation, if known.

## Secrets policy

Never commit:

- Firebase service-account JSON.
- `google-services.json` or `GoogleService-Info.plist`.
- Generated `firebase_options.dart`.
- Apple `.p8`, `.p12`, `.cer` or provisioning profiles.
- Android keystores or `key.properties`.
- OAuth client secrets.
- `.env` files with real values.
- Push certificates or APNs private keys.
- GitHub, Firebase, Apple or Google access tokens.

Use Firebase/Google Secret Manager, GitHub Actions encrypted secrets and local
untracked environment files.

If a secret is committed:

1. Revoke or rotate it immediately.
2. Remove it from the working tree.
3. Rewrite Git history before sharing the repository further.
4. Review access logs and affected infrastructure.

Removing a secret in a later commit does not make the leaked value safe.

## Client-side Firebase configuration

Firebase client configuration identifies a Firebase project but is not an
authorization boundary. Firestore Rules, Storage Rules, App Check and callable
function authorization must protect every operation.

Production and development must use separate Firebase projects.

## Application signing

- Keep Android release keystores outside this repository.
- Keep Apple signing assets in the developer account/keychain.
- Never use debug signing for store releases.
- Use a separate development bundle identifier until the production identity
  is registered.

