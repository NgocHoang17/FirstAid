# FirstAid

FirstAid hỗ trợ giáo dục và phổ biến kiến thức sơ cứu ngoại viện qua bài học trực quan, tra cứu ngoại tuyến và hỏi đáp RAG có nguồn. Mobile không cần tài khoản; web quản trị sử dụng một role ADMIN.

## Tài liệu

- [Bàn giao backend](docs/BACKEND_HANDOFF.md) ghi việc theo thứ tự thực hiện và tiêu chí nghiệm thu.
- [Đặc tả hệ thống](docs/baseline-v2/01_SYSTEM_SPEC.md), [hợp đồng API](docs/baseline-v2/06_SHARED_CONTRACTS.md) và [hướng dẫn đọc](docs/baseline-v2/README.md) dùng chung cho cả nhóm.
- [Thiết kế dữ liệu](docs/DATABASE_DESIGN.md) và [dữ liệu tham chiếu](docs/DATA_REFERENCE.md) mô tả cấu trúc, phạm vi nội dung và nguồn.
- [Kiến trúc](docs/ARCHITECTURE.md) và [quy tắc đóng góp](CONTRIBUTING.md) dùng khi phát triển.

## Công nghệ

| Thành phần | Công nghệ | Trách nhiệm |
| --- | --- | --- |
| Mobile | Flutter, BLoC, SQLite | Hướng dẫn offline, tìm kiếm, hỏi đáp |
| API | Node.js, Express, PostgreSQL | Nội dung, Admin auth, snapshot và gateway AI |
| Web Admin | React + TypeScript | Quản lý bài, danh mục, hình và nguồn |
| RAG | FastAPI, BM25, Gemini tùy cấu hình | Truy xuất bài có nguồn, giữ đối tượng và citation |

## Phạm vi

FirstAid hỗ trợ giáo dục và phổ biến kiến thức sơ cứu ngoại viện qua bài học trực quan, nội dung ngoại tuyến và hỏi đáp RAG bằng văn bản/hình ảnh. Đối tượng gồm người lớn và trẻ em, không bao gồm nhũ nhi. Không có quiz, danh bạ, bản đồ hoặc định vị. Không thay thế nhân viên y tế và dịch vụ cấp cứu. Đặc tả ở [01](docs/baseline-v2/01_SYSTEM_SPEC.md), nghiệm thu ở [08](docs/baseline-v2/08_ACCEPTANCE_AND_PLAN.md).

## Phát triển local

### Chạy ứng dụng với dữ liệu thật trên Windows

Cần Python 3.11+, Node.js theo `admin/package.json` và Flutter. Backend dùng Node.js. Launcher ưu tiên PostgreSQL cấu hình trong `backend/.env`; nếu chưa có file này, dùng PostgreSQL local riêng (ưu tiên binary đã cài, nếu thiếu mới tải portable). Có thể chỉ định Python bằng `FIRSTAID_PYTHON` hoặc PostgreSQL binary bằng `FIRSTAID_PG_BIN`.

Tại thư mục gốc, chạy:

```powershell
powershell -ExecutionPolicy Bypass -File tools/start-local.ps1
```

Lệnh này khởi động backend Node.js, chatbot và web Admin, chạy migration và nạp bộ dữ liệu đã biên soạn khi chưa có bài, rồi kiểm tra API. Với `backend/.env`, PostgreSQL phải đang chạy. Launcher giữ bài đã chỉnh và dùng cùng token cho backend/AI; không ghi đè `.env`. Mở **http://127.0.0.1:5173** để quản trị. Thông tin đăng nhập và log lưu trong `.local/`, được Git bỏ qua.

Thêm `-SkipAi` khi chỉ cần backend/Admin, hoặc `-PortableDatabase` để dùng database riêng thay cho `backend/.env`. AI mặc định trích xuất nội dung có nguồn, không cần khóa Gemini. Đọc [cấu hình Gemini](ai/GROUNDED_GENERATION.md) khi cần chế độ sinh.

Trong terminal khác, chạy mobile trên Android emulator:

```powershell
cd mobile
flutter pub get
flutter devices
flutter run -d <ANDROID_DEVICE_ID>
```

Debug mặc định kết nối `http://10.0.2.2:8080/api/v1`. Điện thoại thật cần `--dart-define=API_BASE_URL` trỏ tới máy chủ truy cập được. Bản release cấu hình API HTTPS theo môi trường.

Dừng các dịch vụ local khi cần:

```powershell
powershell -ExecutionPolicy Bypass -File tools/start-local.ps1 -Stop
```

Database được giữ lại để lần sau dùng tiếp. Lệnh dừng chỉ dừng tiến trình do launcher quản lý; PostgreSQL đang dùng qua `.env` tiếp tục chạy. Chạy lại lệnh khởi động giữ dữ liệu đã chỉnh bằng Admin.

### Luồng dữ liệu

1. `mobile/assets/content/reference_library.json` chứa 24 bài, 18 nhóm và 17 nguồn đã biên soạn.
2. `tools/build_app_data.py` tạo `mobile/assets/content/offline_snapshot.json`. App cài mới đọc được bài và hình đi kèm, không cần mạng.
3. Lệnh khởi động nạp dữ liệu nội dung vào PostgreSQL khi chưa có bài. Các chỉnh sửa từ Admin được giữ lại.
4. Backend Node.js xuất snapshot. Mobile cập nhật qua **Cài đặt → Kiểm tra cập nhật**, kiểm và ghi SQLite nguyên tử.
5. Chatbot dùng corpus từ snapshot public của backend. Gateway kiểm nguồn và revision trước khi trả phản hồi.

Khi chạy bằng launcher, AI kiểm ETag của snapshot mỗi 30 giây và cập nhật corpus. Sau khi sửa dữ liệu biên soạn, chạy `python tools/build_app_data.py`. Dùng `--check` để đối chiếu bản đóng gói.

### Phối hợp backend và AI

Đọc [bàn giao backend](docs/BACKEND_HANDOFF.md) khi nối gateway ảnh, snapshot v2 và migration. Đọc [cấu hình Gemini](ai/GROUNDED_GENERATION.md) khi kiểm model thật.
