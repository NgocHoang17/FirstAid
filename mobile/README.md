# FirstAid mobile

Flutter, BLoC và SQLite. Ba tab Trang chủ, Kiến thức, Hỏi đáp. Đọc [PRD](../docs/PRD.md) và [Frontend Guide](../docs/baseline-v2/03_FRONTEND_GUIDE.md).

## Chạy local

Khởi động dịch vụ theo [README gốc](../README.md#phát-triển-local), sau đó:

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
flutter analyze
flutter test
```

Lưu ảnh xem trước và bộ kiểm giao diện cá nhân trong `.local/` ở thư mục gốc. Đặt ngoài `mobile/test/` để `flutter test` chỉ chạy bộ kiểm của dự án. Không đưa PDF gốc, ảnh hội thoại, secrets hoặc dữ liệu runtime vào Git.
