# FirstAid

FirstAid hỗ trợ giáo dục và phổ biến kiến thức sơ cứu ngoại viện qua bài học trực quan, tra cứu ngoại tuyến và hỏi đáp RAG có nguồn. Mobile không cần tài khoản; web quản trị sử dụng một role ADMIN.

## Tài liệu

Đây là bộ đặc tả sản phẩm và hướng dẫn phát triển dùng chung. Tài liệu không ghi tiến độ, danh sách tính năng đã làm hoặc kiểm kê mã nguồn. Chỉ sửa đặc tả khi có quyết định thay đổi yêu cầu, kiến trúc hoặc contract; tiến độ và kết quả kiểm thử được báo trong task/PR.

Bắt đầu tại [hướng dẫn đọc](docs/baseline-v2/README.md), sau đó đọc [đặc tả hệ thống](docs/baseline-v2/01_SYSTEM_SPEC.md) và [contract chung](docs/baseline-v2/06_SHARED_CONTRACTS.md).

- [Dữ liệu chuẩn tham chiếu](docs/DATA_REFERENCE.md): nội dung theo 18 nhóm, biến thể đối tượng và độ phủ nguồn.
- [PRD](docs/PRD.md): mục tiêu và phạm vi sản phẩm.
- [Kiến trúc](docs/ARCHITECTURE.md): thành phần, trách nhiệm và luồng dữ liệu.
- [Thiết kế cơ sở dữ liệu](docs/DATABASE_DESIGN.md): quan hệ PostgreSQL/SQLite, ràng buộc và SQL tham chiếu.
- [Quy tắc đóng góp](CONTRIBUTING.md).

## Công nghệ

| Thành phần | Công nghệ | Trách nhiệm |
| --- | --- | --- |
| Mobile | Flutter, BLoC, SQLite | Hướng dẫn offline, tìm kiếm, hỏi đáp |
| API | Spring Boot, PostgreSQL | Nội dung, Admin auth, snapshot và gateway AI |
| Web Admin | React + TypeScript | Quản lý bài, danh mục, hình và nguồn |
| RAG | FastAPI, BM25, trả lời trích xuất | Truy xuất bài có nguồn, giữ đối tượng và citation |

## Phạm vi

FirstAid hỗ trợ giáo dục và phổ biến kiến thức sơ cứu ngoại viện qua bài học trực quan, nội dung ngoại tuyến và hỏi đáp RAG bằng văn bản/hình ảnh. Đối tượng gồm người lớn và trẻ em, không bao gồm nhũ nhi. Không có quiz, danh bạ, bản đồ hoặc định vị. Không thay thế nhân viên y tế và dịch vụ cấp cứu. Đặc tả ở [01](docs/baseline-v2/01_SYSTEM_SPEC.md), nghiệm thu ở [08](docs/baseline-v2/08_ACCEPTANCE_AND_PLAN.md).

## Phát triển local

### Chạy ứng dụng với dữ liệu thật trên Windows

Cần Python 3.11+, Node.js theo `admin/package.json`, JDK 21 và Flutter. Script tự tìm JDK 21 trong Android Studio nếu `JAVA_HOME` chưa phù hợp. Lần đầu script tải PostgreSQL portable từ EDB vào thư mục công cụ của dự án.

Tại thư mục gốc, chạy:

```powershell
powershell -ExecutionPolicy Bypass -File tools/start-local.ps1
```

Lệnh này khởi động PostgreSQL, Spring, chatbot và web Admin, nạp bộ dữ liệu đã biên soạn, rồi kiểm tra API. Mở **http://127.0.0.1:5173** để quản trị. Tài khoản được tạo riêng trên máy và lưu trong `.local/credentials.json`. Database, mật khẩu và log nằm trong `.local/`, được Git bỏ qua.

Trong terminal khác, chạy mobile trên Android emulator:

```powershell
cd mobile
flutter pub get
flutter run
```

Debug mặc định kết nối `http://10.0.2.2:8080/api/v1`. Điện thoại thật cần `--dart-define=API_BASE_URL` trỏ tới máy chủ truy cập được. Bản release cấu hình API HTTPS theo môi trường.

Dừng các dịch vụ local khi cần:

```powershell
powershell -ExecutionPolicy Bypass -File tools/start-local.ps1 -Stop
```

Database được giữ lại để lần sau dùng tiếp. Chạy lại lệnh khởi động giữ dữ liệu đã chỉnh bằng Admin.

### Luồng dữ liệu

1. `mobile/assets/content/reference_library.json` chứa 24 bài, 18 nhóm và 17 nguồn đã biên soạn.
2. `tools/build_app_data.py` tạo `mobile/assets/content/offline_snapshot.json`. App cài mới đọc được bài và hình đi kèm, không cần mạng.
3. Lệnh khởi động nạp dữ liệu nội dung vào PostgreSQL khi chưa có bài. Các chỉnh sửa từ Admin được giữ lại.
4. Spring xuất snapshot. Mobile cập nhật qua **Cài đặt → Kiểm tra cập nhật**, kiểm và ghi SQLite nguyên tử.
5. Chatbot dùng corpus từ snapshot public của Spring. Gateway kiểm nguồn và revision trước khi trả phản hồi.

Chạy lại lệnh khởi động sau khi xuất bản nội dung để dựng lại corpus. Sau khi sửa nguồn biên soạn, chạy `python tools/build_app_data.py`; dùng `--check` để kiểm artifact.

### Phối hợp backend và AI

Đặc tả giáo dục và hỏi đáp kèm ảnh nằm trong bộ docs. Hỏi đáp kèm ảnh cần triển khai và nghiệm thu bộ xử lý đa phương thức thật theo [05](docs/baseline-v2/05_AI_RAG_GUIDE.md); không coi nhận file là hoàn thành AI.

Backend do thành viên phụ trách chuyển đổi theo [04](docs/baseline-v2/04_BACKEND_GUIDE.md). Bộ chạy local giữ tương thích snapshot v1 cho tới khi client/server cùng hỗ trợ schema 2. Client không dùng dữ liệu danh bạ trong v1. Script không xóa dữ liệu đã có trong PostgreSQL.
