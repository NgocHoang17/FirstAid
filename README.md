# FirstAid

FirstAid hỗ trợ tra cứu sơ cứu với khoảng 18 nhóm tình huống, hướng dẫn cố định đọc ngoại tuyến, chatbot RAG văn bản có nguồn và danh bạ cơ sở y tế. Mobile không cần tài khoản; web quản trị sử dụng một role ADMIN.

## Tài liệu

Đây là bộ đặc tả sản phẩm và hướng dẫn phát triển dùng chung. Tài liệu không ghi tiến độ, danh sách tính năng đã làm hoặc kiểm kê mã nguồn. Chỉ sửa đặc tả khi có quyết định thay đổi yêu cầu, kiến trúc hoặc contract; tiến độ và kết quả kiểm thử được báo trong task/PR.

Bắt đầu tại [hướng dẫn đọc](docs/baseline-v2/README.md), sau đó đọc [đặc tả hệ thống](docs/baseline-v2/01_SYSTEM_SPEC.md) và [contract chung](docs/baseline-v2/06_SHARED_CONTRACTS.md).

- [Dữ liệu chuẩn tham chiếu](docs/DATA_REFERENCE.md): nội dung theo 18 nhóm, biến thể đối tượng và độ phủ nguồn.
- [PRD](docs/PRD.md): mục tiêu và phạm vi sản phẩm.
- [Kiến trúc](docs/ARCHITECTURE.md): thành phần, trách nhiệm và luồng dữ liệu.
- [Quy tắc đóng góp](CONTRIBUTING.md).

## Công nghệ

| Thành phần | Công nghệ | Trách nhiệm |
| --- | --- | --- |
| Mobile | Flutter, BLoC, SQLite | Hướng dẫn offline, tìm kiếm, chat và danh bạ |
| API | Spring Boot, PostgreSQL | Nội dung, Admin auth, snapshot và gateway AI |
| Web Admin | React + TypeScript | Quản lý bài, danh mục, nguồn và cơ sở y tế |
| RAG | FastAPI, BM25, LLM provider | Truy xuất corpus có nguồn và phản hồi theo policy |

## Phạm vi

P0 gồm đọc/tìm bài quick và learn từ cùng dữ liệu, core offline từ lần mở đầu, RAG text, danh bạ, CRUD Admin và cập nhật full snapshot thủ công. CPR metronome là P1. Không triển khai voice, AI ảnh, mô phỏng/quiz, tài khoản mobile, hồ sơ nạn nhân hoặc điều phối xe. Tiêu chí ở [08](docs/baseline-v2/08_ACCEPTANCE_AND_PLAN.md).

## Phát triển local

Phiên bản SDK và dependencies lấy từ cấu hình build/lockfile của từng thành phần. Không đưa secrets vào repository.

Mobile:

```powershell
cd mobile
flutter pub get
flutter run
```

Spring Boot trên Windows:

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

API public dùng prefix `/api/v1`; FastAPI chỉ phục vụ nội bộ qua `/internal/v1`. Base URL cấu hình theo môi trường. Android emulator dùng `10.0.2.2` để truy cập dịch vụ trên máy phát triển.
