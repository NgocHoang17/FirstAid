# FirstAid backend

Spring Boot 4.1.1 / Java 21, PostgreSQL 15+ và Flyway. API theo [contract](../docs/baseline-v2/06_SHARED_CONTRACTS.md), lược đồ theo [thiết kế CSDL](../docs/DATABASE_DESIGN.md).

## Chạy local

1. Tạo PostgreSQL database rỗng, user có quyền tạo bảng trong database đó. Đặt `DB_URL`, `DB_USER`, `DB_PASSWORD` từ [mẫu cấu hình](.env.example). Flyway tự chạy `V1__schema.sql` và `V2__reference_metadata.sql` khi khởi động.
2. Đặt `ADMIN_SEED_USERNAME` và `ADMIN_SEED_PASSWORD` (ít nhất 12 ký tự) cho lần tạo Admin đầu tiên. Không có tài khoản/mật khẩu mặc định trong mã nguồn. Lần chạy sau có thể bỏ hai biến này; seed không ghi đè mật khẩu đã có.
3. Xác minh khu vực/số hỗ trợ trước khi đặt `PUBLIC_REGION` và `EMERGENCY_NUMBER`. Khi một trong hai để trống, endpoint snapshot trả 503 thay vì xuất cấu hình chưa kiểm. Đặt `SESSION_COOKIE_SECURE=false` **chỉ khi chạy HTTP local**; trên HTTPS giữ `true`.
4. Chạy `./mvnw spring-boot:run` (Windows: `.\mvnw.cmd spring-boot:run`). Public GET ở `/api/v1`; Admin dùng session cookie và `X-CSRF-TOKEN` lấy từ `GET /api/v1/admin/auth/csrf`. Login nhận JSON `{username,password}`. Sau login lấy lại CSRF token.

`AI_BASE_URL` và `AI_INTERNAL_TOKEN` chỉ dùng ở backend; FastAPI phải ở mạng nội bộ. Khi chưa cấu hình AI, `/api/v1/assistant/query` trả `status=unavailable` đúng schema, không trả nội dung mô phỏng như dữ liệu thật. CORS chỉ cho origin cấu hình bằng `ADMIN_ORIGIN`.

## Dữ liệu tham chiếu

Migration V2 chỉ seed 18 danh mục và 14 metadata nguồn, giữ UUID từ `mobile/assets/content/reference_library.json`. **Không tự publish** 24 bài DRAFT hoặc cơ sở giả. Nếu muốn đưa toàn bộ bài tham chiếu vào DB phát triển để biên tập, chạy [script import DRAFT](scripts/import_reference_drafts.sql) **một lần trên DB chưa có Article** sau khi Flyway chạy. Script giữ ID bài/bước, 58 trích dẫn và trạng thái DRAFT; nó từ chối DB đã có bài. Nội dung chưa được xác nhận độc lập và không xuất qua API public.

Backend không ghi chat history, bệnh án, tài khoản mobile, guided graph hoặc vector index trong PostgreSQL. Corpus RAG được build ở FastAPI từ nguồn đã chọn; Spring kiểm lại citation/revision trước khi trả.

## Kiểm tra local

Trên **DB thử nghiệm riêng**, đặt `TEST_ADMIN_USERNAME`/`TEST_ADMIN_PASSWORD` trùng Admin seed rồi chạy `powershell -ExecutionPolicy Bypass -File .\scripts\smoke.ps1`. Script chỉ nhận API HTTP localhost, tạo một bài minh họa, kiểm auth/CSRF, draft/public, duplicate references, bảo vệ source, publish, revision, ETag/304 và xóa bài sau khi thử.

Để kiểm gateway AI, chạy `node scripts/mock_ai_fixture.js` trong terminal khác, đặt `AI_BASE_URL=http://127.0.0.1:18081` và `AI_INTERNAL_TOKEN=LocalInternalTestToken`, khởi động lại backend rồi chạy `node scripts/ai_gateway_smoke.js`. Mock chỉ dành cho test và không tự bật trong production.

## Các ranh giới cần kiểm khi tích hợp

- Public không đọc DRAFT; publish cần `content_checked`, đủ section, nguồn active và trang hợp lệ.
- PUT Article nhận `expected_revision`; sửa bài PUBLISHED chuyển DRAFT và đổi `data_version`.
- Snapshot dùng transaction `REPEATABLE_READ`, ETag token và 304 không body. Mobile chỉ áp dụng snapshot schema 1 sau khi validate và thay SQLite trong một transaction.
- Xóa category/source còn liên kết bị chặn; đổi source revision khiến citation corpus cũ bị từ chối.

Backend cũ dùng `/api/v1/handbook`, `/api/v1/triage`, `/api/v1/facilities/nearby` với dữ liệu hardcode đã được thay bằng các path trong contract 06. Mobile hiện có thể vẫn cần cập nhật client khi nối API mới.
