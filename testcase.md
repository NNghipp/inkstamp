# Test Cases Week 2-3

Ngày cập nhật gần nhất: **2026-09-11**. `T1/T2/T3` là ba lần/kênh kiểm tra; dấu `-`
nghĩa là chưa thể chạy do thiếu thiết bị hoặc cấu hình bên ngoài.

Android emulator được chủ dự án chấp nhận là bằng chứng E2E đủ để đóng milestone.
Phiên bản/model emulator của lần chạy thủ công chưa được ghi nhận.

| Name / Screen | Description | Input / Scenario | Expected result | Test result 1 | Test result 2 | Test result 3 | Stage | Proof |
|---|---|---|---|---|---|---|---|---|
| Worker / Health | Kiểm tra đủ biến môi trường | `GET /health` với config hợp lệ | HTTP 200, không lộ secret | Pass unit | Pass local trước đó | Pass dry-run | PASS | `worker.test.ts`; Wrangler check |
| Worker / Invalid config | Thiếu Cloudinary secret | Secret rỗng | HTTP 503, nêu tên biến, không lộ giá trị | Pass | Pass | - | PASS | Worker unit test |
| Worker / Auth | Thiếu/sai ID token | Không có hoặc token giả | HTTP 401 trước khi tính quota | Pass | Pass | - | PASS | Worker unit test |
| Worker / App Check | Thiếu App Check khi enforce | `APP_CHECK_ENFORCED=true` | HTTP 403 | Pass | Pass | - | PASS | Worker unit test |
| Worker / Rate limit | Quota user/IP và reset | Vượt upload/delivery quota | 429 + `Retry-After`, scope độc lập | Pass | Pass | Pass | PASS | Rate limiter unit tests |
| Auth / Firebase config | App/package/SHA Android | `inkstamp-dev`, debug keystore | Đúng app ID, SHA-1/SHA-256 có mặt | Pass CLI | Pass CLI | - | PASS | `firebase apps:android:sha:list` |
| Auth / Google provider | Google OAuth Android client | Bật provider và tải SDK config | Có Android/Web OAuth client | Pass Console | Pass CLI | Pass APK build | PASS | Firebase hiển thị Google Enabled; SDK config có OAuth clients |
| Auth / Controller | Sign-in thành công/hủy/lỗi | Fake repository | Route đúng và lỗi cụ thể | Pass | Pass | Pass | PASS | Flutter controller tests |
| Auth / Session | Đóng/mở app | Firebase auth stream + profile | Khôi phục đúng stage | Pass unit | Pass router logic | Pass emulator (owner verified) | PASS | Android emulator; version not recorded |
| Auth / Sign-out | Sign-out | User đang đăng nhập | Router về welcome/sign-in | Pass code | Pass unit hiện hữu | Pass emulator (owner verified) | PASS | Android emulator; version not recorded |
| Username / Validation | Hợp lệ, sai, hoa/thường | `New.User`, ngắn, ký tự cấm | Trim/lowercase, 3-20, chỉ `[a-z0-9._]` | Pass | Pass | Pass | PASS | Functions schema tests |
| Username / Race | Hai user reserve cùng tên | Hai transaction đồng thời | Chỉ một transaction thành công | Pass code review | - | - | WORK IN PROGRESS | Cần Functions emulator callable test |
| Firestore Rules | Chặn ghi trực tiếp | Client ghi username/profile | Bị từ chối | Pass emulator | Pass | - | PASS | Rules test 2/2 |
| Onboarding / Persist | Permissions và widget intro | Restart từng stage | Mở đúng profile/permissions/widget/app | Pass controller | Pass router | Pass emulator (owner verified) | PASS | Android emulator restart; version not recorded |
| Upload / Validation | File thiếu/sai MIME/quá lớn | Missing, PNG, >5 MB | Reject trước upload | Pass | Pass | Pass | PASS | Flutter repository tests |
| Upload / Signed request | Stamp/thumbnail | JPEG + ID/App Check token | Public ID đúng tham số Worker đã ký | Pass mock | Pass Worker | Pass emulator (owner verified) | PASS | Real authenticated Cloudinary upload from emulator |
| Upload / Timeout | Gateway/Cloudinary chậm | Timeout | UI thoát loading, báo retry | Pass | Pass | - | PASS | Flutter timeout test |
| Upload / Cleanup | Thumbnail/publish lỗi | Stamp đã upload | Xóa asset đã upload thuộc UID | Pass client | Pass Worker auth | Pass emulator (owner verified) | PASS | Android emulator integration |
| Publish / Idempotency | Retry cùng asset | Gọi lại publish | Cùng request ID, không tạo stamp trùng | Pass code/unit | Pass transaction logic | Pass emulator (owner verified) | PASS | Android emulator integration |
| Delivery / Authorization | Owner/recipient/người lạ | Xin URL bằng public ID | Chỉ owner/recipient hợp lệ nhận URL | Pass Worker | Pass Rules | Pass emulator (owner verified) | PASS | Authenticated Android emulator flow |
| Delivery / Cache | URL còn trong cache | Đọc cùng asset hai lần | Chỉ gọi gateway một lần | Pass unit | Pass | - | PASS | Flutter delivery repository test |
| Android / E2E | Toàn luồng thật | Sign-in đến sign-out | Upload/publish/xem ảnh thành công | Config pass | APK pass | Pass emulator (owner verified) | PASS | Android emulator accepted as milestone evidence; version not recorded |
| Android / Offline | Mất mạng/upload/resume | Ngắt mạng giữa upload | Không kẹt loading, retry/cleanup đúng | Pass timeout unit | Pass emulator (owner verified) | - | PASS | Android emulator; version not recorded |
| iOS / Apple Sign-In | Hoãn đến sau bản Android hoàn chỉnh | Không chạy trong milestone Android | Không chặn milestone | - | - | - | DEFERRED | Theo quyết định chủ dự án |
| Security / Secret scan | Không commit secrets | Git tracked files/diff | Không có `.dev.vars`, token hoặc secret | Pass ignore | Pass scan | Pass diff | PASS | `.gitignore`, `git ls-files`, secret scan; rotate được miễn cho dev |
| Production / Rate limit | Limiter phân tán | Worker public nhiều isolate | Durable Object limiter | - | - | - | WORK IN PROGRESS | Blocker trước deploy, ngoài local milestone |

## Production Friend Graph — Week 4–5

| Area | Scenario | Expected result | Stage | Proof |
|---|---|---|---|---|
| Repository selection | Firebase configured / demo mode | Firebase repository in configured builds; in-memory only in demo/test | PASS | Provider wiring + Flutter analyzer |
| Friend mutations | Accept, decline, Close Friends, remove | State changes only after repository succeeds and survives reload | PASS | Flutter controller tests |
| Friend screens | Invite search, request acceptance, audience selection | Existing screens render and dispatch production friend state | PASS | Flutter widget tests |
| Firestore Rules | Member, stranger and Close Friends access | Members can read their relationships; strangers and client writes are denied | PASS | Firestore Rules Emulator 5/5 |
| Android friend E2E | Two accounts: search → request → accept → Close Friends → audiences → remove | Complete Firebase flow succeeds without demo fallback | WORK IN PROGRESS | Requires interactive Android emulator run with two accounts |

## Camera and Image Processing — Weeks 6–7

| Area | Scenario | Expected result | Stage | Proof |
|---|---|---|---|---|
| Camera controller | Initialize, flash, switch lens, pause/resume | State and camera resources remain consistent | PASS | Flutter controller tests |
| Permission/error UI | Permission denied, initialization pending, retry | Explicit loading/error UI and retry action | PASS | Flutter widget tests |
| Image normalization | Landscape/portrait capture with EXIF orientation | Center-cropped square JPEG outputs at 1440 and 512 | PASS | Image processing tests |
| Privacy and size | Source contains EXIF/text metadata | Output metadata is empty and each JPEG is at most 5 MB | PASS | Image processing tests |
| File lifecycle | Success, invalid input, retake and stale draft | Raw/old files are removed; drafts expire after 24 hours | PASS | Image processing/controller tests |
| Android camera E2E | Capture → preview → retake → editor → audience → publish | Processed image and thumbnail upload successfully | WORK IN PROGRESS | No Android emulator is currently connected |

## Animation and functional flow — 2026-10-05

Emulator: AVD `Medium_Phone_API_36.1`, serial `emulator-5554`, reported model
`sdk_gphone64_x86_64`, Android SDK/API **36**. These results supersede the
previous note that no emulator was connected, without closing full Camera E2E.

| Area | Scenario | Result | Evidence / limits |
|---|---|---|---|
| Static analysis | Final implementation | PASS — no issues | `flutter analyze --no-pub` |
| Full Flutter suite | Current tests, preserving existing coverage | PASS — 59/59 | `flutter test --no-pub`; prior baseline 45 |
| Focused final verification | Camera, Preview and golden regression after live-preview fix | PASS — 21/21 | Camera test directory, Post-Capture widget tests and `visual_ui_test.dart` |
| Camera UI baseline | Frozen settled Camera and other design screens | PASS — 5/5 golden tests | Existing PNG files unchanged; explicit fixtures for data-driven screens |
| Capture / discard | Duplicate capture prevented; processed image enters Preview; X returns safely | PASS — automated | Camera controller and Post-Capture widget tests |
| Audience | ALL default, custom multi-select, ALL reset, empty custom disabled | PASS — automated | `post_capture_flow_test.dart`, `post_capture_screen_test.dart` |
| Publish | One submission, inline progress, automatic return, retained failed draft, stable retry assets | PASS — automated with test repositories | Real production repository wiring is retained; these tests do not prove backend E2E |
| History / Calendar / Collection | Photo → Detail; overlays/title limit; date/month updates; collection filtering | PASS — automated | `memory_interactions_test.dart` |
| Reduced motion | Send and automatic return with animations disabled | PASS — automated | Post-Capture widget test |
| Android camera hardware | Real front/back capture, 1440 image, 512 thumbnail, empty EXIF, cleanup | PASS — emulator hardware subset | `apps/mobile/integration_test/camera_hardware_test.dart`; `docs/evidence/2026-10-05/camera-hardware-result.md` |
| Emulator environment | Model/API and environment screenshot | RECORDED | `docs/evidence/2026-10-05/emulator-environment.png` is an environment screenshot, not a captured-photo/publish proof |
| Friend Graph E2E | Two accounts: request/accept/reject/Close Friends/block/unblock/QR/deep link | NOT RUN | Authorized test account sessions are still required |
| Camera → Publish → Delivery E2E | ALL/custom recipient; authenticated upload, callable publish, recipient delivery; network failure/retry | NOT RUN | Local gateway `/health` on port 8787 was unavailable; account sessions and reachable dev gateway required |

The integration APK installation hit insufficient emulator storage. Flutter
automatically removed the old app before reinstalling, so its previous local
data/login session may have been lost. Code and repository changes were not
removed. The architecture-specific normal APK was subsequently installed with
`adb install -r` successfully; no uninstall fallback was used for restoration.
This is recorded separately from test PASS results.
The latest x86_64 APK builds successfully, but updating the restored normal app
with that final artifact still returns `INSTALL_FAILED_INSUFFICIENT_STORAGE`.
The earlier normal-app build remains installed. Free emulator storage before
the required production E2E; no additional app uninstall was performed.

No full Friend Graph or Camera/Image Processing E2E milestone is marked
complete. `WEEK_2_REVIEW.md` is not advanced for this phase. Architecture, file
list, retry limitations and remaining E2E procedure are in
`docs/INTERACTION_PHASE.md`.

## Inbox + Calendar integration — 2026-10-05

Evidence summary: `docs/evidence/2026-10-05/inbox-calendar-result.md`.
Architecture, modified-file list, repository APIs, Rules/index deployment gates
and prepared two-account scenarios: `docs/INBOX_CALENDAR_PHASE.md`.
PASS below means automated/local verification unless explicitly labeled E2E.

| Area | Scenario | Result | Evidence / limits |
|---|---|---|---|
| Baseline | Before this phase | PASS — 59/59 | Full Flutter suite |
| Analysis/full regression | Final code and new coverage | PASS — zero analyzer issues; 75/75 Flutter | `flutter analyze --no-pub`, `flutter test --no-pub` |
| Camera/Preview/reference UI | Existing interaction coverage | PASS — 21/21; 5/5 goldens | PNGs unchanged; no Camera styling changes; frozen fixtures, not live E2E |
| Inbox loading/order | Delivery-backed page, server newest first, deterministic equal-time cursor | PASS — automated | New repository/controller tests; 25/25/1 cursor pages |
| Inbox unread/read | Dot and semantic label; Detail lookup finishes before write | PASS — automated | Pending-lookup widget test; thumbnail vs full references asserted |
| Read persistence/error | Repository isSeen persists; one write; failed read does not block Detail; reopen retries | PASS — automated | Controlled repository, not production two-account persistence proof |
| Inbox pagination | Load-more adds unique rows, final page stops | PASS — automated | Widget 25→30 rows; repository no duplicate/gap tests |
| Inbox empty/error/offline | Minimal empty state, inline retry, keep loaded rows after failure | PASS — automated | New Inbox tests; no full-offline claim |
| Unavailable/blocked memory | Repository excludes unavailable items; invalid Detail does not mark read | PASS — automated | Controlled repository and real Rules authorization tests; gateway revocation not proven |
| Calendar range | Half-open local month query, not full timeline; zero History reads | PASS — automated | Range assertions, endpoint exclusion, publish invalidation test |
| Calendar grouping | UTC timestamp crosses host +07 local midnight; multiple memories/day and empty day | PASS — automated | UTC 25 Sep 17:30 → local 26 Sep 00:30 |
| Calendar selection/navigation/cache | Today in current month; clear unrelated month selection; back/forward cached | PASS — automated | No day-selection requery; two month ranges only |
| Calendar/Detail | Retry after fetch failure; thumbnail/photo opens same shared Detail ID | PASS — automated | Calendar widget and existing History/Collection widget tests |
| Lifecycle/account changes | Cached Inbox/month state does not carry to another simulated account | PASS — automated | A/B session test; disposed providers, no realtime listener introduced |
| Firestore Rules | Own delivery access/read update; protect other fields/users; authorized month queries | PASS — 7/7 on emulator | Java from Android Studio JBR; no production Rules/index deployment |
| Functions | Existing backend tests and lint | PASS — 9/9; lint clean | Functions source unchanged; Rules executed separately, not counted as plain npm-test PASS |
| Media gateway | Existing unit regression | PASS — 14/14 | Gateway source unchanged; first-100/status-check gaps remain |
| Emulator storage | Safe pre-install capacity inspection and system cache trimming | STILL LIMITED — 393M free | API36, emulator-5554, sdk_gphone64_x86_64, 6G data partition; trimming gave no measurable gain; no app/session wipe/uninstall/install |
| Inbox E2E | A custom/ALL publish → B receive/unread/thumbnail/Detail/persisted read | NOT RUN | Authorized A/B sessions absent; local gateway health unavailable |
| Calendar E2E | Real received memory correct local day/count/Detail | NOT RUN | Same account/gateway prerequisites; new phase APK not installed |
| Block E2E | Historical delivery and signed-media revocation | NOT RUN / RELEASE GAP | Backend revokes both directions; unblock does not restore. Gateway currently ignores status and only checks first 100 deliveries |

No Friend Graph/send-receive milestone is closed. Development can continue to
the next phase, but release requires reviewed Rules/index deployment, safe
emulator capacity, a reachable authenticated gateway, gateway authorization
hardening and real two-account evidence. Durable Object/public Worker exposure,
iOS and Apple Sign-In remain outside this phase.

## Android E2E closure attempt — 2026-10-06

Milestone **OPEN**. Full case register (case IDs, A/B roles, DEV environment,
model/API, expected/actual, BLOCKED reasons and evidence) is in
`docs/evidence/2026-10-06/e2e-closure/result.md`. All real A/B cases remain
BLOCKED, not PASS; automated coverage is not substituted for E2E.

| Area | Actual result | Status / evidence |
|---|---|---|
| Baseline and final Flutter | 75/75; focused21/21; analyzer zero issues | PASS automated; closure report |
| Final Rules / Functions / gateway | Rules7/7; Functions9 PASS +7 Rules skipped/executed separately; gateway14/14, TypeScript clean | PASS local; closure report |
| Emulator/storage | Old AVD393M preserved; new `InkStamp_E2E_API_36_1`, `sdk_gphone64_x86_64`, API36, UTC+07, 12G partition; 11G free after boot, 9.4G after APK install | PASS environment; no old app/session wipe |
| Rules/index deploy | Explicit `inkstamp-dev` only; deploy exit0; all5 indexes READY | PASS deployment, not mobile query E2E |
| Gateway | Local127.0.0.1:8787; host/emulator health200; unauthenticated upload401; Android APK targets this URL via adb reverse | PASS smoke; authenticated auth/upload/publish BLOCKED |
| Accounts | User has no dedicated Google A/B; no personal accounts/fake Firebase users used | BLOCKED AUTH-A / AUTH-B |
| Backend | Cloud Functions API read403 SERVICE_DISABLED; no API/billing enablement or Functions deployment | BLOCKED backend; verify callable region/App Check too |
| Friend Graph | Search/request/accept/duplicate/Close Friends/reject/block/unblock/QR/deep link not executed | BLOCKED FG-01 through FG-12 |
| Camera/custom send | No real authenticated capture/process/custom upload/publish/draft cleanup/duplicate prevention run | BLOCKED CAM-01/02, CUSTOM-01/02, DRAFT-01, DUP-01 |
| Inbox/Detail/read | No A→B delivery or persistent read verified | BLOCKED INBOX-01, DETAIL-01, READ-01 |
| Calendar | No real received local-date/month/boundary/Detail verified | BLOCKED CAL-01/02 |
| ALL / retry | No authenticated ALL delivery or safe failed-send/retry | BLOCKED ALL-01, RETRY-01 |
| Block/revoked | Backend revokes both directions; unblock does not restore; gateway status check missing | BLOCKED BLOCK-01, REVOKED-01; source findings only |
| First100 gateway scan | `pageSize=100` per account per lookup, no nextPageToken; not daily send quota; no limit removed | BLOCKED real LIMIT-01; source review recorded |
| UI/product changes | None this run; five PNG goldens untouched; no bug fixed without reproduction | No redesign/new phase |

Evidence screenshot is environment/app-launch only, not auth/capture/delivery
proof. To resume: prepare two human-verified dedicated Google accounts; obtain
authorized DEV backend/API/App Check setup; verify region and authenticated
gateway; execute required cases and address pagination/revocation blockers.
Do not close the milestone or claim production-ready before that evidence.

## DEV test authentication — 2026-10-07

Setup/security: `docs/DEV_TEST_AUTH.md`. Complete case register with A/B roles,
environment/model/API, expected/actual and evidence:
`docs/evidence/2026-10-07/dev-auth-e2e/result.md`.

| Area | Result | Scope / evidence |
|---|---|---|
| Real DEV users | PASS | Firebase UID/profile/username provisioning for test-a / test-b; credentials local and ignored |
| Real Android auth | PASS1/1 | Firebase A profile/UID→logout→B profile/UID→logout; existing auth abstraction, not mock |
| Real Android camera subset | PASS in same smoke | A authenticated rear/front capture,1440/512,empty EXIF,local cleanup; permission pre-granted; not custom publish/send |
| Production guard | PASS automated | Debug + APP_ENVdev + explicit flag + exact project/email; release/profile blocked, no hidden-button-only guard |
| Session isolation/UI | PASS automated |7 new tests; Inbox/Calendar/Friend Graph reset and stale-result protection; runtime password dialog |
| Draft/session isolation | PASS automated | A's draft image/recipient references reset on logout/UID change; covered by enabled DEV test |
| Ordinary DEV APK | PASS build/install/launch | Restored with adb install -r; actual DEV login UI screenshot;9.0G free; no original AVD wipe |
| Full regression | PASS82/82; focused21/21 | Existing75 retained; five goldens unchanged; analyzer zero issues |
| Rules / Functions / gateway | PASS7/7,9/9,14/14 | Plain Functions suite skips7 Rules cases, separately executed; no Rules/backend/gateway logic changed |
| Friend Graph | BLOCKED | Search/request/accept/duplicate/Close Friends/reject/block/unblock require unavailable callables |
| Custom/ALL publish | BLOCKED | No real send/publish/delivery or successful-draft-cleanup E2E |
| Inbox/read/Detail/Calendar | BLOCKED | No real received stamp; auth smoke not counted as send-receive proof |
| Retry/block/revoked | BLOCKED | Callable backend and gateway authorization gaps remain |
| Cloud Functions DEV | BLOCKED / Spark retained | User explicitly rejected new billing costs; no API enablement or Functions deployment |
| Google Sign-In A/B E2E | **DEFERRED** | Still mandatory before production release; not PASS |

**CORE ANDROID E2E: OPEN. PRODUCTION AUTH E2E: DEFERRED.
PRODUCTION RELEASE: NOT READY.**

## Spark backend unblock — continuation 2026-10-08

Implementation: `docs/BACKEND_DEV_UNBLOCK.md`. Current evidence and limitations:
`docs/evidence/2026-10-07/backend-unblock/result.md` (requested folder date retained).

Verified on 2026-10-08: Flutter98/98; enabled DEV-auth7/7;
Camera/post-capture/visual regression24/24; Rules7/7; Firestore cursor tests8/8;
Functions29/29; gateway29/29. Functions skips15 emulator-only cases in its normal
unit command; those run and pass separately. Analyzer clean, five goldens unchanged.

Functions Emulator uses real DEV Auth and controlled cloud Firestore, with explicit
server-side token verification; missing/forged signatures rejected. Gateway local
only via Wrangler; no billing upgrade or deployment. Pagination fixtures126 are
not camera publishes. Final Android real-UI A/B E2E PASS1/1 (5:01), all required
gates together; see timestamped2026-10-08T13-56-07-107Z safe log. Core CLOSED for
this DEV path, not production. Google remains DEFERRED and
production remains NOT READY. Old signed URLs/cache and saved bytes have documented
revocation limitations.

Ordinary DEV APK restored/build/install/launch PASS; normal Sign in shows Test A/B
controls, local Functions5001/gateway8787 (requires running host services).
Fault proxy closed, runtime credential file removed, safe logs checked,8.8G AVD
free. Camera visuals/5 goldens unchanged. **CORE ANDROID E2E: CLOSED for this
documented DEV path. GOOGLE AUTH E2E: DEFERRED. PRODUCTION RELEASE: NOT READY.**
Rapid Camera-tab/native initialization hardening and production backend/media/
attestation/auth release gates remain; closed Core is not release approval.

## Android hardening / CV portfolio — 2026-10-10, continued 2026-10-11

Owner clarified: personal portfolio, not Play Store registration. Spark retained;
no billing, production deployment, Google account creation or release key generation.
Implementation: `docs/RELEASE_HARDENING.md`. Full 28-point report and gate matrix:
`docs/evidence/2026-10-10/release-hardening/result.md`.

Baseline before edits confirmed: Flutter98, DEV-auth7, focused24, Rules7,
pagination8, Functions29, gateway29; analyzer clean, five golden hashes unchanged.
Final automated runs: **Flutter114/114, DEV-auth7/7, focused30/30,
Rules7/7, pagination8/8, Functions29/29, gateway36/36**. The 15 Rules/pagination
tests skipped in ordinary Functions command were separately executed. Functions
build/lint and gateway TypeScript pass; Flutter analyzer zero issues.

Camera race tests initially failed on stale resume and draft commit after pause;
fixed with serialized operations, generations and route leases. Real CameraX
stress PASS:20 rapid tab transitions, Android HOME/resume during init, Preview
background/draft retention, return/retake/file cleanup. First real stress failed
after Preview and was corrected before final PASS. Camera visuals unchanged.

Media resolution now reauthorizes instead of trusting four-minute cached URLs;
mounted Detail/media recheck with foreground timers and tracked image eviction.
Privacy status **LIMITED**: revoked tombstone metadata, old bearer URL/CDN window,
failed resource deletion and already-downloaded copies are not concealed.

Central config fails closed; release/profile DEV-auth blocked; release no longer
uses debug signing. Release APK and AAB attempts on2026-10-11 both fail safely
because signing is missing. No current production/R8/smoke PASS claimed, and an
older release APK on disk is not this phase's artifact. HTTPS/permissions/logging/
App Check checks hardened. Draft account cleanup and invite auth guards tested.

Current-phase real backend A/B replay **PASS1/1,5:52,exit0**, dated2026-10-11:
all core gates including126 pagination fixtures, committed-response-loss retry,
block/unblock and revoke with old full-size URL404. Emulator System UI ANR required
selecting Wait under host memory pressure; documented as an environment intervention,
not an unattended/performance PASS. Runtime credentials and reverse5002 removed.
Final ordinary debug APK build/install/launch PASS; Welcome/Sign in screenshots
visually verified, APK SHA/signature recorded. Packagecom.inkstamp.app, min26/target36;
Android Debug signing, not a production artifact. Unused transitive microphone,
storage, notifications, biometric and ad permissions removed and verified in merged
APK. Camera stress rerun after removals PASS, no System UI intervention in that run.
Private runtime credentials absent; normal backend5001/gateway8787 kept for demo.
README startup commands now explicitly configure debug DEV; no silent demo fallback.
**GOOGLE AUTH E2E: DEFERRED. PRODUCTION RELEASE: NOT READY.** Physical-device,
interrupted-upload/process-kill, full performance/accessibility and real App Links
verification remain listed, not assumed PASS.
