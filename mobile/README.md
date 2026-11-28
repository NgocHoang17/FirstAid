# FirstAid mobile

Flutter, BLoC và SQLite. Ba tab Trang chủ, Kiến thức, Hỏi đáp. Đọc [PRD](../docs/PRD.md) và [Frontend Guide](../docs/baseline-v2/03_FRONTEND_GUIDE.md).

## Tóm tắt kết nối mobile

Hướng dẫn này dùng khi backend đã kết nối và query PostgreSQL thành công. Bước tiếp theo là kiểm tra API HTTP, chạy mobile và đồng bộ nội dung. Kết quả query database chưa xác nhận kết nối từ thiết bị tới backend.

Luồng dữ liệu: **PostgreSQL → backend Node.js `/api/v1` → mobile → SQLite trên thiết bị**. Mobile gọi API; thông tin đăng nhập PostgreSQL nằm ở backend.

| Phần sử dụng | Cách hoạt động |
| --- | --- |
| Trang chủ / Kiến thức | Đọc nội dung SQLite đã tải; lần đầu dùng nội dung đi kèm app. Tìm kiếm và đọc bài dùng dữ liệu trên máy. |
| Cài đặt và dữ liệu | Nút **Kiểm tra cập nhật** tải snapshot từ backend, kiểm tra rồi lưu SQLite. Đồng bộ thành công mới thay bộ dữ liệu hiện tại. |
| Hỏi đáp | Gọi backend để chuyển câu hỏi tới FastAPI/AI. Cần mạng và dịch vụ AI hoạt động. |

**Mở app thấy bài viết chưa chứng minh đã nối backend**, vì app có sẵn nội dung offline. App hiện cập nhật theo thao tác của người dùng trong Cài đặt.

## Chạy nhanh với backend đã có

Yêu cầu Flutter >=3.47.0, Dart >=3.13.0 và thiết bị Android/emulator. Build iOS cần Xcode >=26.1.1. Giữ backend đang chạy; chỉ cần FastAPI khi kiểm tra Hỏi đáp. Hướng dẫn dịch vụ: [backend](../backend/README.md), [AI](../ai/README.md).

### 1. Kiểm tra API từ máy chạy backend

Chạy trong PowerShell, đổi cổng hoặc vùng nếu môi trường đang dùng giá trị khác:

```powershell
$api = 'http://127.0.0.1:8080/api/v1'
Invoke-RestMethod "$api/categories"
$snapshot = Invoke-RestMethod "$api/offline-snapshot?region_code=VN-DN"
$snapshot.data | Select-Object schema_version, data_version, region_code
$snapshot.data.articles.Count
```

Mong đợi HTTP 200, `schema_version = 1`, `region_code = VN-DN`, `data_version` có giá trị. Số bài phụ thuộc nội dung đã xuất bản trong database; đủ 24 bài khi dùng bộ seed đầy đủ. Bài nháp chưa xuất hiện trong snapshot public. Endpoint snapshot có thể trả 304 khi client gửi ETag của phiên bản hiện tại.

### 2. Chạy mobile trên Android emulator

Từ thư mục gốc dự án:

```powershell
cd mobile
flutter pub get
flutter devices
flutter run -d <ANDROID_DEVICE_ID> --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1 --dart-define=PILOT_REGION_CODE=VN-DN
```

Thay `<ANDROID_DEVICE_ID>` bằng ID Android từ `flutter devices`. Với Android Emulator của Android Studio, `10.0.2.2` trỏ về máy chạy emulator; `127.0.0.1` trong thiết bị trỏ tới chính thiết bị.

### 3. Nếu dùng điện thoại Android thật qua Wi-Fi

Máy tính và điện thoại cần truy cập được nhau trên mạng LAN. Dùng `ipconfig` để tìm IPv4 LAN của máy chạy backend; ví dụ địa chỉ máy là `192.168.1.10` thì chạy:

```powershell
flutter run -d <ANDROID_DEVICE_ID> --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1 --dart-define=PILOT_REGION_CODE=VN-DN
```

Thay IP ví dụ bằng IP thực tế. Backend cần lắng nghe trên địa chỉ LAN hoặc `0.0.0.0` và firewall cho phép cổng API trên mạng riêng. Có thể mở `http://<IP_MAY_TINH>:8080/api/v1/categories` bằng trình duyệt điện thoại để kiểm tra đường mạng trước.

### 4. Xác nhận dữ liệu backend đã vào app

1. Mở app → **Cài đặt và dữ liệu** từ biểu tượng Cài đặt.
2. Nhấn **Kiểm tra cập nhật**; lần tải đầu mong đợi **Cập nhật thành công**.
3. Kiểm tra **Phiên bản** khớp `data_version` từ API và **Ngày tải** đã thay cho “Đi kèm ứng dụng”. Số bài khớp snapshot public.
4. Nhấn lại khi backend chưa thay đổi: mong đợi **Đã là bản mới nhất**.
5. Tắt mạng, đóng rồi mở app: nội dung đã lưu vẫn đọc được. Ảnh bước tải từ server vẫn có thể cần mạng.

Muốn kiểm tra thay đổi từ Admin: sửa và xuất bản một bài, kiểm tra bài đã có trong snapshot API, rồi nhấn cập nhật trên mobile. Sửa bài public đưa bài về nháp; cần xuất bản lại để mobile nhận được.

## API và cấu hình mobile

Các đường dẫn dưới đây nối vào `API_BASE_URL`, vốn đã bao gồm `/api/v1`:

| API | Mobile dùng để |
| --- | --- |
| `GET /offline-snapshot?region_code=VN-DN` | Tải dữ liệu public v1. Gửi `If-None-Match` sau lần đồng bộ đầu; 304 nghĩa là giữ bộ hiện tại. |
| `GET /offline-snapshot?schema_version=2` | Tải snapshot v2 khi bật `FIRSTAID_SNAPSHOT_V2`. |
| `POST /assistant/query` | Gửi câu hỏi bằng JSON. |
| `POST /assistant/query-with-image` | Gửi multipart gồm `request` là JSON và `image` là ảnh. |

Public API mobile không yêu cầu đăng nhập Admin hoặc CSRF. `/categories` ở bước kiểm tra chỉ dùng xác minh API; luồng đồng bộ của app lấy snapshot.

| Biến `--dart-define` | Giá trị mặc định / cách dùng |
| --- | --- |
| `API_BASE_URL` | Debug: `http://10.0.2.2:8080/api/v1`. Release cần truyền URL HTTPS của backend. |
| `PILOT_REGION_CODE` | `VN-DN`; dùng snapshot v1 phải khớp `PUBLIC_REGION` ở backend. |
| `FIRSTAID_SNAPSHOT_V2` | Mặc định `false`; thêm `--dart-define=FIRSTAID_SNAPSHOT_V2=true` để yêu cầu schema 2. |
| `AI_CHAT_TIMEOUT_SECONDS` | `40`; giới hạn chờ câu trả lời văn bản ở mobile. |

Đổi `--dart-define` cần dừng và chạy lại app bằng lệnh mới. Backend phải trả `app_config.locale = vi-VN` và `app_config.emergency_number = 115` để mobile chấp nhận snapshot.

## Xử lý nhanh khi chưa nhận dữ liệu

| Hiện tượng | Kiểm tra |
| --- | --- |
| API chạy trên máy tính nhưng điện thoại không truy cập được | Địa chỉ emulator/LAN, cổng, `HOST` backend và firewall. Giữ phần `/api/v1` trong URL. |
| Vẫn thấy nội dung cũ | Vào Cài đặt nhấn cập nhật; kiểm tra Ngày tải/Phiên bản. Xác nhận bài đã PUBLISHED và xuất hiện trong snapshot API. |
| Snapshot v1 trả 400 | `region_code` của request và `PILOT_REGION_CODE` phải khớp `PUBLIC_REGION`. |
| Snapshot trả 503 | Kiểm tra log backend, trạng thái database và cấu hình `PUBLIC_REGION`, `EMERGENCY_NUMBER`. |
| App báo “Bản dữ liệu chưa tương thích” | Kiểm tra schema 1/2, vùng của v1, locale, số khẩn cấp và metadata snapshot. Dữ liệu đang lưu vẫn được giữ. |
| Đọc bài được nhưng Hỏi đáp chưa hoạt động | Kiểm tra FastAPI, `AI_BASE_URL`, token nội bộ giữa backend/AI và corpus. Kết nối PostgreSQL thành công chưa xác nhận AI hoạt động. |

## Nội dung

24 bài, 18 nhóm, 17 nguồn và hình nhắc nhớ đi kèm ứng dụng. Đọc đầy đủ và theo bước dùng cùng Article. Không yêu cầu tài khoản. Cập nhật qua Cài đặt, giữ dữ liệu khi lỗi.

Không có quiz, danh bạ, bản đồ, GPS hoặc quyền vị trí. Trong Hỏi đáp, người học có thể chọn, xem trước, bỏ ảnh JPEG/PNG rồi gửi kèm câu hỏi. Luồng gửi ảnh cần gateway hỗ trợ multipart và Gemini phía server. Không lưu ảnh hoặc lịch sử chat mặc định.

Mobile đọc được public snapshot v1 và v2. Chỉ thêm `--dart-define=FIRSTAID_SNAPSHOT_V2=true` khi gateway đã cung cấp schema 2. Payload danh bạ không có màn hình sử dụng. Snapshot giáo dục schema 2 được quy định trong [06](../docs/baseline-v2/06_SHARED_CONTRACTS.md).

## Kiểm tra

Ảnh hướng dẫn do Admin tải lên có ba bố cục: xếp dọc, lưới và vuốt ngang. Ảnh xuất hiện sau chữ trong khối của bước; có chú thích và mô tả đọc màn hình. Lưới chuyển thành một cột khi chữ lớn. Ảnh tải từ server cần kết nối mạng; khi không tải được, phần hướng dẫn chữ vẫn đọc được. Hình bundled tiếp tục phục vụ các bước không có bộ ảnh upload.

```powershell
flutter pub get
flutter analyze
flutter test
```

Chạy các lệnh từ thư mục `mobile`. `flutter pub get` tạo `.dart_tool/package_config.json` để Dart/IDE nhận các import `package:mobile`, `flutter_test` và `integration_test`. Nếu các import còn bị đánh dấu đỏ, kiểm tra SDK của IDE trùng với `flutter --version` trong terminal và Dart đáp ứng `sdk` trong `pubspec.yaml`, rồi khởi động lại Dart Analysis Server.

`flutter test` chạy bộ unit/widget trong `test/`, không cần backend. Ca `publication_sync_test.dart` chỉ chạy khi có biến `FIRSTAID_TEST_SNAPSHOTS` trỏ đến fixture xuất từ kiểm thử xuất bản backend; thiếu fixture thì ca này được bỏ qua có chủ đích.

### Integration test trên Android

`integration_test/real_data_test.dart` cần thiết bị Android/emulator, backend Node.js + PostgreSQL đã seed bộ 24 bài và FastAPI có corpus hoạt động. Đây là kiểm thử trực tiếp dịch vụ thật, không dùng API giả lập. Mỗi lần chạy tạo database SQLite test riêng và xóa khi kết thúc.

```powershell
flutter devices
flutter test integration_test/real_data_test.dart -d <ANDROID_DEVICE_ID> --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

Thay `<ANDROID_DEVICE_ID>` bằng ID từ `flutter devices`. `10.0.2.2` dành cho Android emulator; điện thoại thật cần địa chỉ LAN của máy chạy backend. V1 cần `PUBLIC_REGION` của backend khớp `PILOT_REGION_CODE` (mặc định `VN-DN`). Không để Flutter tự chọn Windows cho bài kiểm thử Android: Windows cần Visual Studio C++ toolchain và bộ lưu SQLite hiện tại của app dành cho nền tảng mobile.

Lưu ảnh xem trước và bộ kiểm giao diện cá nhân trong `.local/` ở thư mục gốc. Đặt ngoài `mobile/test/` để `flutter test` chỉ chạy bộ kiểm của dự án. Không đưa PDF gốc, ảnh hội thoại, secrets hoặc dữ liệu runtime vào Git.
