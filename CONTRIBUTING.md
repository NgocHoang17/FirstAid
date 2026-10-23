# Quy tắc đóng góp

## Nhánh và commit

Không làm trực tiếp trên `main`. Dùng `feature/ten-tinh-nang`, `bugfix/ten-loi` hoặc `docs/ten-tai-lieu`. Commit dùng `feat:`, `fix:`, `docs:`, `chore:` hoặc `refactor:` theo nội dung thực tế. Không gộp thay đổi sẵn của người khác vào task.

## Đọc tài liệu theo công việc

Bắt đầu với [README baseline](docs/baseline-v2/README.md), [01](docs/baseline-v2/01_SYSTEM_SPEC.md) và [06](docs/baseline-v2/06_SHARED_CONTRACTS.md); đọc guide chuyên trách theo thứ tự trong README. Coding agent đọc thêm [09](docs/baseline-v2/09_CODEX_WORKFLOW.md) và AGENTS.md thực sự áp dụng nếu có. Prompt mẫu không phải yêu cầu tự triển khai mọi tính năng.

Scope theo 01, payload/API theo 06, catalog theo 07; khi thay contract phải cập nhật tài liệu và kiểm liên quan trong cùng tác vụ. Nêu khác biệt giữa baseline và code trước khi đổi stack. Docs là đặc tả dùng chung, không ghi tiến độ hoặc kiểm kê code. Chỉ sửa khi yêu cầu, kiến trúc hoặc contract thay đổi. Báo tiến độ, kết quả kiểm thử và việc còn lại trong task/PR; không báo test hoặc dữ liệu y khoa chưa kiểm là đã đạt.

## Quy ước tên

- Flutter/Dart: biến/hàm `camelCase`, class `PascalCase`.
- Java/Spring Boot: biến/phương thức `camelCase`, class `PascalCase`.
- Python/FastAPI RAG (mục tiêu): biến/hàm `snake_case`, class `PascalCase`.
- JSON/API: field `snake_case` theo 06, không suy từ cách đặt tên của ngôn ngữ.

Giữ BLoC và tổ chức hiện có khi phù hợp. Không thêm dependency hoặc chức năng ngoài scope chỉ vì xuất hiện trong tài liệu cũ. Chạy kiểm phù hợp với phần thay đổi, báo giới hạn thực tế; không commit secret hoặc PDF gốc mặc định.
