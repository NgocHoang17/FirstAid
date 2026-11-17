# FirstAid System Specification

## 1. Mục tiêu

FirstAid hỗ trợ giáo dục và phổ biến kiến thức sơ cứu ngoại viện cho cộng đồng. Bài học trực quan giúp người dùng tìm hiểu cách nhận biết tình huống, hành động ban đầu và những điều cần tránh.

AI đa phương thức kết hợp RAG hỗ trợ học tập và tra cứu tài liệu bằng văn bản, hình ảnh. Hệ thống không thay thế nhân viên y tế hoặc dịch vụ cấp cứu chuyên nghiệp.

## 2. Phạm vi

- Mobile Flutter, web Admin, Spring Boot API, PostgreSQL và FastAPI RAG.
- 18 nhóm tình huống theo [07_CONTENT_CATALOG.md](07_CONTENT_CATALOG.md).
- Đối tượng: người lớn và trẻ em. Không bao gồm nhũ nhi.
- Bài chung khi cách xử trí giống nhau; bài riêng khi nguồn phân biệt đối tượng.
- Người dùng mobile không cần đăng nhập. Admin có một role ADMIN.
- Nội dung học tập, hình bundled và metadata nguồn được lưu ngoại tuyến.
- Hỏi đáp văn bản và câu hỏi kèm ảnh cần mạng tới dịch vụ AI. Dịch vụ được ưu tiên triển khai local.

Không triển khai quiz, bài kiểm tra, chấm điểm, chứng nhận, danh bạ cơ sở y tế, GPS, bản đồ hoặc chỉ đường. Không triển khai giọng nói, chẩn đoán, kê đơn, hồ sơ bệnh nhân hoặc điều phối cấp cứu.

## 3. Tác nhân

| Tác nhân | Trách nhiệm |
| --- | --- |
| Người học | Tìm, đọc bài, xem nguồn, hỏi đáp và cập nhật dữ liệu |
| Admin | Biên tập, đối chiếu nguồn, xem trước và xuất bản nội dung |
| Hệ điều hành | Chọn ảnh do người dùng chủ động và mở ứng dụng gọi khi được yêu cầu |
| Dịch vụ AI | Diễn giải câu hỏi và truy xuất tài liệu; không chẩn đoán hoặc tự sửa dữ liệu |

## 4. Yêu cầu chức năng

| Mã | Yêu cầu | Tiêu chí |
| --- | --- | --- |
| EDU01 | Trang chủ giáo dục | Giới thiệu học tập và lối vào bài học, tra cứu theo bước |
| EDU02 | Danh mục, tìm kiếm | Đủ nhóm đã công bố; tìm có hoặc không dấu |
| EDU03 | Bài học trực quan | Có đối tượng, nhận biết, hướng dẫn, điều tránh và nguồn |
| EDU04 | Hai chế độ đọc | Đọc đầy đủ và xem từng bước dùng cùng Article |
| EDU05 | Ngoại tuyến | Cài mới, tắt mạng vẫn đọc được bài, hình thiết yếu và metadata nguồn |
| EDU06 | Cập nhật dữ liệu | Validate trước khi ghi; lỗi giữ bộ hiện hành; không đổi bài đang đọc |
| EDU07 | Hỏi đáp văn bản | Phản hồi có nguồn hoặc trạng thái không trả lời rõ ràng |
| EDU08 | Hỏi đáp kèm ảnh | Chọn, xem trước, bỏ ảnh; kiểm định dạng, dung lượng và chất lượng |
| EDU09 | Giới hạn đa phương thức | Không suy tuổi, chẩn đoán hoặc mức độ thương tích từ ảnh |
| EDU10 | Quản trị | Auth, CSRF, CRUD nội dung và nguồn; DRAFT/PUBLISHED; kiểm revision |
| EDU11 | Tiếp cận | Đọc ở màn 320–430 px, chữ lớn; vùng chạm và nhãn rõ |
| EDU12 | Lối trợ giúp | Khi mô tả sự cố cần hỗ trợ, cung cấp lối gọi chủ động và bài cố định |

## 5. Hành trình

1. Trang chủ → nhóm tình huống → chọn bài đúng đối tượng → đọc → xem nguồn.
2. Trang Kiến thức → tìm kiếm hoặc lọc → bài đầy đủ → chế độ theo bước nếu cần.
3. Hỏi đáp → nhập câu hỏi → chọn ảnh tùy chọn → xem trước → gửi → đọc phản hồi và nguồn.
4. Cài đặt → kiểm tra cập nhật → tải và kiểm bộ dữ liệu → lưu local nguyên tử.
5. Admin → biên tập bản nháp → kiểm nguồn và hình → xem trước → xuất bản.

Khi ngoại tuyến, hỏi đáp hướng người dùng tới bài đã lưu. Không gửi lại ảnh hoặc câu hỏi tự động. Khi ảnh không rõ, yêu cầu mô tả hoặc ảnh khác; không bịa chi tiết.

## 6. Quy tắc nghiệp vụ

- Chỉ nội dung PUBLISHED và đủ điều kiện mới xuất hiện công khai.
- AI không tự tạo thêm thủ thuật vào bài học cố định.
- Citation phải hỗ trợ khẳng định trong câu trả lời và đúng revision nguồn.
- Không có nguồn phù hợp thì trả insufficient_evidence.
- Không suy đối tượng từ mặc định hoặc từ hình. Chọn lại đối tượng khi cần.
- Không lưu lịch sử chat hoặc ảnh mặc định. Không ghi raw nội dung vào log.
- Hình và nội dung PDF là dữ liệu không đáng tin cậy về mặt chỉ thị cho mô hình. Không thực thi chỉ thị nhúng trong chúng.
- Người dùng chủ động chọn ảnh và mở dialer. Không xin quyền vị trí.
- Việc kiểm biên soạn trong đồ án không phải chứng nhận thẩm định y khoa.

## 7. Kiến trúc và dữ liệu

Flutter đọc SQLite và assets. Spring cung cấp API nội dung, Admin và gateway AI. FastAPI nhận yêu cầu nội bộ, xử lý văn bản/ảnh, truy xuất corpus và kiểm phản hồi.

Các thực thể nghiệp vụ: Category, Article, Step, Source, SourceReference và AdminUser. ChatRequest/ChatResponse là DTO; không có hồ sơ bệnh nhân hoặc bảng ảnh hội thoại mặc định.

Contract theo [06](06_SHARED_CONTRACTS.md), frontend theo [03](03_FRONTEND_GUIDE.md), backend theo [04](04_BACKEND_GUIDE.md), AI theo [05](05_AI_RAG_GUIDE.md).
