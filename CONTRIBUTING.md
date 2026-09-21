# Quy tắc đóng góp (Contributing Guidelines)

Để dự án hoạt động trơn tru, các thành viên vui lòng tuân thủ các quy tắc sau:

## 1. Quy tắc tạo nhánh (Branching)
Không code trực tiếp trên nhánh `main`. Khi làm task mới, hãy tạo nhánh theo cú pháp:
- Tính năng mới: `feature/ten-tinh-nang` (VD: `feature/login-screen`, `feature/sos-button`)
- Sửa lỗi: `bugfix/ten-loi` (VD: `bugfix/fix-gps-crash`)
- Tài liệu: `docs/ten-tai-lieu` (VD: `docs/api-specs`)

## 2. Quy tắc viết code (Naming Conventions)
Do dự án sử dụng nhiều công nghệ khác nhau, cần lưu ý:
- **Mobile (Flutter/Dart):** Tên biến và hàm dùng `camelCase` (VD: `getUserLocation`). Tên Class dùng `PascalCase` (VD: `LocationService`).
- **Backend (Python/FastAPI):** Tên biến và hàm dùng `snake_case` (VD: `get_user_location`). Tên Class dùng `PascalCase`.

## 3. Quy tắc viết Commit Message
Bắt đầu commit bằng các tiền tố sau:
- `feat:` Thêm tính năng mới
- `fix:` Sửa lỗi code
- `docs:` Thêm/sửa tài liệu (như file README này)
- `chore:` Cấu hình linh tinh (thêm thư viện, sửa file config)
- `refactor:` Chỉnh sửa lại code cho sạch đẹp mà không làm thay đổi tính năng