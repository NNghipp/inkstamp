# Release hardening evidence — 2026-10-10

Owner clarified: portfolio/CV project, no PROD registration/signing yet. Spark preserved, no billing/production deployment. Work is assessed against the requested strict release gates anyway; missing PROD is not concealed by a DEV demo.

## Baseline before changes

Flutter 98/98; DEV-auth 7/7; focused regression 24/24; Rules 7/7; pagination 8/8; Functions 29/29 (+15 emulator-only tests skipped in ordinary npm test and separately executed); gateway 29/29. Analyzer clean. All five golden hashes match the prior phase.

## Camera evidence

Added tests initially reproduced lost resume (only one init instead of two) and committing a draft after background during capture. First real stress passed 20 rapid tabs and background init, then failed after Preview background/resume. Cause: resumed event was ignored by the Preview-covered CameraScreen. Fixed and rerun passed. An intermediate Gradle build failed due to a Kotlin DSL `java` namespace shadow; fixed by importing Base64 explicitly.

Latest [camera-stress.log](camera-stress.log): `rapid_switches=20 PASS`, Android HOME/activity-resume PASS, Preview background/draft retention/return/retake cleanup PASS, exit 0. Real CameraX and local processor; other tabs use existing demo repositories in this dedicated stress harness. This is not Google/backend auth coverage.

After merged permission removals, repeated the real Camera stress on 2026-10-11: all scenarios again PASS, exit0, no manual System UI intervention in this dedicated run. Latest log reports debug Camera opening **5,807 ms**. Earlier successful run:4,075 ms; earlier cold attempt:10,673 ms. These include mounting test UI and hardware initialization, not a production startup benchmark. No invented History/Inbox/Calendar/Detail latency or percentile numbers. Full production/device performance profiling remains unmeasured.

## Backend rerun

The first hardening A/B replay passed Friend Graph and actual custom capture/upload/publish, then found **0/126 pagination fixtures**. This is retained as a failed test attempt, not counted as PASS. Recreated only the existing dedicated DEV A/B fixture IDs and reran.

Final real DEV Android A/B replay **PASS 1/1**, exit 0, 5:52 on 2026-10-11: Friend Graph, custom capture/upload/publish/cleanup, ALL, 126 fixture cursor ties/gateway authorization after record 100, Inbox/read/Detail, Calendar, real committed-publish response-loss retry with no duplicate stamp/delivery, revoke and block/unblock/no restore. [Completed safe log](e2e-2026-10-11T09-12-59-457Z.log). Revoke reported `mediaDeleted=true`, repeat revoke succeeded, old **full-size** URL HTTP404. No separate old thumbnail URL HTTP probe was made; do not infer it from the full-size result.

The emulator displayed **System UI isn't responding** under host memory pressure during capture. Selecting Wait allowed the test to continue and all assertions passed. This was manual test-environment intervention and is **not an unattended/performance PASS**. Runtime test credential file absence and removal of fault-proxy ADB reverse5002 verified afterwards; only normal5001/8787 remain.

Security probe: missing auth 401, forged token 401, genuine real DEV user 200 with expected target. No token/password persisted in evidence.

## Final validation

Automated final run on 2026-10-10: Flutter **114/114**, enabled DEV-auth **7/7**, focused Camera/Preview/golden regression **30/30**, Rules **7/7**, pagination **8/8**, Functions **29/29** (15 emulator cases skipped in ordinary command and passed separately), gateway **36/36**. Analyzer: **0 issues**. Gateway TypeScript/build/local dry-run passed. Five golden hashes unchanged.

Two validation failures were fixed, not hidden: the old delivery test expected one cached authorization request (now intentionally two), and Windows temporary-file teardown raced with asynchronous account cleanup. Privacy assertions remain intact; cleanup only tolerates an already-absent test directory. The subsequent full Flutter run passed all 114 tests.

Continuation on 2026-10-11: the interrupted A/B rerun produced no completed evidence; previous failed replay is retained, followed by the completed PASS above. Ordinary debug artifact restored/build/install/launch PASS, detailed below. Both `flutter build apk --release --no-pub` and `flutter build appbundle --release --no-pub` failed **as intended** with “Release signing is not configured … debug signing is forbidden.” This proves missing-key fail-closed behavior, not a successful production build. An older 2026-10-07 release APK already on disk is not a current hardening artifact and must not be used as one.

## Final portfolio artifact

`D:\stampcard\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`

- Ordinary `lib/main.dart` debug DEV build, not the integration-test entry point. APP_ENVdev, enabled guarded DEV-auth, Functions5001/gateway8787. **Requires running host services + ADB reverse**, not a standalone deployed public backend.
- Build/install-r/launch PASS. Welcome and Sign in (Test A/B controls) visually inspected: [welcome](ordinary-dev-welcome.png), [sign in](ordinary-dev-sign-in.png). No Google sign-in was performed.
- Package `com.inkstamp.app`, app label `Inkstamp`, version0.1.0/code1, minSDK26/targetSDK36.
- APK SHA-256 `0A94F6BF5163FB731253683D50B0AA390AA7B2B939E7F3FBA98C2E7488F475AC`.
- Signature verified: **Android Debug**, certificate SHA-256 `8b32a0101df8c228229d5b61537c5a9677c582ab7f638ef614b4be80a510d326`. This is expected for this debug demo, explicitly not production signing.
- Merged permissions: CAMERA + INTERNET; normal SDK ACCESS_NETWORK_STATE, WAKE_LOCK, C2DM RECEIVE, READ_GSERVICES and app-scoped DYNAMIC_RECEIVER_NOT_EXPORTED. No microphone, external storage, notifications, biometric/fingerprint or ad/attribution/referrer permissions remain.
- Private E2E credential file absent after ordinary install; fault proxy5002 closed/reverse removed. Functions5001/gateway8787 intentionally retained for local demo. Owned idle Gradle daemons stopped after builds to reduce host memory pressure; no user emulator wipe.
- Final analyzer rerun **0 issues**. Gradle warns some inherited plugins still apply KGP and may need future migration; current debug builds pass, no blind dependency upgrade performed.

## Requested 28-point report

1. **Camera root cause:** overlapping initialize/dispose and stale async completion; Preview suppressed resume. Real stress exposed the Preview case before the fix.
2. **Camera fix:** FIFO hardware operations, session generations, route ownership, idempotent handle disposal, preview detachment and active-only resume.
3. **App lifecycle:** real emulator initialization/Preview background tests PASS; interrupted capture unit test PASS. Real background upload/capture, process death and OEM testing remain uncovered.
4. **Revoke guarantee:** new media authorization denied after revoke; server attempts deletion of full + thumb; app reauthorizes and evicts tracked cache keys. Status LIMITED.
5. **Cache/CDN limitation:** downloaded copies cannot be erased; asynchronous CDN invalidation, old bearer URL window, deletion failures and revoked delivery tombstone metadata remain documented.
6. **Environments:** centralized DEV/staging/prod policy and fail-closed public templates. Real PROD resources do not exist; no billing/deployment.
7. **DEV auth exclusion:** debug + DEV + explicit flag + allowlist only; non-debug guard tests PASS. No current production binary exists for string inspection.
8. **IDs/flavors:** preserve `com.inkstamp.app`; no unregistered flavor/package rename.
9. **Signing:** debug release fallback removed; both missing-key release builds rejected. No release key created.
10. **Google configuration:** existing DEV JSON/package/OAuth types inspected; provider/SHA/release OAuth/real login not verified.
11. **Deep links:** auth gating, pending invite and malformed target tests PASS; `/u/` HTTPS filter. Real PROD domain/assetlinks/certificate/cold-warm OS tests absent.
12. **Network/TLS:** HTTPS outside local debug DEV, bounded request/token/body waits, Firebase-owned token refresh, no infinite retry. Release cleartext disabled. Library-added unused permissions explicitly removed and verified absent in rebuilt APK.
13. **Logging/privacy:** allowlisted structured events; no arbitrary error/stack/token/private URL serialization; gateway errors sanitized.
14. **Crash handling:** framework + uncaught async hooks installed. Remote automatic Crashlytics/Analytics collection disabled; no remote telemetry claim.
15. **Performance:** latest debug Camera stress open5,807 ms (earlier4,075 ms; test UI + native init). Other requested latency/device-scale benchmarks not measured; no invented numbers. Full backend replay required System UI Wait, so not an unattended performance certification.
16. **Firestore:** Rules 7/7 + cursor pagination 8/8; no Rules relaxation. Unbounded History/month/friend queries remain a documented scale concern.
17. **Gateway:** 36/36; signed App Check project-number verification added; bounded requests/delete deadline and best-effort bounded limiter. Not a distributed rate-limit guarantee.
18. **Draft cleanup:** success/discard, retry retention, 24h stale cleanup and account-scope file cleanup tested. In-memory unsent drafts are not restored after process death.
19. **Account privacy:** UID/generation-scoped resets, old draft file deletion and tracked image eviction; DEV-auth 7/7 and real full A/B replay PASS1/1 with the environment intervention documented above.
20. **Accessibility:** shutter semantic label added without visual change; existing targets/audience selection/reduced motion retained. Full TalkBack/large-text/contrast audit not completed.
21. **Release APK:** BLOCKED, missing signing/PROD; fail-closed behavior verified. Ordinary debug demo build/install/launch/signature/merged permissions PASS, artifact above.
22. **Release AAB:** BLOCKED, same verified missing-signing preflight; no new AAB produced.
23. **Tests:** Flutter 114/114; DEV-auth 7/7; focused 30/30; Rules 7/7; pagination 8/8; Functions 29/29 (+15 skipped in ordinary test, executed separately); gateway 36/36.
24. **Analyzer:** 0 issues.
25. **Goldens:** all five tests/hashes unchanged; no screenshot baseline regenerated.
26. **Remaining gates:** isolated PROD + signing, actual Google, real App Links, accepted/strengthened media policy, production/R8 smoke, remaining lifecycle/performance/accessibility/device checks.
27. **GOOGLE AUTH E2E:** DEFERRED, not PASS.
28. **PRODUCTION RELEASE:** NOT READY. Portfolio clarification does not authorize inventing or waiving release evidence.

## Release gates (conservative until final verification)

| Gate | Status | Evidence / remaining requirement |
|---|---|---|
| CORE DEV E2E | PASS | Final2026-10-11 replay1/1, exit0; System UI Wait intervention documented, not a performance certification |
| CAMERA LIFECYCLE | PASS for tested emulator scenarios | Real stress exit 0 + race tests; physical/OEM/interrupted-upload/process-kill testing not covered |
| MEDIA REVOKE PRIVACY | LIMITED | Server delete/authorization + app cache hardening; CDN/bearer URL/deletion failure/retained tombstones |
| PRODUCTION ENV CONFIG | FAIL | Fail-closed template only; owner has no PROD project/gateway |
| RELEASE SIGNING | FAIL | No keystore; debug fallback removed |
| PRODUCTION BUILD | FAIL | No eligible signed/configured RC |
| GOOGLE AUTH E2E | DEFERRED | No actual Google sign-in run |
| DEEP LINK PROD | FAIL | Auth routing tests/local filter; domain/certificate association/cold-warm production verification absent |
| PRODUCTION SMOKE | BLOCKED | No production artifact/auth/environment |
| PRODUCTION RELEASE | NOT READY | No gate waived by portfolio clarification |

## Golden SHA-256

| File | Hash |
|---|---|
| calendar.png | 0F77ADCEAD873CE9DD8C1AD2E7F2718488CEF6B365E3752C8963BB531BC75C44 |
| camera.png | 5E253257687011AFA0A3E586E8B29ACD0CAB6E67BB1504E52A3CCD623243BD2A |
| feed.png | 8E87C1F3D7FDD1DD21B2C371ECE1B0A3F837823AF9C02E348BC0ABBE1AA477C3 |
| preview.png | 536930BAE1A9FAD93AD2F320D3D1513AC94F47AE33BAC526B85B17C2D218C13E |
| profile.png | 0401AAC4DC89E99B39B53E877DFB1C33D8B52042F723A3B342B965906FAC8892 |
