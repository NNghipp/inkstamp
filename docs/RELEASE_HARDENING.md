# Android hardening / portfolio readiness

Date: 2026-10-10 (Asia/Saigon). The owner clarified that this is a small CV/portfolio project, not a Play Store launch. Spark is retained. No PROD registration, domain, signing key, billing upgrade or deployment is required to demonstrate the DEV product. **Portfolio DEV evidence is not production readiness.**

## Architecture and environments

Flutter → Firebase Auth/Firestore and callable Functions → authenticated Cloudinary media gateway. DEV uses real `inkstamp-dev` Auth/Firestore, local Functions and local Wrangler through `adb reverse`; it is not an entirely offline emulator setup. Functions verify real Firebase tokens, including revocation, rather than trusting emulator-decoded JWT context.

`AppEnvironment` centralizes public mobile configuration. Only debug DEV allows loopback HTTP. Profile/release reject DEV; remote staging/prod require an explicit isolated project, HTTPS gateway, Functions region and Firebase app registration. Bootstrap no longer falls back silently to demo repositories on Firebase failure. `DEMO_MODE` is debug-only. No staging infrastructure currently exists; no production identifiers have been invented.

`apps/mobile/config/prod.example.json` deliberately contains empty required values. It is a setup template, not a usable production configuration. Public Firebase app IDs/API keys and OAuth client IDs are configuration, not signing/Cloudinary secrets. Never put passwords, service-account keys or Cloudinary API secrets in dart-defines. The server gateway has a separate fail-closed production Wrangler environment; its secrets must be configured separately if a release is later authorized.

## Camera lifecycle

Root causes: concurrent init/dispose; an old dispose clearing a newly created handle; stale init updating `ready` after tab removal; a single `_initializing` boolean dropping a legitimate resume request; and ignoring `resumed` while Preview was open.

Policy: release hardware off-screen and reinitialize on return. Controller and native repository serialize operations. A generation invalidates stale async results. Route leases prevent delayed disposal of an old CameraScreen from suspending its successor. Preview is detached before native disposal. Native dispose detaches its own handle first and is idempotent for an already-empty handle. Pause/hidden/inactive/detached suspend; resume initializes only an active screen. Returning from a tab reads the current application lifecycle rather than trusting a stale foreground flag.

Capture interrupted before committing a draft is canceled; raw/processed files are cleaned, no duplicate draft is committed. A completed Preview draft survives a brief background/resume. Hardware operations are serialized rather than falsely canceled by a timeout while still owning the camera. Physical-device/OEM testing remains desirable; emulator results do not cover every camera driver.

## Media privacy: LIMITED, not instantaneous erasure

Uploads use Cloudinary `authenticated`, with separate 1440 full and 512 thumbnail resources. Only the server holds the API secret. Revoke first atomically revokes stamp/delivery access, then attempts server-side destroy of both resources with `invalidate=true`. Repeated revoke is idempotent and retained owner metadata permits retry. Failure to delete returns `mediaDeleted=false`; there is not yet a durable deletion retry queue.

New gateway URL requests require an active owned stamp or available received delivery. Direct unsigned media is denied. Download URLs expire after 300 seconds. Mobile no longer treats its old four-minute signed-URL cache as authorization: each resolution rechecks the gateway. Mounted media and Detail metadata revalidate every 30 seconds while foreground timers execute; leaving an image/disposing its user-scoped delivery repository evicts tracked NetworkImage keys. This does not promise a 30-second wall-clock SLA when Android suspends the process or the network is unavailable. SDK requests have bounded UI waits; failure hides/retries content rather than authorizing it.

Important limitations:

- Bytes already downloaded, screenshots, exports, browser/disk caches and recipient-controlled copies cannot be erased remotely.
- Cloudinary invalidation is asynchronous. Signed delivery URL invalidation is not universally enabled by default; account-specific CDN behavior must be tested before claiming immediate revoke. See [Cloudinary invalidation documentation](https://cloudinary.com/documentation/invalidate_cached_media_assets_on_the_cdn).
- Blocking a recipient does not destroy an asset still owned by the sender/available to other recipients. An already issued URL remains a bearer capability until expiration; in-app periodic reauthorization limits continued display but cannot invalidate an externally copied URL.
- Existing Firestore Rules permit a user to read their own revoked delivery tombstone. Copied metadata can therefore remain visible through direct SDK reads even though app Detail returns unavailable and new media authorization is denied. **Direct revoked metadata denial is not implemented or claimed.** Tightening that rule requires changing the gateway's recipient authorization queries, not simply changing Rules and breaking pagination.
- Metadata can remain in Firebase's account-scoped/offline cache. UI/session guards prevent rendering another user's data; forensic disk erasure is not claimed.

Accept this limited DEV/portfolio policy explicitly if appropriate. Production strong revoke remains a release gate until deletion failures, CDN behavior, bearer URL window and retained metadata are accepted or strengthened. No production acceptance has been inferred from the portfolio clarification.

## Signing / Android identity / Google

Preserve the established `com.inkstamp.app` namespace/application ID. No flavors or `.dev` suffix were added because the existing Firebase Android registration and OAuth configuration use this package. If future DEV/PROD coexistence is required, create explicit Firebase registrations and verify links/SHA before introducing flavors.

Release no longer uses debug signing. Ignored `apps/mobile/android/key.properties` requires `storeFile`, `storePassword`, `keyAlias`, `keyPassword`; keep the keystore outside version control. No production key was generated. Release task preflight rejects missing signing, conventional debug key/alias, DEV flags, mixed Firebase project, demo mode and missing explicit PROD configuration. Actual certificate fingerprints must still be reviewed: a renamed debug key must not be approved merely because preflight accepts its filename.

The current `google-services.json` identifies `inkstamp-dev`, package `com.inkstamp.app`, and OAuth client types 1 and 3. This is not a verified PROD registration. Optional `GOOGLE_SERVER_CLIENT_ID` is explicit public configuration. Google provider enablement, SHA-1/SHA-256, Play signing/upload certificate compatibility, release OAuth client and real Google account login remain unverified for production. **Google E2E: DEFERRED.** No A/B Google accounts were created.

Release preparation reference: [Android signing](https://developer.android.com/studio/publish/app-signing). An internal debug APK for portfolio is not a signed production APK/AAB.

## Network / logs / errors

Release manifest has cleartext disabled and Internet enabled. Debug's network-security XML allows only local loopback cleartext. Photo capture uses `enableAudio=false` and app-private temporary files. Artifact inspection found libraries reintroduced microphone, storage, notification, biometric and advertising permissions; explicit manifest-merger removal directives now exclude these unused permissions, including ad attribution/referrer permissions. Firebase SDK normal network/wake-lock/receiver permissions are documented separately from dangerous permissions. Final APK merged-manifest results are recorded in the dated evidence.

Gateway calls: 15-second delivery wait, 30-second upload/signature wait, bounded token/App Check loads, and bounded upload response-body wait. Upload destinations must be HTTPS `api.cloudinary.com`. Firestore mobile reads have a 20-second UI timeout. Callable SDK waits are bounded by its SDK settings; publish response ambiguity is handled with the same idempotency request/media IDs, not blind repeated upload. No infinite retries or manual token persistence. Firebase owns refresh; 401/403 fail visibly without automatic loops.

`SafeErrorReporter` installs framework and uncaught async hooks. It serializes only allowlisted event/severity, never arbitrary errors, stacks, user records, tokens, headers or private URLs. Bootstrap no longer prints raw exceptions. Camera/filesystem user messages are generic. Native Crashlytics/Analytics automatic collection is disabled pending an approved collection policy. Crashlytics package/Gradle plugin exist, but **remote crash telemetry is not configured/claimed**; local structured error events are the baseline. No paid service was added.

Gateway unexpected logs contain only fixed event/error category and known endpoint path. App Check failure responses do not expose upstream exceptions. App Check now requires the exact project-number issuer/audience plus JWT header, signature and expiry, per [Firebase custom backend verification](https://firebase.google.com/docs/app-check/custom-resource-backend).

## Backend / Rules / scale

Rules are not relaxed by this phase. Unauthorized profile/username/friendship writes, cross-user delivery/archive reads, forged/read-field mutations remain denied. Inbox uses 25 records plus lookahead and timestamp/document-ID cursor tie handling. Existing indexes cover Inbox/month/friendship queries.

Gateway request bodies remain bounded (1 KiB upload/delete, 4 KiB delivery), 1–50 media IDs and safe format validation. Authorization scans 100-record recipient pages under a 12-second deadline, failing closed on non-OK/repeating tokens. Owner active-media lookup is exact/limited. Cloudinary destroy now has a 12-second abort deadline. Responses use `Cache-Control: no-store`.

Anti-abuse: server daily publish/friend-request quota; idempotent publish ledger; upload/delete 20 and delivery 50 requests/minute plus 100/IP/minute in the existing best-effort isolate limiter when enabled. Its map is bounded/expired entries cleaned, but it is **not a distributed guarantee across isolates/restarts**. A future public deployment requires account-level/rate-binding/WAF review, including repeated revoke calls; no new paid infrastructure was provisioned.

Remaining scale concerns: History, a Calendar month and friendship lists can be unbounded; recipient authorization scans history rather than an indexed media→delivery lookup. Appropriate for the controlled portfolio dataset, not evidence of large-scale readiness. Do not truncate data silently to manufacture query bounds; add repository pagination when justified by real scale/performance measurements.

## Drafts / account privacy / deep links / accessibility

Successful send/discard clears full+thumb; failed upload retains retryable draft; ambiguous committed publish retains its stable IDs. Old-draft files are removed on composer scope/account invalidation without reading Riverpod state in disposal callbacks. Startup/Camera cleanup removes only owned Inkstamp files older than 24 hours. Process-death restoration of an in-memory unsent draft is **not implemented**: orphan files age out, retry state is not durable across a killed process. Brief background is supported; killed process is a separate recovery gate.

UID-scoped Friends/Inbox/Calendar/History/Collection reset and generation checks remain. Sign-out's delayed completion cannot overwrite a newer controller operation. Delivery repository disposal evicts its tracked image keys. Auth redirect hides private Detail/Friend routes after logout. Splash navigation is now a cancelable timer, and router/notifier lifetimes are disposed with their provider.

Invite paths validate existing username syntax (`[a-z0-9._]{3,20}`), defer lookup until fully authenticated/onboarded, and resume the pending username after auth. Unknown/blocked users use existing server policy. Android HTTPS intent filter is restricted to `/u/`. The custom scheme remains an unauthenticated routing input, not a trusted authentication assertion. Production App Links still need domain `assetlinks.json`, actual production certificate, cold/warm real link verification; no domain ownership was assumed.

Camera's shutter now has a Vietnamese button semantic label without visual changes. Existing 44dp Camera controls, 82dp shutter, bottom-nav targets, audience check/semantic selection and reduced-motion behavior are retained. Full TalkBack/large-text/contrast physical-device audit remains separate; automated/golden checks are not a claim of complete accessibility certification.

## Validation and smoke

See [dated evidence](evidence/2026-10-10/release-hardening/result.md) for exact final counts, emulator logs, artifacts, unresolved checks and release gates. All five source golden PNG hashes must remain unchanged.

Production smoke (not PASS without a real release): fresh install → startup/onboarding/auth → actual Google login → Camera permission denied/granted → rapid tabs → background init/capture/Preview/upload → History/Inbox/Calendar/Profile → offline/timeout/401/403 → cold/warm valid/invalid/blocked invite → logout/B login/no stale Detail/image → old full/thumb URLs after revoke → R8/minified release repeat. APK and AAB need signing/isolated configuration before this can be run.

For CV, accurately describe a **Flutter Android portfolio app with real DEV Firebase E2E, authenticated Cloudinary gateway, privacy/lifecycle regression tests and documented production gates**. Do not claim a launched Play Store app, completed Google production login, immediate erasure, or production-scale SLA.
