# FirstAid mobile

Flutter, BLoC và SQLite. Ba tab Trang chủ, Kiến thức, Hỏi đáp. Đọc [PRD](../docs/PRD.md) và [Frontend Guide](../docs/baseline-v2/03_FRONTEND_GUIDE.md).

## Chạy local

<<<<<<< HEAD
Khởi động backend Node.js theo [README backend](../backend/README.md) và FastAPI theo [README AI](../ai/README.md), sau đó:
=======
Khởi động dịch vụ theo [README gốc](../README.md#phát-triển-local), sau đó:
>>>>>>> origin/master

```powershell
flutter pub get
flutter run
```

Android emulator mặc định dùng `http://10.0.2.2:8080/api/v1`. Điện thoại thật dùng `--dart-define=API_BASE_URL` với địa chỉ máy chủ truy cập được. Release dùng HTTPS.

## Nội dung

24 bài, 18 nhóm, 17 nguồn và hình nhắc nhớ đi kèm ứng dụng. Đọc đầy đủ và theo bước dùng cùng Article. Không yêu cầu tài khoản. Cập nhật qua Cài đặt, giữ dữ liệu khi lỗi.

Không có quiz, danh bạ, bản đồ, GPS hoặc quyền vị trí. Trong Hỏi đáp, người học có thể chọn, xem trước, bỏ ảnh JPEG/PNG rồi gửi kèm câu hỏi. Luồng gửi ảnh cần gateway hỗ trợ multipart và Gemini phía server. Không lưu ảnh hoặc lịch sử chat mặc định.

Mobile đọc được public snapshot v1 và v2. Chỉ thêm `--dart-define=FIRSTAID_SNAPSHOT_V2=true` khi gateway đã cung cấp schema 2. Payload danh bạ không có màn hình sử dụng. Snapshot giáo dục schema 2 được quy định trong [06](../docs/baseline-v2/06_SHARED_CONTRACTS.md).

## Kiểm tra

Ảnh hướng dẫn do Admin tải lên có ba bố cục: xếp dọc, lưới và vuốt ngang. Ảnh xuất hiện sau chữ trong khối của bước; có chú thích và mô tả đọc màn hình. Lưới chuyển thành một cột khi chữ lớn. Ảnh tải từ server cần kết nối mạng; khi không tải được, phần hướng dẫn chữ vẫn đọc được. Hình bundled tiếp tục phục vụ các bước không có bộ ảnh upload.

```powershell
<<<<<<< HEAD
flutter pub get
=======
>>>>>>> origin/master
flutter analyze
flutter test
```

<<<<<<< HEAD
Chạy các lệnh từ thư mục `mobile`. `flutter pub get` tạo `.dart_tool/package_config.json` để Dart/IDE nhận các import `package:mobile`, `flutter_test` và `integration_test`. Nếu các import còn bị đánh dấu đỏ, kiểm tra SDK của IDE trùng với `flutter --version` trong terminal và Dart đáp ứng `sdk` trong `pubspec.yaml`, rồi khởi động lại Dart Analysis Server.

`flutter test` chạy bộ unit/widget trong `test/`, không cần backend. Ca `publication_sync_test.dart` chỉ chạy khi có biến `FIRSTAID_TEST_SNAPSHOTS` trỏ đến fixture xuất từ kiểm thử xuất bản backend; thiếu fixture thì ca này được bỏ qua có chủ đích.

### Integration test trên Android

`integration_test/real_data_test.dart` cần thiết bị Android/emulator, backend Node.js + PostgreSQL đã seed bộ 24 bài và FastAPI có corpus hoạt động. Đây là kiểm thử trực tiếp dịch vụ thật, không dùng API giả lập. Mỗi lần chạy tạo database SQLite test riêng và xóa khi kết thúc.

```powershell
flutter devices
flutter test integration_test/real_data_test.dart -d <ANDROID_DEVICE_ID> --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

Thay `<ANDROID_DEVICE_ID>` bằng ID từ `flutter devices`. `10.0.2.2` dành cho Android emulator; điện thoại thật cần địa chỉ LAN của máy chạy backend. V1 cần `PUBLIC_REGION` của backend khớp `PILOT_REGION_CODE` (mặc định `VN-DN`). Không để Flutter tự chọn Windows cho bài kiểm thử Android: Windows cần Visual Studio C++ toolchain và bộ lưu SQLite hiện tại của app dành cho nền tảng mobile.

=======
>>>>>>> origin/master
Lưu ảnh xem trước và bộ kiểm giao diện cá nhân trong `.local/` ở thư mục gốc. Đặt ngoài `mobile/test/` để `flutter test` chỉ chạy bộ kiểm của dự án. Không đưa PDF gốc, ảnh hội thoại, secrets hoặc dữ liệu runtime vào Git.
