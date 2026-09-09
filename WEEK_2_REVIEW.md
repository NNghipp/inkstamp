# Inkstamp - Week 2-3 Review

Ngày cập nhật: **9 tháng 9 năm 2026**.

## Kết luận

Week 2-3 đã hoàn thiện phần code và test tự động local cho authentication,
onboarding, Cloudinary gateway, publish và Firestore Rules. Milestone **chưa
đóng** vì chưa test trên Android thật. Google provider và Android OAuth client
đã được cấu hình. Việc rotate Cloudinary secret không phải điều kiện đóng theo
quyết định của chủ dự án development.

## Đã hoàn thành

- Firebase Android app khớp `com.inkstamp.app`; SHA-1 và SHA-256 debug đã đăng ký.
- Google provider đã bật; Android và Web OAuth client đã có trong cấu hình mới.
- Session restore và router đọc profile/onboarding thật từ Firestore.
- Trạng thái permissions/widget intro được lưu bằng callable Function.
- Username được chuẩn hóa và reserve bằng Firestore transaction.
- Firebase repository không tự rơi về demo khi đăng nhập/upload lỗi.
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

## Kiểm tra đã chạy

Kết quả chi tiết và bằng chứng nằm trong [testcase.md](testcase.md). Các quality
gate tự động đã pass: Flutter analyze/test, Functions lint/test/build, Firestore
Rules Emulator, Worker test/check và `git diff --check`. Android APK được build
lại trong lần kiểm tra cuối.

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

## Việc còn chặn milestone

1. Xác nhận preset trong Cloudinary Console là signed/authenticated.
2. Kết nối Android thật và bật USB debugging. `adb.exe` đã có trong Android SDK
   nhưng chưa nằm trong `PATH`; hiện `adb devices` chưa thấy thiết bị.
3. Chạy end-to-end trên Android thật: sign-in, onboarding, upload, publish,
   delivery, offline/resume và sign-out.
4. Apple Sign-In/iOS device QA chờ macOS/Xcode.
5. Trước khi deploy Worker public, thay `InMemoryRateLimiter` bằng Durable Object.

Cloudinary secret đã xuất hiện ngoài file local. Chủ dự án chấp nhận rủi ro này
cho development; tuyệt đối không tái sử dụng secret đó cho production.

Không có Worker, Functions production hay app store deployment trong milestone này.
