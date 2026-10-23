# Backend Implementation Guide

Baseline 2.0 | Spring Boot + PostgreSQL | Hợp đồng duy nhất ở [06_SHARED_CONTRACTS.md](06_SHARED_CONTRACTS.md).

## 1. Trách nhiệm

Backend quản lý dữ liệu công khai, một tài khoản/role Admin, CRUD, snapshot ngoại tuyến và gateway gọi FastAPI RAG. Backend không cần điều xe, realtime tracking, bệnh án, chat history, review workflow, bundle signing hoặc vector database. Không tạo endpoint đăng ký tài khoản mobile.

Trước triển khai kiểm repository, pom/Gradle, JDK, config và migration hiện có. Giữ phiên bản tương thích; không đoán Java version. Nếu project chưa có backend, khởi tạo một ứng dụng Spring Boot, không chia nhiều service. AI là một process Python riêng với hợp đồng nội bộ rõ.

## 2. Tổ chức module vừa đủ

| Module/package | Nội dung |
| --- | --- |
| auth | Spring Security, login/me/logout, CSRF, Admin seed |
| content | Category, Article, Step, Reference, Source và publish validation |
| facility | Danh bạ, lọc vùng, kiểm tọa độ và khoảng cách |
| offline | Tạo snapshot nhất quán và ETag |
| assistant | Input policy, rate limit, gọi RAG, kiểm citation, fallback |
| common | Error envelope, validation, trace ID, config |

Controller chỉ map request/response. Service xử lý nghiệp vụ và transaction. Repository chỉ truy cập dữ liệu. Dùng DTO, không serialize JPA entity trực tiếp để tránh vòng lặp, lộ password/internal fields và thay API vô ý. Không bắt buộc CQRS, event sourcing, service discovery hoặc message broker.

## 3. Database tối thiểu

UUID cho PK; timestamp UTC. Tạo migration có thứ tự và seed idempotent. Không dùng auto-update schema làm cách quản lý production mặc định.

| Bảng | Cột chính | Constraint/index |
| --- | --- | --- |
| admin_users | id, username, password_hash, enabled, created_at | username UNIQUE; không plaintext password |
| categories | id, code, name, group_code, description, keywords_json, sort_order, is_active | code UNIQUE; index sort_order |
| articles | id, category_id, slug, variant_key, title, age_group, applies_to, summary, recognition_json, quick_actions_json, warnings_json, seek_help_json, status, content_checked, checked_at, content_revision, updated_at | FK category; slug UNIQUE; UNIQUE(category_id,variant_key); index(category_id,status) |
| article_steps | id, article_id, position, title, instruction, asset_key, image_url, alt_text | FK article; UNIQUE(article_id,position); position >= 1 |
| sources | id, code, title, publisher, publication_year, page_count, revision, original_url, is_active, rights_note | code UNIQUE; page_count > 0; revision >= 1 |
| article_references | id, article_id, source_id, page_start, page_end, section_key, note | FK article/source; CHECK 1 <= page_start <= page_end |
| facilities | id, name, region_code, address, phone, latitude, longitude, emergency_24h, verification_note, verified_at, is_active | index(region_code,is_active); tọa độ cùng null/cùng có |
| public_data_state | id singleton, data_version, updated_at | Một row dùng đổi ETag snapshot |

Nếu cần trường `row_version` phục vụ optimistic locking DB, thêm nội bộ và map về expected_revision phù hợp; không làm client tự tính version. Article content_revision là counter, không bảng history. Chưa cần role/user_role tables vì chỉ ADMIN; authority có thể được gán cố định cho admin_users trong Security layer.

Mảng JSON đơn giản có thể dùng JSONB hoặc text được serialize an toàn; chọn một cách phù hợp JPA version hiện tại và kiểm round trip. Không cần chuẩn hóa mọi warning thành bảng riêng. Nested steps/reference cập nhật trong transaction, không để bài tồn tại nửa cũ nửa mới.

## 4. Authentication và phân quyền

Default web Admin và API cùng origin qua reverse proxy. Session cookie HttpOnly, Secure trên HTTPS, SameSite phù hợp. Login JSON username/password theo 06; cấu hình handler/filter đọc JSON đúng, không dùng form-urlencoded trong implementation trong khi frontend gửi JSON.

CSRF bật cho Admin, gồm logout và request ghi; frontend lấy token từ `/api/v1/admin/auth/csrf`, gửi theo header đã thống nhất cấu hình. Sau login token có thể thay đổi theo framework; client lấy lại CSRF token để tránh lỗi request đầu tiên. `/auth/me` dùng xác nhận session khi reload.

Admin user đầu tiên tạo bằng CLI/seed đọc biến môi trường, không commit password mặc định vào repo. Hash password bằng password encoder của Security stack, không tự viết thuật toán hash. Có giới hạn thử login và thông báo lỗi không tiết lộ password/stack trace. Không yêu cầu JWT hoặc refresh token để làm cùng chức năng session.

API public chỉ có GET nội dung và POST assistant; request này không mang quyền Admin. FastAPI không được mở public; internal token chỉ server đọc được. Không public PostgreSQL cổng Internet. Dev CORS allowlist chính xác origin được nhóm dùng, không kết hợp wildcard với credential.

POST public `/api/v1/assistant/query` phục vụ mobile ẩn danh, không dùng session Admin để cấp quyền; cấu hình CSRF chỉ exempt endpoint public này khi cần. Không tắt CSRF toàn bộ `/admin/**` để làm chat chạy. Các request ghi Admin vẫn cần session và CSRF như trên.

## 5. CRUD và publish đơn giản

### 5.1 Category

Tạo/sửa code và tên có validation; 18 seed codes giữ ổn định cho guided flow và AI. Không tự đổi FA01 sang mã khác khi rename. Danh mục có bài thì không hard-delete. Deactivate category chứa bài public phải bị chặn hoặc yêu cầu unpublish bài trước; không âm thầm làm mất nhóm trong snapshot.

### 5.2 Source

Chỉ quản lý metadata và quyền sử dụng/URL. Không xây pipeline upload PDF tự động. Tệp gốc đưa vào AI qua quy trình developer ở 05. Xóa/deactivate source còn article public tham chiếu trả RESOURCE_IN_USE. Nếu source chỉ đang dùng trong corpus thì gateway chặn khi inactive/revision mismatch; nhóm phải rebuild index sau thay đổi để trả lời trở lại đầy đủ.

### 5.3 Article

Create luôn DRAFT. PUT nhận nested content và expected_revision; nếu version khác trả 409. Khi sửa bài public, chuyển DRAFT, content_checked=false, checked_at=null và tăng revision; public_data_state cũng đổi vì bài đã rời public. Frontend cảnh báo trước hành động này. Khi sửa draft, tăng revision nhưng không cần đổi public_data_state nếu public dataset không thay đổi.

Admin kiểm nội dung bên ngoài rồi đặt content_checked=true bằng update draft; backend đặt checked_at thời điểm server nhận xác nhận. Không tin checked_at do client gửi tùy ý. Bất kỳ thay đổi nội dung sau xác nhận đặt content_checked=false, trừ request xác nhận nội dung cuối có toàn bộ payload và flag phù hợp. Việc này là trạng thái xác nhận của Admin, không thêm role hoặc quy trình phê duyệt nhiều cấp.

Publish kiểm các mục bắt buộc trong 06, references đúng trang nguồn active và object chưa đổi version. Thực hiện publish + đổi data_version trong cùng transaction. Unpublish tương tự. Public GET không trả draft, kể cả đoán đúng ID. DELETE xóa child rows theo transaction, đổi data_version nếu dữ liệu public bị xóa. Guided route nằm trong app không phải FK server; mobile phải resolve bài còn hợp lệ sau update, thiếu bài thì unsupported. Không tạo thêm bảng dependency chỉ để quản lý một vài flow local.

### 5.4 Hình ảnh

Core asset_key được nhóm đóng gói sẵn trong Flutter, có allowlist dùng chung. image_url optional HTTPS URL cho hình bổ sung, không tự tải URL tùy ý từ backend để tránh SSRF. P0 không cần server upload ảnh nếu repo chưa có. Nếu nhóm đã có upload, giữ theo whitelist/dung lượng an toàn và không biến thành yêu cầu bắt buộc mới.

### 5.5 Facility

Admin nhập name/address/region/phone/coordinates/verification. Chỉ active khi các trường cơ bản đã được kiểm; 24/7 không rõ thì UNKNOWN. Lưu dữ liệu thật theo nguồn, không tự lấy fixture làm bệnh viện đang hoạt động. Không có trường available_beds, ambulance_eta hoặc specialty_score.

## 6. Snapshot ngoại tuyến

Endpoint `/api/v1/offline-snapshot?region_code=...` xuất đúng DTO 06. Category/article/source trong public snapshot phải referentially complete; lấy sources được phép công khai và đang được dùng. Facilities lọc một vùng. App_config chỉ chứa cấu hình public.

Đọc public_data_state và tập nội dung trong một transaction có consistent snapshot (ví dụ isolation phù hợp DB), tránh ETag version A nhưng content version B. Với dataset nhỏ có thể khóa row state khi xuất nếu đo thấy đủ; không giữ transaction khi gọi LLM hoặc làm công việc ngoài DB.

Response header ETag dùng data_version được quote đúng HTTP. If-None-Match trùng thì 304, không body JSON. Version mới là token ngẫu nhiên server tạo khi public dataset đổi, không timestamp do client cung cấp. Không cần lưu gói ZIP, checksum/chữ ký hay lịch sử release. Snapshot là dữ liệu JSON đầy đủ, không kèm PDF gốc.

Schema version không tăng vì sửa một bài. Chỉ tăng khi thay cấu trúc không tương thích và phối hợp frontend. Không gửi schema mới khiến app cũ mất dữ liệu; frontend giữ local và thông báo cập nhật app.

## 7. Danh bạ và khoảng cách

Danh bạ nhỏ không bắt buộc PostGIS. GET list theo region; nếu có cả latitude/longitude thì tính Haversine trong service, sắp distance tăng. Validate bounds, không đọc vị trí từ header ngầm. Không có vị trí thì sort theo tên hoặc sort ổn định đã công bố, distance=null.

Haversine dùng radian, bán kính Trái Đất thống nhất cùng frontend; có test điểm trùng và thứ tự gần/xa. Đây là xấp xỉ khoảng cách đường thẳng, không route/ETA. Trường distance chỉ trên DTO.

## 8. Gateway AI

Input validation → policy/risk check cơ bản → rate limit → POST FastAPI nội bộ → parse DTO → kiểm citations và suggested article → trả response envelope. Emergency policy thực hiện cả gateway lẫn AI theo cùng test fixture/policy config, không để hai bản luật tự khác nhau.

Provider lỗi, timeout, output sai schema hoặc nguồn không còn active/revision mismatch thì fallback controlled unavailable hoặc insufficient_evidence. Không trả nguyên exception. API gateway không nhận raw prompt tùy ý, không forward Admin cookie/token sang LLM.

Citation check: source tồn tại, active, revision bằng source_revision, trang trong page_count; article optional nếu có phải public, revision khớp và age_group phù hợp. Mapping title lấy DB. Chặn một citation sai thì không hiển thị một câu trả lời vẫn chứa khẳng định dựa trên citation bị loại; trả fallback hoặc yêu cầu AI tạo lại trong ngân sách đã định, P0 ưu tiên fallback không retry.

Không log message hoặc tọa độ. Ghi trace_id, duration, status, corpus_version, lỗi kỹ thuật. Không cần lưu bảng chat. HTTP limits và ngân sách timeout theo 06, không đặt mỗi tầng 30 giây rồi cộng dồn.

## 9. Kiểm tra đầu vào và lỗi

Title ≤ 200 ký tự; summary ≤ 1000; message chat ≤ 2000; step text đủ dài cho hướng dẫn nhưng có giới hạn hợp lý (đề xuất 4000 mỗi bước); số steps ≤ 50; enum strict. Nếu giới hạn thực tế không đủ cho một bài nguồn, nhóm chỉnh contract/test thống nhất, không cắt nội dung âm thầm.

URL chỉ scheme HTTPS (hoặc null), phone lưu dạng chuẩn hóa cho dialer, không suy mã quốc gia nếu dữ liệu chưa kiểm. Bắt lỗi FK/unique ở service exception handler để trả mã rõ. Mọi lỗi theo envelope 06; không trả entity và stacktrace.

## 10. Migration, cấu hình và chạy local

Cần `.env.example`/application profile tài liệu hóa DB URL/user/password, Admin seed, AI_BASE_URL, AI_INTERNAL_TOKEN, chat limits, timezone và public region. Không ghi secrets thật. Cách truyền biến phù hợp stack hiện có; dùng một nguồn config, không hardcode ba nơi.

Migration tạo schema; seed categories + source metadata idempotent; nội dung fixture demo tách seed nghiệm thu. Không tự public các bài source chưa kiểm để demo đủ số. Docker Compose là tiện ích tùy môi trường, không bắt buộc nếu nhóm đang chạy trực tiếp.

Tài liệu chạy phải mô tả: chuẩn bị PostgreSQL → migration/seed → chạy backend → kiểm public categories → login Admin → chạy AI thật hoặc mock profile rõ → nối mobile. Mock AI không được tự bật trong production khi provider lỗi.

## 11. Test tối thiểu có giá trị

- Public GET không lộ draft, Admin ghi thiếu auth/CSRF bị chặn.
- Publish thiếu nguồn, sai trang hoặc chưa content_checked bị từ chối.
- Update nested article rollback toàn transaction nếu child sai.
- expected_revision cũ bị 409.
- Xóa source/category đang được dùng bị RESOURCE_IN_USE.
- Snapshot đủ liên kết và ETag đổi sau publish/unpublish/facility update.
- 304 không body; snapshot lỗi không phát dữ liệu nửa vời.
- Citation nguồn giả, sai revision/trang, article draft bị chặn.
- AI timeout trả fallback, không lộ stack trace và không log câu hỏi.
- Khoảng cách và tọa độ không hợp lệ được xử lý.

Không viết test chỉ để kiểm Lombok getter/setter. Ưu tiên các ranh giới nghiệp vụ có thể gây sai dữ liệu hoặc lộ quyền.

## 12. Thứ tự triển khai và DoD

DB/migration → public read → local snapshot contract → Admin auth → CRUD → publish validation → directory → AI gateway → integration/fault tests. Frontend có thể dựng UI từ fixture ngay khi DTO chốt; AI có thể phát triển độc lập qua `/internal/v1/query`.

Hoàn thành khi endpoint đúng 06, README chạy từ môi trường sạch, Admin không cần reviewer role, snapshot nhất quán, corpus cũ bị kiểm revision, các lỗi có mã, không secrets trong repo và không thêm bảng/tính năng ngoài phạm vi. OpenAPI được sinh/cập nhật từ implementation sau khi xác nhận contract, không coi docs là code đã có.
