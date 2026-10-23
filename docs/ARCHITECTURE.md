# Kiến trúc FirstAid

## Thành phần

```text
Flutter mobile ── đọc ── SQLite + assets bundled
       │
       └── /api/v1 ── Spring Boot ── PostgreSQL
                          │
Web Admin ────────────────┤
                          └── /internal/v1 ── FastAPI RAG ── corpus/index + LLM provider
```

| Thành phần | Trách nhiệm |
| --- | --- |
| Flutter mobile | Hiển thị nội dung, tìm kiếm local, quick/learn, guided flow, chat UI và danh bạ |
| SQLite và assets | Lưu core offline, nguồn metadata, danh bạ và hình thiết yếu |
| Spring Boot | Public API, Admin auth/CRUD, validation publish, snapshot và gateway AI |
| PostgreSQL | Category, Article, Step, Source, SourceReference, Facility và AdminUser |
| React + TypeScript Admin | Quản lý nội dung và cơ sở y tế với role ADMIN |
| FastAPI RAG | Policy, retrieval BM25, gọi provider và kiểm output theo contract |

## Mobile và ngoại tuyến

Tổ chức theo feature, dùng BLoC thống nhất và repository để tách giao diện khỏi dữ liệu. Quick/learn đọc cùng Article, khác cách trình bày. Seed nội dung core và asset map đi kèm ứng dụng, nạp SQLite trong transaction; việc đọc bài không phụ thuộc request mạng.

Cập nhật nội dung do người dùng chủ động. Mobile kiểm schema và liên kết trước khi ghi full snapshot trong transaction; lỗi giữ dữ liệu cũ. Hoãn cập nhật khi đang đọc bài/guided flow. Không lưu lịch sử bundle hoặc hỗ trợ rollback nhiều phiên bản.

## API và quản trị

Spring Boot là gateway public với prefix `/api/v1`. Public chỉ đọc dữ liệu đã publish hợp lệ. Admin dùng session cookie và CSRF; chỉ một role ADMIN. Không tạo tài khoản mobile, hồ sơ bệnh nhân hoặc bảng lịch sử chat.

Article gồm các bước và references, kiểm nội dung trước publish; expected_revision ngăn ghi đè khi sửa đồng thời. Snapshot nhất quán dùng data_version và ETag. Danh bạ dùng Haversine tính khoảng cách đường thẳng, không suy thành ETA hoặc khả năng tiếp nhận.

## AI và nguồn

FastAPI chỉ phục vụ mạng nội bộ, giao tiếp với Spring qua `/internal/v1` và token server. Corpus được tuyển chọn từ tài liệu có nguồn, giữ ID, revision, trang và đối tượng. P0 dùng BM25; generation phải qua policy và validation. Spring kiểm citation/source/article revision trước khi trả mobile.

Chat xử lý độc lập từng request, trả sáu ChatStatus theo contract. Hướng dẫn khẩn cấp dùng nội dung cố định; nguy cơ được chuyển hướng về hỗ trợ và bài local phù hợp. Provider lỗi không ảnh hưởng khả năng đọc bài offline.

## Ranh giới thiết kế

Gọi và mở bản đồ là hành động chủ động của người dùng. Không thu thập vị trí nền, hình nạn nhân hoặc định danh. Không xây reviewer workflow, microservice phức tạp, vector database riêng hoặc AI sinh thủ thuật tại hiện trường.

## Tài liệu chuyên trách

Phạm vi theo [01](baseline-v2/01_SYSTEM_SPEC.md), contract theo [06](baseline-v2/06_SHARED_CONTRACTS.md). Hướng dẫn: [Frontend](baseline-v2/03_FRONTEND_GUIDE.md), [Backend](baseline-v2/04_BACKEND_GUIDE.md), [AI](baseline-v2/05_AI_RAG_GUIDE.md), [thiết kế](baseline-v2/02_FIGMA_DESIGN_BRIEF.md) và [nghiệm thu](baseline-v2/08_ACCEPTANCE_AND_PLAN.md).
