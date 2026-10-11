# Inkstamp - Week 2-3 Review và tiến độ hiện tại

Ngày cập nhật: **11 tháng 9 năm 2026**.

## Kết luận

Week 2-3 đã hoàn thiện phần code, test tự động local và kiểm thử end-to-end trên
Android emulator cho authentication, onboarding, Cloudinary gateway, publish và
Firestore Rules. Milestone **đã đóng** theo quyết định của chủ dự án: Android
emulator là môi trường xác minh hợp lệ, không yêu cầu thiết bị Android thật.
Google provider và Android OAuth client đã được cấu hình. Việc rotate Cloudinary
secret không phải điều kiện đóng đối với development.

## Đã hoàn thành

- Firebase Android app khớp `com.inkstamp.app`; SHA-1 và SHA-256 debug đã đăng ký.
- Google provider đã bật; Android và Web OAuth client đã có trong cấu hình mới.
- Session restore và router đọc profile/onboarding thật từ Firestore.
- Trạng thái permissions/widget intro được lưu bằng callable Function.
- Username được chuẩn hóa và reserve bằng Firestore transaction.
- Authentication, stamp và friend repository không tự rơi về demo khi Firebase
  hoặc network báo lỗi; in-memory chỉ dùng trong demo/test.
- Media gateway kiểm tra Firebase ID token, App Check, config và rate limit.
- Upload dùng authenticated Cloudinary asset, URL gateway lấy từ
  `MEDIA_GATEWAY_BASE_URL`.
- App gửi ID token và App Check token, giới hạn JPEG 5 MB và timeout.
- Upload lỗi một phần được cleanup qua endpoint chỉ cho phép asset thuộc UID.
- Publish dùng request ID xác định theo cặp asset để retry không tạo stamp trùng.
- Stamp/delivery được lưu Firestore; delivery URL chỉ cấp sau kiểm tra quyền.
- App cache delivery URL trong 4 phút và tự xin lại sau khi cache hết hạn.
- In-memory repository chỉ còn dùng khi Firebase không được cấu hình (demo/test).
- Firestore Emulator xác nhận client không thể tự ghi username/profile và không
  thể đọc delivery của user khác.

## Tiến độ hiện tại — Production Friend Graph

- Flutter tự chọn `FirebaseFriendRepository` khi Firebase đã khởi tạo và chỉ
  dùng `InMemoryFriendRepository` trong demo/test.
- Danh sách bạn bè, lời mời đến, Close Friends và người dùng đã block được đọc
  từ Firestore.
- Tìm kiếm username gọi callable Function, chuẩn hóa trim/lowercase và không trả
  về chính tài khoản đang đăng nhập hoặc quan hệ đã bị block.
- Gửi, chấp nhận, từ chối lời mời, hủy kết bạn, Close Friends, block và unblock
  đều gọi backend; UI chỉ cập nhật sau khi thao tác thành công.
- Gửi lại cùng lời mời và accept lại không tạo quan hệ trùng. Hai người gửi lời
  mời đồng thời sẽ hội tụ thành một quan hệ accepted.
- Người bị block không thể gọi `removeFriend` để tự xóa trạng thái block.
- All Friends, Close Friends và Select People đã dùng dữ liệu friend graph.
- Màn hình invite tạo QR thật theo username hiện tại. Deep link
  `https://inkstamp.app/u/:username` mở tìm kiếm đúng người khi app đang chạy
  hoặc sau khi hoàn tất đăng nhập/onboarding.
- Firestore Rules cho phép thành viên đọc quan hệ của mình, từ chối người lạ và
  cấm client ghi trực tiếp friendship/Close Friends.

## Tiến độ hiện tại — Camera và Image Processing Android

- `_CameraPreviewSimulation` đã được thay bằng preview thật từ package `camera`.
- Home và route `/camera` dùng chung `CameraRepository` và controller, không còn
  hai luồng capture xử lý ảnh khác nhau.
- Camera hỗ trợ camera sau/trước, flash, capture, retry và giải phóng/khởi tạo lại
  tài nguyên khi ứng dụng pause/resume.
- Ảnh raw được sửa orientation, center-crop vuông và xử lý trong isolate để không
  chặn UI.
- Mỗi lần capture tạo JPEG chính `1440×1440` và thumbnail `512×512`, tối đa 5 MB.
- EXIF, ICC profile và text metadata bị loại trước khi ghi file; ảnh raw bị xóa
  kể cả khi xử lý thất bại.
- Preview/editor chỉ cho tiếp tục trong chế độ Firebase khi cả ảnh chính và
  thumbnail đã sẵn sàng.
- Retake, publish thành công và capture mới đều cleanup file draft cũ. File draft
  quá 24 giờ được dọn khi ứng dụng khởi động hoặc khi camera được mở.
- Không có gallery import và không có thay đổi iOS trong milestone này.

## Kiểm tra đã chạy

Kết quả chi tiết và bằng chứng nằm trong [testcase.md](testcase.md). Các quality
gate tự động hiện tại đã pass:

- Flutter format/analyze và **40/40 tests**.
- Functions lint/build và **9/9 tests**.
- Firestore Rules Emulator **5/5 tests**.
- Media gateway **14/14 tests**, type check/build và Wrangler dry-run.
- `git diff --check`.
- Android debug APK build thành công.

Chủ dự án xác nhận luồng Week 2–3 trên Android emulator đã chạy thành công;
model/API level của phiên emulator chưa được ghi lại.

## Bug đã sửa

- App Check khởi tạo lỗi từng làm app rơi về demo dù Firebase đã sẵn sàng.
- Session chỉ giữ onboarding trong memory nên restart mở sai màn hình.
- Lỗi đăng nhập bị gom thành một thông báo chung.
- Upload repository từng có thể trả public ID giả trong luồng Firebase.
- Public ID từ Cloudinary chưa được đối chiếu với public ID đã ký.
- Publish retry từng tạo request ID mới.
- Delivery URL từng được ký chỉ từ public ID client gửi, chưa kiểm tra quyền.
- Rate limit từng dùng chung quota upload và delivery, thiếu `Retry-After`.
- Upload/publish thất bại có thể để lại asset rác.
- Friend graph từng chỉ sửa state in-memory dù Firebase đã được cấu hình.
- Nút Add từng chỉ hiện thông báo mà không gửi request lên backend.
- Request lặp lại/cross-request từng trả lỗi thay vì hội tụ idempotent.
- Người bị block từng có thể gọi `removeFriend` để xóa document block.
- QR invite từng là hình placeholder và username/link bị hard-code.
- Màn hình `/camera` từng chỉ hiển thị camera mô phỏng.
- Camera Home từng upload trực tiếp file raw, không tạo thumbnail hoặc xóa metadata.

## Kết quả xác minh milestone

1. Android emulator đã xác minh sign-in, onboarding, upload, publish, delivery,
   offline/resume và sign-out.
2. Upload authenticated thành công trên emulator là bằng chứng tích hợp cho
   Cloudinary signed preset và authenticated asset trong môi trường development.
3. Không yêu cầu kết nối Android thật để đóng milestone.

## Việc hoãn lại

- Toàn bộ Apple Sign-In, iOS implementation và iOS QA chỉ được xem xét sau khi
  ứng dụng Android đã hoàn thiện toàn bộ.
- Trước khi deploy Worker public, thay `InMemoryRateLimiter` bằng Durable Object.

## Việc tiếp theo

1. Chạy E2E friend graph trên Android emulator bằng hai tài khoản:
   search → send request → accept → Close Friends → gửi theo ba audience → remove.
2. Chạy E2E camera trên Android emulator:
   camera → capture → preview → retake → editor → audience → upload/publish.
3. Ghi model emulator, Android API level và bằng chứng hai lần chạy vào
   [testcase.md](testcase.md).
4. Sau khi hai luồng E2E pass, đóng Production Friend Graph và Camera/Image
   Processing rồi chuyển sang Inbox/Calendar integration cho Android.

Cloudinary secret đã xuất hiện ngoài file local. Chủ dự án chấp nhận rủi ro này
cho development; tuyệt đối không tái sử dụng secret đó cho production.

Không có Worker, Functions production hay app store deployment trong milestone này.
