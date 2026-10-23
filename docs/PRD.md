# PRD — FirstAid

## Mục tiêu

Hỗ trợ người dân nhận biết tình huống sơ cứu, đọc hướng dẫn ban đầu có nguồn, tránh hành động sai và liên hệ hỗ trợ. Sản phẩm gồm ứng dụng mobile không yêu cầu tài khoản, web Admin một role và chatbot tra cứu kiến thức bằng văn bản.

## Phạm vi sản phẩm

- Khoảng 18 nhóm tình huống với bài và biến thể phù hợp đối tượng.
- Danh mục, tìm kiếm và hướng dẫn theo bước; quick và learn dùng cùng Article.
- Nội dung core, hình bundled và metadata nguồn đọc được offline ngay sau cài.
- Guided flow giới hạn với lựa chọn cố định, có nhánh không chắc và kiểm đối tượng.
- Chatbot RAG online có citation và hành vi riêng khi thiếu bằng chứng, ngoài phạm vi, nguy cơ hoặc lỗi dịch vụ.
- Danh bạ khu vực, khoảng cách đường thẳng, mở dialer/map chủ động.
- Admin quản lý Category, Article, Source và Facility; DRAFT/PUBLISHED, session và CSRF.
- Cập nhật full snapshot thủ công, giữ dữ liệu local khi lỗi và không đổi bài giữa lúc đang đọc.

CPR metronome là P1. Voice, nhận diện ảnh, mô phỏng/quiz, tài khoản mobile, hồ sơ nạn nhân và điều phối xe nằm ngoài phạm vi.

## Đặc tả chi tiết

| Tài liệu | Nội dung |
| --- | --- |
| [01 — System specification](baseline-v2/01_SYSTEM_SPEC.md) | P0/P1, FR01–FR19, UC01–UC07 và quy tắc nghiệp vụ |
| [06 — Shared contracts](baseline-v2/06_SHARED_CONTRACTS.md) | Schema, enum, payload, API, mã lỗi và timeout |
| [07 — Content catalog](baseline-v2/07_CONTENT_CATALOG.md) | FA01–FA18, biến thể, nguồn và yêu cầu coverage |
| [08 — Acceptance and plan](baseline-v2/08_ACCEPTANCE_AND_PLAN.md) | NFR, TC01–TC24 và trình tự triển khai |

01 là nguồn thống nhất về phạm vi; 06 là nguồn thống nhất về contract; 07 quy định danh mục nội dung. Tài liệu này là điểm vào PRD, không sao chép toàn bộ yêu cầu chi tiết.

## Nguyên tắc

Hướng dẫn khẩn cấp dùng nội dung cố định có nguồn; LLM không tự sinh thủ thuật. Không thay bài khác đối tượng khi thiếu nội dung phù hợp. Không chẩn đoán, kê đơn hoặc cam kết tiếp nhận của cơ sở y tế. Nội dung và quyền sử dụng nguồn/hình phải được kiểm tra trước khi công bố.
