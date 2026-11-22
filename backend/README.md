# FirstAid backend

Spring Boot, Java 21, PostgreSQL và Flyway. Dùng [bàn giao backend](../docs/BACKEND_HANDOFF.md) để nhận việc. API theo [hợp đồng chung](../docs/baseline-v2/06_SHARED_CONTRACTS.md). Migration thực thi nằm trong [db/migration](src/main/resources/db/migration).

## Chạy cùng dự án trên Windows

Dùng [launcher local](../README.md#phát-triển-local) để khởi động PostgreSQL, Spring, FastAPI và Admin. Launcher lưu thông tin kết nối và tài khoản local trong `.local/credentials.json` tại thư mục gốc. Lần chạy lại giữ nội dung đã sửa bằng Admin.

## Chạy riêng Spring

1. Tạo PostgreSQL database và user có quyền chạy Flyway.
2. Đặt biến môi trường cho tiến trình Java theo [mẫu cấu hình](.env.example). Khi khởi động, Flyway áp dụng tuần tự các migration trong repository.
3. Đặt `ADMIN_SEED_USERNAME` và `ADMIN_SEED_PASSWORD` khi tạo tài khoản đầu tiên. Mật khẩu dài ít nhất 12 ký tự. Seeder giữ mật khẩu đã lưu.
4. Đặt `PUBLIC_LOCALE`, `PUBLIC_REGION` và `EMERGENCY_NUMBER` theo môi trường. Snapshot v1 cần `region_code` khớp `PUBLIC_REGION`.
5. Đặt `ADMIN_ORIGIN` theo origin của web. Chỉ đặt `SESSION_COOKIE_SECURE=false` khi dùng HTTP local.
6. Chạy `./mvnw spring-boot:run` từ thư mục này. Trên PowerShell, chạy `.\mvnw.cmd spring-boot:run`.

Public và Admin API dùng prefix `/api/v1`. Để đăng nhập Admin, lấy CSRF từ `GET /api/v1/admin/auth/csrf`. Gửi token vào header trả về từ endpoint đó và gửi `{username,password}` đến `POST /api/v1/admin/auth/login`. Sau login, lấy lại CSRF. Giữ session cookie cho các request tiếp theo.

Spring nhận `AI_BASE_URL` và `AI_INTERNAL_TOKEN` để gọi FastAPI qua mạng riêng. Chat trả `unavailable` khi chưa kết nối được AI. Đặt `AI_REQUEST_TIMEOUT_SECONDS=35` cho môi trường kiểm Gemini theo [hướng dẫn AI](../ai/GROUNDED_GENERATION.md). Khóa Gemini thuộc tiến trình AI.

## Dữ liệu và kiểm thử

- Dùng launcher để nạp thư viện đã biên soạn. Dùng `scripts/import_reference_drafts.sql` trên database thử trống phần bài khi cần kiểm riêng dữ liệu nháp. Bản nháp chỉ hiện với Admin.
- Chạy `./mvnw test` hoặc `.\mvnw.cmd test` để kiểm Spring. Dùng DB thử riêng cho các script có ghi dữ liệu.
- Đặt `TEST_ADMIN_USERNAME` và `TEST_ADMIN_PASSWORD` cho `scripts/smoke.ps1`. Script v1 gửi `region_code=VN-PILOT`. Cấu hình backend thử cùng mã vùng. Chạy `powershell -ExecutionPolicy Bypass -File scripts/smoke.ps1 -BaseUrl http://127.0.0.1:18080/api/v1`.
- Dùng `node scripts/mock_ai_fixture.js` và `node scripts/ai_gateway_smoke.js` để kiểm gateway văn bản. Fixture AI nghe cổng 18081. Script gọi Spring cổng 18080. Đặt `AI_BASE_URL=http://127.0.0.1:18081` và `AI_INTERNAL_TOKEN=LocalInternalTestToken` cho backend thử.
- Chạy kiểm ảnh bước, xuất bản và đồng bộ theo [BE-04](../docs/BACKEND_HANDOFF.md#be-04-kiểm-tích-hợp-trên-môi-trường-riêng).
