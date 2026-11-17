# FirstAid: yêu cầu sản phẩm

## Mục tiêu

FirstAid là ứng dụng di động hỗ trợ giáo dục và phổ biến kiến thức sơ cứu y tế ngoại viện cho cộng đồng. Ứng dụng giúp người dùng nâng cao nhận thức, tìm hiểu kỹ năng sơ cứu ban đầu và tra cứu nội dung có nguồn.

Hệ thống cung cấp bài học theo các tình huống thường gặp, kết hợp hướng dẫn bằng chữ và nội dung trực quan. Trợ lý AI đa phương thức kết hợp RAG hỗ trợ câu hỏi bằng văn bản và hình ảnh, trả lời dựa trên tài liệu tham khảo.

FirstAid phục vụ học tập và tra cứu. Ứng dụng không thay thế nhân viên y tế hoặc dịch vụ cấp cứu chuyên nghiệp.

## Phạm vi

- 18 nhóm tình huống. Nội dung áp dụng cho người lớn và trẻ em, không bao gồm nhũ nhi.
- Bài học, phân nhóm, tìm kiếm, đọc đầy đủ và tra cứu theo bước từ cùng nội dung.
- Hình minh họa có mô tả thay thế và quyền sử dụng rõ ràng.
- Bài học và thông tin nguồn đọc được ngoại tuyến.
- Hỏi đáp RAG bằng văn bản hoặc câu hỏi kèm một ảnh, có dẫn nguồn và xử lý thiếu bằng chứng.
- Admin quản lý danh mục, bài học, nguồn và hình gắn với bài.
- Cập nhật bộ nội dung thủ công, giữ bản local khi lỗi.
- Người dùng mobile không cần tài khoản.

Không có quiz, bài kiểm tra, chấm điểm hoặc chứng nhận. Không có danh bạ cơ sở y tế, bản đồ, định vị hoặc chỉ đường. Không có chẩn đoán bằng ảnh, kê đơn, hồ sơ bệnh nhân, giọng nói hoặc điều phối cấp cứu.

## Nguyên tắc

Ảnh người dùng là đầu vào cho câu hỏi học tập, không phải bằng chứng để xác định bệnh hoặc mức độ thương tích. Câu trả lời y khoa cần được tài liệu truy xuất hỗ trợ. Hệ thống hỏi lại hoặc từ chối khi không đủ thông tin.

Điểm nguồn hiển thị tên tài liệu, đơn vị biên soạn và năm. Trang PDF và vị trí trích dẫn phục vụ kiểm tra nội bộ. Không tuyên bố có thẩm định chuyên gia khi đồ án chỉ đối chiếu tài liệu.

## Đặc tả

- [Phạm vi và yêu cầu](baseline-v2/01_SYSTEM_SPEC.md).
- [Thiết kế](baseline-v2/02_FIGMA_DESIGN_BRIEF.md).
- [Hợp đồng dữ liệu](baseline-v2/06_SHARED_CONTRACTS.md).
- [Danh mục nội dung](baseline-v2/07_CONTENT_CATALOG.md).
- [Nghiệm thu](baseline-v2/08_ACCEPTANCE_AND_PLAN.md).
