# Test Cases Week 2-3

Ngày chạy gần nhất: **2026-09-09**. `T1/T2/T3` là ba lần/kênh kiểm tra; dấu `-`
nghĩa là chưa thể chạy do thiếu thiết bị hoặc cấu hình bên ngoài.

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
| Auth / Session | Đóng/mở app | Firebase auth stream + profile | Khôi phục đúng stage | Pass unit | Pass router logic | - | WORK IN PROGRESS | Cần Android device test |
| Auth / Sign-out | Sign-out | User đang đăng nhập | Router về welcome/sign-in | Pass code | Pass unit hiện hữu | - | WORK IN PROGRESS | Cần Android device test |
| Username / Validation | Hợp lệ, sai, hoa/thường | `New.User`, ngắn, ký tự cấm | Trim/lowercase, 3-20, chỉ `[a-z0-9._]` | Pass | Pass | Pass | PASS | Functions schema tests |
| Username / Race | Hai user reserve cùng tên | Hai transaction đồng thời | Chỉ một transaction thành công | Pass code review | - | - | WORK IN PROGRESS | Cần Functions emulator callable test |
| Firestore Rules | Chặn ghi trực tiếp | Client ghi username/profile | Bị từ chối | Pass emulator | Pass | - | PASS | Rules test 2/2 |
| Onboarding / Persist | Permissions và widget intro | Restart từng stage | Mở đúng profile/permissions/widget/app | Pass controller | Pass router | - | WORK IN PROGRESS | Cần Android restart test |
| Upload / Validation | File thiếu/sai MIME/quá lớn | Missing, PNG, >5 MB | Reject trước upload | Pass | Pass | Pass | PASS | Flutter repository tests |
| Upload / Signed request | Stamp/thumbnail | JPEG + ID/App Check token | Public ID đúng tham số Worker đã ký | Pass mock | Pass Worker | - | WORK IN PROGRESS | Cần Cloudinary thật |
| Upload / Timeout | Gateway/Cloudinary chậm | Timeout | UI thoát loading, báo retry | Pass | Pass | - | PASS | Flutter timeout test |
| Upload / Cleanup | Thumbnail/publish lỗi | Stamp đã upload | Xóa asset đã upload thuộc UID | Pass client | Pass Worker auth | - | WORK IN PROGRESS | Cần Cloudinary thật |
| Publish / Idempotency | Retry cùng asset | Gọi lại publish | Cùng request ID, không tạo stamp trùng | Pass code/unit | Pass transaction logic | - | WORK IN PROGRESS | Cần Functions emulator callable test |
| Delivery / Authorization | Owner/recipient/người lạ | Xin URL bằng public ID | Chỉ owner/recipient hợp lệ nhận URL | Pass Worker | Pass Rules | - | WORK IN PROGRESS | Cần test Firebase token thật |
| Delivery / Cache | URL còn trong cache | Đọc cùng asset hai lần | Chỉ gọi gateway một lần | Pass unit | Pass | - | PASS | Flutter delivery repository test |
| Android / E2E | Toàn luồng thật | Sign-in đến sign-out | Upload/publish/xem ảnh thành công | Config pass | APK pass | - | WORK IN PROGRESS | `adb.exe` có sẵn nhưng chưa có thiết bị kết nối |
| Android / Offline | Mất mạng/upload/resume | Ngắt mạng giữa upload | Không kẹt loading, retry/cleanup đúng | Pass timeout unit | - | - | WORK IN PROGRESS | Cần Android device test |
| iOS / Apple Sign-In | Apple device verification | iPhone thật | Sign-in và session đúng | - | - | - | WORK IN PROGRESS | Cần macOS/Xcode; ngoài điều kiện đóng |
| Security / Secret scan | Không commit secrets | Git tracked files/diff | Không có `.dev.vars`, token hoặc secret | Pass ignore | Pass scan | Pass diff | PASS | `.gitignore`, `git ls-files`, secret scan; rotate được miễn cho dev |
| Production / Rate limit | Limiter phân tán | Worker public nhiều isolate | Durable Object limiter | - | - | - | WORK IN PROGRESS | Blocker trước deploy, ngoài local milestone |
