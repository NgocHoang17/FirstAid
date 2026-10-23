# FirstAid Development Pack

**Baseline 2.0 — ngày 23/10/2026 — phạm vi dành cho nhóm 3 sinh viên trong hơn một tháng.**

Bộ tài liệu này mô tả phạm vi đã thống nhất: ứng dụng Flutter hỗ trợ khoảng 18 nhóm tình huống sơ cứu, đọc ngoại tuyến, chatbot RAG bằng văn bản, danh bạ cơ sở y tế và web quản trị với một vai trò Admin. Người dùng mobile không cần tài khoản.

Phạm vi không bao gồm quy trình duyệt nhiều cấp, nhật ký nạn nhân, ký gói nội dung, thu hồi/rollback nhiều phiên bản, huấn luyện PhoBERT/NER, giọng nói hoặc nhận diện hình ảnh. Đây là tài liệu thiết kế, chưa phải kết quả đối chiếu mã nguồn hoặc chứng nhận nội dung y khoa.

## 1. Các tệp trong gói

| Tệp | Mục đích |
| --- | --- |
| [01_SYSTEM_SPEC.md](01_SYSTEM_SPEC.md) | Đặc tả chung về sản phẩm, phạm vi, tác nhân, chức năng, luồng và kiến trúc |
| [02_FIGMA_DESIGN_BRIEF.md](02_FIGMA_DESIGN_BRIEF.md) | Brief thiết kế mobile và admin, danh sách màn hình, component, trạng thái và prototype |
| [03_FRONTEND_GUIDE.md](03_FRONTEND_GUIDE.md) | Hướng dẫn Flutter mobile và web admin, dữ liệu, điều hướng, tích hợp và thứ tự triển khai |
| [04_BACKEND_GUIDE.md](04_BACKEND_GUIDE.md) | Spring Boot, database, xác thực Admin, CRUD, cập nhật dữ liệu và gateway AI |
| [05_AI_RAG_GUIDE.md](05_AI_RAG_GUIDE.md) | Chuẩn bị corpus, RAG, policy, citation, FastAPI và đánh giá |
| [06_SHARED_CONTRACTS.md](06_SHARED_CONTRACTS.md) | Nguồn thống nhất cho ID, enum, JSON, API và giao tiếp giữa các phần |
| [07_CONTENT_CATALOG.md](07_CONTENT_CATALOG.md) | 18 nhóm tình huống, cấu trúc bài, biến thể đối tượng, nguồn và checklist dữ liệu |
| [08_ACCEPTANCE_AND_PLAN.md](08_ACCEPTANCE_AND_PLAN.md) | Kế hoạch hơn một tháng, phân công, tiêu chí hoàn thành và test nghiệm thu |
| [09_CODEX_WORKFLOW.md](09_CODEX_WORKFLOW.md) | Quy tắc làm việc cho Codex và các prompt giao việc theo giai đoạn |

## 2. Thứ tự đọc

- Mọi người và mọi coding agent: đọc README, 01 và 06 trước.
- Thiết kế Figma: đọc thêm 02 và 07; không cần tạo nội dung y khoa từ trí tưởng tượng.
- Frontend: đọc 03, 02 và 08.
- Backend: đọc 04, 06 và 08.
- AI: đọc 05, 07, 06 và phần đánh giá trong 08.
- Codex thực hiện tác vụ: đọc thêm 09 và mọi AGENTS.md thực sự có trong repository.

Nếu chỉ gửi một tài liệu cho một agent, gửi kèm 01 và 06. Các tài liệu chuyên trách không tự thay đổi scope hoặc contract chung.

## 3. Quy tắc thống nhất

Phạm vi sản phẩm lấy từ 01. Payload và endpoint lấy từ 06. Dữ liệu bài và danh mục lấy từ 07. Thay đổi các hợp đồng này phải cập nhật tài liệu chuyên trách và test liên quan trong cùng tác vụ. Nếu tài liệu xung đột, ghi rõ xung đột trước khi sửa; không âm thầm chọn một bản theo ý agent.

Các lựa chọn kỹ thuật mặc định trong gói: Flutter mobile; Spring Boot; PostgreSQL; FastAPI cho RAG; React + TypeScript cho admin nếu repository chưa có lựa chọn khác; SQLite local. Đây là baseline triển khai mới, không khẳng định các thư viện đã tồn tại trong dự án. Không tự thay stack đang có; nếu repo khác baseline, báo khác biệt và đề xuất cách giữ tương thích.

Những thông tin thực sự chưa biết dùng nhãn `[TODO / NEED DECISION]`, chủ yếu gồm provider/model AI, người xác nhận nội dung, quyền tái sử dụng tài liệu/hình, dữ liệu cơ sở thực và hạ tầng triển khai. Nhãn này không phải lý do để dừng toàn bộ công việc: dùng mock đúng schema cho phần độc lập, không dùng mock y khoa như dữ liệu thật.

## 4. Cách sử dụng tài liệu

Bộ tài liệu đặt tại `docs/baseline-v2/` và được tham chiếu từ README dự án. Đây là đặc tả sản phẩm, kiến trúc, contract và hướng dẫn phát triển; không dùng làm bảng tiến độ hoặc bản kiểm kê code. Chỉ cập nhật khi có quyết định thay đổi yêu cầu, kiến trúc hoặc contract. Tiến độ, kết quả kiểm thử và báo cáo hoàn thành đặt trong task/PR, không yêu cầu sửa docs sau mỗi bước triển khai.

Không đưa PDF gốc dung lượng lớn hoặc khóa API vào git mặc định. Nguồn PDF và yêu cầu quyền sử dụng nằm trong 07.

## 5. Bắt đầu một tác vụ

Đọc README, 01 và 06; chọn guide chuyên trách theo mục 2. Xác định một chức năng và tiêu chí nghiệm thu trong 08. Các prompt trong 09 là mẫu giao việc, chỉ thực hiện khi tác vụ được giao. Kiểm tra code và cấu hình để triển khai an toàn, báo kết quả trong task/PR.
