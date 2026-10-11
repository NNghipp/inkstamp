# InkStamp — Technical Interview Notes

Use these as prompts, not a memorized script. Explain code you actually understand; distinguish implementation, test evidence and remaining gates.

## Why Flutter?

Flutter gives this project one widget/state/testing stack for the paper/stamp UI and native-plugin boundaries. The demonstrated target is Android; shared Dart code is not proof of iOS completion. Riverpod manages feature/account scopes and GoRouter handles authenticated navigation.

## Why one-screen Post-Capture?

Preview, audience and Check/send use the same draft instead of passing it through multiple editor pages. Sending locks recipient edits/discard; failure retains processed files and completed upload identities. Widgets own motion/navigation, while `PostCaptureController` orchestrates the existing composer/timeline repositories.

## How does Friend Graph work?

Username lookup and relationship mutations use callable Functions, not unrestricted client writes. Deterministic pair IDs and transactional relationship checks handle duplicate requests/state transitions. Publish resolves accepted recipients; block removes Close Friends edges and revokes old deliveries. Only the original blocker can unblock, and unblock does not restore friendship or old deliveries.

## How does retry avoid duplicates?

A UUID v5 request identity derives from sender and uploaded full/thumbnail IDs. The client preserves those IDs and audience after publish is attempted. The server transaction writes the request ledger, stamp and deterministic recipient deliveries together. Repeating a request reads the ledger rather than fan-out again. The real fault-proxy test drops a response **after commit**, then confirms retry still creates one stamp/delivery. A timeout alone cannot prove failure.

## How does account switching avoid leaks?

UID-scoped providers reset Friends, Inbox, Calendar, History/collection references and drafts. Generation checks reject old async completions; owned draft paths are cleaned, tracked image-cache keys evicted and authenticated routes redirected. This protects rendering/session state; it is not a guarantee of forensic erasure of Firebase/device disk caches.

## How does Calendar handle timezones?

UI grouping compares local year/month/day after `toLocal()`. Query bounds represent local month/day boundaries converted for server timestamps. Sent/received memories share the Stamp model and Detail route. Server `createdAt` is delivery time, not an invented client timestamp. Test boundaries rather than comparing UTC date strings or assuming every date maps to midnight UTC.

## How does pagination work?

Inbox orders `createdAt DESC` and document ID DESC, fetches 26 to expose 25 and uses the last exposed timestamp/ID as a value cursor. Ties remain deterministic; removing a cursor document does not invalidate cursor values. Gateway authorization separately follows Firestore REST pages of 100 under a deadline. The real 126 delivery fixtures prove traversal, **not 126 camera publishes**. Unbounded History/month/friend queries still need scale review.

## What caused the camera race?

Initialize/dispose could overlap, old disposal could clear a new handle and stale initialization could mark an inactive screen ready. Preview also suppressed resume. FIFO operations, generations and route leases establish ownership; detach preview before disposal, dispose the captured handle idempotently and resume only an active screen. Evidence includes race unit tests and real 20-transition/background/Preview stress, not every OEM camera driver.

## How are photos processed?

The processor corrects orientation, square-crops and creates 1440×1440 full/512×512 thumbnail JPEGs with metadata stripped. Displayed portrait framing is UI presentation, not a claim that stored bytes are 3:4. Temporary files are app-private; success/discard/account change cleanup is ownership-scoped. Failed sends retain retryable files. Process-death unsent-draft recovery is not implemented.

## What does revoke actually guarantee?

The sender-only transaction revokes access, then attempts full/thumbnail Cloudinary deletion with invalidation. A repeat can retry cleanup; `mediaDeleted=false` must not be hidden. New URL authorization fails; app media is reauthorized and tracked cache keys evicted. The DEV old full URL returned 404, but that does not prove all CDN/browser caches or saved copies erased. Block retains assets other recipients still use; existing URLs are short-lived bearer capabilities. Own revoked delivery tombstone metadata remains SDK-readable under existing Rules.

## Why is Google E2E deferred?

No real Google account sign-in E2E was completed. Guarded Firebase email/password A/B identities provide deterministic DEV business-flow tests; they are not a substitute for Google/OAuth/release-certificate verification. Don't imply Google is broken or verified without evidence.

## What is needed for production?

An explicitly authorized isolated Firebase/gateway environment; production signing/OAuth fingerprints; real Google login and App Links; accepted or strengthened revoke policy; signed/R8 release smoke; remaining device/lifecycle/accessibility/performance/scale checks. Spark/local Functions were selected without enabling billing or deploying production. Production remains NOT READY.

For an unguided demo, also wire accessible Friends navigation and an approved sender-revoke interaction: existing routes/backend behavior do not establish those missing UI entry points. This portfolio task documents that gap without changing the product.

## How convincing are the tests?

Use exact counts in the [overview](PORTFOLIO_OVERVIEW.md#verified-results), not a summed total. Unit tests isolate failure paths; golden tests protect frozen visuals; real A/B integration verifies cloud DEV transport/business behavior. The latest A/B replay passed with an emulator System UI Wait intervention under host memory pressure—not unattended/performance certification. The later dedicated Camera run needed no such intervention.

[Source/evidence](evidence/2026-10-10/release-hardening/result.md) · [Demo sequence](RECRUITER_DEMO.md)
