# Inkstamp media gateway spike

This Cloudflare Worker is an isolated feasibility spike for issuing
user-scoped Cloudinary authenticated-upload signatures. It is not deployed and
is not part of the production Inkstamp backend.

## Local checks

```bash
npm install
npm run build
npm test
npm run check
npx wrangler types --check
```

`npm run check` performs a Wrangler dry run. It does not deploy the Worker.

## Local configuration

Copy `.dev.vars.example` to `.dev.vars` and provide development-only values.
`.dev.vars` is ignored by Git.

Never commit:

- `CLOUDINARY_API_SECRET`
- Firebase credentials or service accounts
- App Check debug tokens
- production project identifiers

## Endpoint

```text
POST /v1/media/upload-signatures
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

{"mediaKind":"stamp"}
```

Accepted media kinds are `stamp` and `thumbnail`. The request body is limited
to 1024 bytes. Successful responses contain public Cloudinary configuration,
signed upload parameters and an authenticated upload URL. API secrets are
never returned.

## Deployment blockers

- Verify Firebase App Check tokens in addition to Firebase ID tokens.
- Add per-user and per-IP rate limiting.
- Add private, short-lived media delivery URL issuance.
- Approve the Cloudinary account, quotas and retention policy.
- Add staging and production Worker environments.

Do not run `wrangler deploy` until all blockers are resolved and the repository
owner explicitly approves deployment.
