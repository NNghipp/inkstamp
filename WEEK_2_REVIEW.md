# Inkstamp - Week 2 Review (Draft)

## Trạng thái

**Week 2 đang ở trạng thái gần hoàn tất về mặt code và kiểm tra local, nhưng chưa nên đánh dấu hoàn tất production.**

Ngày cập nhật: **7 tháng 9 năm 2026**.

Trong phiên làm việc này, nền tảng Firebase Development đã được nối với project inkstamp-dev, luồng xác thực/session đã được tích hợp vào app, Cloudinary được chọn làm hệ thống lưu trữ media, và media gateway đã chạy được ở local.

## Các hạng mục đã hoàn thành

- Đã xác thực Firebase CLI bằng tài khoản Firebase hiện có.
- Đã kết nối project Firebase inkstamp-dev.
- Đã đăng ký Firebase Android app với package com.inkstamp.app.
- Đã đăng ký Firebase iOS app với bundle ID com.inkstamp.app.
- Đã sinh cấu hình FlutterFire cho Android và iOS.
- Đã nối Firebase.initializeApp() với DefaultFirebaseOptions.currentPlatform.
- Đã bật cấu hình Google Services trong Android Gradle.
- Đã thêm session-driven routing và khôi phục session Firebase khi app khởi động.
- Đã cập nhật Google Sign-In theo API google_sign_in 7.2.0.
- Đã giữ demo mode khi Firebase chưa sẵn sàng để app vẫn chạy local.
- Đã chuyển media model từ Firebase Storage draft path sang Cloudinary public ID.
- Đã thêm repository upload stamp và thumbnail lên Cloudinary thông qua signed upload gateway.
- Đã thêm signed delivery URL cho ảnh private.
- Đã thêm kiểm tra Firebase ID token trong media gateway.
- Đã thêm kiểm tra Firebase App Check khi được bật.
- Đã thêm rate limiting theo IP và user ở mức local prototype.
- Đã thêm route kiểm tra GET /health cho media gateway.
- Đã cập nhật publish validation để kiểm tra Cloudinary public ID thuộc sender và đúng namespace.

## Kiểm tra đã chạy

| Kiểm tra | Kết quả |
|---|---|
| flutter analyze | Pass, không còn issue |
| flutter test | Pass, 13 tests |
| Android debug APK | Build thành công |
| Functions ESLint | Pass |
| Functions tests | Pass, 8 tests |
| Functions TypeScript build | Pass |
| Media gateway tests | Pass, 13 tests |
| Wrangler TypeScript/build check | Pass |
| Wrangler deploy dry-run | Pass |
| Media gateway GET /health local | 200 OK |
| Media gateway không có Auth token | 401 Unauthorized, đúng kỳ vọng |
| git diff --check | Pass, còn cảnh báo CRLF hiện hữu |

APK debug được tạo tại: apps/mobile/build/app/outputs/flutter-apk/app-debug.apk

## Lỗi đã phát hiện và sửa

- Sửa API Google Sign-In cũ không tương thích với phiên bản 7.2.0.
- Sửa provider Firebase initialization không tương thích Riverpod 3.
- Sửa test app thiếu ProviderScope.
- Sửa tham chiếu màu không tồn tại AppColors.stamp.
- Sửa import ordering để Flutter analyzer không còn issue.
- Sửa media gateway để có route health kiểm tra local rõ ràng.
- Cập nhật test route không tồn tại sau khi thêm /health.

## Giới hạn và việc chưa hoàn tất

- Chưa test upload Cloudinary thật từ app vì chưa có Firebase ID token của user đăng nhập thật trong phiên local.
- Chưa xác nhận Google Sign-In trên thiết bị Android thật.
- Chưa xác nhận Apple Sign-In trên iOS thật.
- Chưa build/test iOS vì môi trường hiện tại là Windows và cần macOS/Xcode.
- Rate limiter hiện là InMemoryRateLimiter, chưa phù hợp production multi-instance. Cần thay bằng Durable Object hoặc KV.
- Cloudinary API secret đã từng được gửi trong cuộc trò chuyện; cần regenerate secret trước khi sử dụng tiếp.
- firebase_options.dart, google-services.json và Cloudinary .dev.vars đang được gitignore theo chủ đích.
- Chưa deploy Worker production. Wrangler mới chỉ chạy local và dry-run.
- Chưa chạy Firebase Emulator integration tests cho Auth/Firestore/Functions.

## Đánh giá milestone

| Phạm vi | Trạng thái |
|---|---|
| Firebase project và app registration | Hoàn tất |
| Firebase Flutter configuration | Hoàn tất local |
| Session và onboarding routing | Hoàn tất ở mức code/test local |
| Cloudinary upload gateway | Hoàn tất ở mức code/local test |
| Cloudinary upload thật | Chưa xác nhận |
| Google/Apple Sign-In thiết bị thật | Chưa xác nhận |
| Production rate limiting | Chưa hoàn tất |
| iOS build/device test | Chưa thực hiện |

## Điều kiện để đóng Week 2

1. Regenerate Cloudinary API secret và cập nhật workers/media-gateway/.dev.vars.
2. Đăng nhập app bằng Firebase thật trên Android để lấy ID token runtime.
3. Test upload stamp và thumbnail thật lên Cloudinary.
4. Test publish stamp và lưu public ID vào Firestore.
5. Test Google Sign-In trên Android thật.
6. Test Apple Sign-In trên iOS/macOS.
7. Thay in-memory rate limiter bằng cơ chế phân tán.
8. Chạy Firebase Emulator integration tests.
9. Review thay đổi, commit vào nhánh Week 2 và tạo Pull Request.

## Quyết định hiện tại

**Chưa commit và chưa push.** File này là draft để review trước khi tạo commit GitHub.
