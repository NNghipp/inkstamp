# InkStamp — Dark Tactile Stamp Gallery

## Thiết kế

Nền `#151619`, thanh điều hướng `#1B1C20`, bề mặt `#222328`, chữ chính
`#F4F4F1`, chữ phụ `#A8A8A3`, điểm nhấn ấm `#D8CBB7`. Phông Be Vietnam Pro.
Các điều khiển dùng lớp trắng bán trong suốt; không blur hàng loạt trên ảnh.
Tem RGBA được đặt trực tiếp trên nền tối, không thêm khung giấy trắng.

History dùng ảnh lớn và nhãn tối nhỏ; Profile dùng gallery không đồng đều;
Calendar giữ truy vấn/ngày chọn hiện có và dùng thumbnail; Inbox giữ hàng đơn giản;
Detail giữ ảnh lớn cùng reaction/reply; Preview giữ hủy/gửi và lựa chọn người nhận.
Màn Bạn bè/Audience chỉ thích nghi màu với theme mới, không đổi logic.

## Gallery ổn định

`SliverStampGallery` dùng SliverList dựng lười các hàng canvas, hai vùng tương tác
riêng biệt mỗi hàng, chiều cao dự trù góc xoay và cỡ chữ. Mỗi tem có RepaintBoundary.
Hash code-unit 31-bit với các salt `angle`, `size`, `x`, `y` tạo góc −8°…8°,
tỉ lệ .88…1.12 và độ lệch nhỏ. Không dùng Random hoặc String.hashCode.
Cùng ID giữ góc/kích thước/độ lệch khi rebuild; vị trí tuyệt đối vẫn thay đổi khi
lọc, đổi thứ tự hoặc đổi chiều rộng màn hình.

Gallery/Calendar/Inbox lấy public ID thumbnail 512px; Detail lấy ảnh full 1440px.
Ảnh asset có giới hạn decode; ảnh mạng giữ NetworkImage gốc để cơ chế xóa cache
khi thu hồi quyền truy cập tiếp tục hoạt động. Không sửa gateway hay pipeline.
Chuyển màn hình tiếp tục dùng fade + scale có reduced-motion, không thêm Hero.

## Kiểm thử

Kết quả xác nhận khi bàn giao ngày 15/10/2026. Các bộ test chồng lấn,
không cộng tổng giữa Flutter, DEV và regression.

| Bộ kiểm thử | Kết quả đã xác nhận |
|---|---|
| Flutter toàn bộ (bao gồm 5 golden), mã cuối | 140/140 PASS |
| Analyzer | 0 issues |
| DEV-auth bật cờ DEV | 7/7 PASS |
| DEV sample bật cờ DEV | 9 PASS, 1 skip cho cấu hình đối nghịch |
| Test mới dark gallery | 10: palette/contrast, hash, rebuild, lazy 1000 tem, bounds/text scale, reduced motion, alpha thật, ảnh cũ, cache key, decode asset |
| Functions | 29 PASS; 15 emulator-only skip, đã chạy riêng bên dưới |
| Firestore Rules trên project demo cô lập | 7/7 PASS |
| Pagination trên emulator | 8/8 PASS |
| Gateway | 39/39 PASS |
| TypeScript Functions + Gateway | PASS |
| Real DEV photo-presentation E2E | 1/1 PASS; 5 cặp ảnh full/thumbnail xác nhận PNG alpha và kích thước |

E2E ngày 14/10/2026 sử dụng dữ liệu đã publish của A/B, không tạo thêm ký ức trùng.
Camera native và DEV sample đều tạo Preview mới rồi hủy; ảnh đã publish được tải
qua gateway thật và kiểm tra alpha. Upload/send vẫn được kiểm tra bằng các test
luồng gửi hiện có; lần E2E này không publish thêm dữ liệu mới.

## Golden và kiểm tra ảnh thật

5 baseline thay đổi có chủ ý: `feed.png`, `profile.png`, `calendar.png`,
`preview.png`, `camera.png` trong `apps/mobile/test/goldens/`.
Camera chỉ đổi bề mặt điều hướng; nhãn `#141` trên ô thumbnail trắng được giữ
màu chữ tối cũ để không bị theme tối làm mất tương phản. Không thay shutter,
overlay, zoom, flash, lens hoặc capture controller.
So sánh pixel với HEAD: golden Camera 706×1600 chỉ khác trong vùng
`(0, 1472)–(706, 1600)` của thanh điều hướng; phần trên giống hoàn toàn.
Golden vẫn dùng ảnh JPEG thiết kế cũ để kiểm tra tương thích; alpha thật được
kiểm tra bằng test pixel riêng và ảnh emulator, không giả lập viền tem trong UI.

Ảnh chụp thật (1080×2400), không phải mockup:

- [History](evidence/2026-10-14/dark-gallery/history.png)
- [Profile](evidence/2026-10-14/dark-gallery/profile.png)
- [Calendar](evidence/2026-10-14/dark-gallery/calendar.png)
- [Detail](evidence/2026-10-14/dark-gallery/detail-2.png)
- [Inbox](evidence/2026-10-14/dark-gallery/inbox-b.png)
- [Preview sample](evidence/2026-10-14/dark-gallery/preview-current.png)
- [Preview Camera native](evidence/2026-10-14/dark-gallery/native-camera-preview.png)
- [Camera](evidence/2026-10-14/dark-gallery/camera.png)
- [Detail ảnh vuông cũ](evidence/2026-10-14/dark-gallery/detail-legacy.png)
- [Log E2E đã lọc thông tin nhạy cảm](evidence/2026-10-14/dark-gallery/e2e-safe-output.log)

Đã xem ảnh: cạnh alpha rõ trên nền tối, không có góc trắng/đen hình vuông thêm
vào tem mới, không kéo méo, không chồng tem trong gallery. Nội dung ở mép dưới
History/Profile/Calendar tiếp tục cuộn, không phải lỗi mất dữ liệu.

## Hiệu năng và giới hạn

Test 1.000 ID xác nhận dựng lười và cuộn sang hàng sau, số boundary hiện diện dưới
40 trong viewport kiểm thử. Không có blur/shadow nặng hoặc animation theo từng
frame cuộn. Chưa đo FPS/profile mode trên điện thoại thật: không khẳng định 60 FPS.
Gallery vẫn dùng dữ liệu/phân trang hiện có; không mở rộng số lượng ký ức tải về.
Ảnh vuông cũ vẫn giữ renderer tương thích, bao gồm khung giấy cũ trong Detail.
Avatar/bio mẫu và một số nhãn tiếng Anh có sẵn chưa được thay bằng chức năng mới.

Bộ ảnh E2E được chụp trước các chỉnh cuối: giữ cache key NetworkImage, màu phụ ở
màn Bạn bè, vùng bấm Calendar nhỏ và màu nhãn Camera. Những chỉnh này được kiểm tra
bằng widget/golden; chưa chụp lại toàn bộ emulator sau các chỉnh cuối.
Không bật billing, deploy, thay Rules/backend hoặc push GitHub.

## Phạm vi file

- Theme: `app.dart`, `app_theme.dart`, `gallery_tokens.dart`, `main_shell.dart`.
- Shared: `editorial_ui.dart`, `inkstamp_scaffold.dart`, `inkstamp_button.dart`,
  `user_avatar.dart`, `memory_photo.dart`, mới `spatial_stamp_gallery.dart`.
- Screens: `settings_screen.dart`, `home_screen.dart`, `calendar_screen.dart`,
  `inbox_screen.dart`, `stamp_detail_screen.dart`, `stamp_preview_screen.dart`,
  `audience_picker_screen.dart`; `reaction_bar.dart`; màu nhãn `camera_screen.dart`.
- Tương thích theme Bạn bè: `close_friends_screen.dart`, `friend_requests_screen.dart`,
  `friend_search_screen.dart`, `friends_screen.dart`, `friend_tile.dart`.
- Tests: mới `dark_gallery_test.dart`; `memory_interactions_test.dart`,
  `home_screen_test.dart`, `inbox_calendar_test.dart`, `post_capture_screen_test.dart`,
  `visual_ui_test.dart` và 5 PNG golden.
- Integration: `camera_lifecycle_stress_test.dart` chỉ đổi theme harness;
  `photo_presentation_test.dart` thêm kiểm tra/chụp native Camera;
  `functions/scripts/run-backend-e2e.mjs` thêm cờ `--dark-gallery` và thư mục evidence.
- Tài liệu này và thư mục evidence. README, workbook, docs/readme và các ảnh cá nhân
  chưa track đã có ngoài phạm vi thay đổi giao diện; được giữ nguyên.

Wrangler skill chỉ dùng để chạy gateway local theo
[tài liệu Wrangler](https://developers.cloudflare.com/workers/wrangler/commands/),
không chỉnh cấu hình hoặc triển khai Cloudflare.
