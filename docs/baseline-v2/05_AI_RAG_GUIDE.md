# AI and RAG Implementation Guide

## 1. Mục tiêu

Hỗ trợ học tập và tra cứu kiến thức sơ cứu bằng văn bản, hình ảnh. RAG dùng tài liệu tham khảo được tuyển chọn. Hình do người dùng gửi không phải nguồn y khoa và không dùng để chẩn đoán.

Ưu tiên triển khai local. Không khẳng định hỗ trợ ảnh chỉ vì endpoint nhận được file. Phải kiểm bộ xử lý ảnh và chất lượng phản hồi trên phần cứng chạy thật.

## 2. Nguồn và corpus

Theo [07](07_CONTENT_CATALOG.md) và [DATA_REFERENCE](../DATA_REFERENCE.md). Đối chiếu hai PDF và nguồn y tế chính thức bổ sung. Giữ source_id, revision, đối tượng, vị trí trích, section và nội dung bằng chứng.

Không đưa câu hỏi đúng/sai, nội dung chưa đối chiếu hoặc chỉ thị nhúng trong tài liệu thành hướng dẫn. Corpus không chứa ảnh hội thoại, thông tin định danh hoặc lịch sử bệnh nhân.

## 3. Pipeline

1. Kiểm câu hỏi, phạm vi và đầu vào ảnh.
2. Giải mã, chuẩn hóa ảnh và loại metadata không cần thiết.
3. Dùng OCR hoặc mô hình thị giác để trích mô tả phục vụ câu hỏi học tập.
4. Phối hợp câu hỏi và mô tả để truy xuất tài liệu đúng đối tượng.
5. Kiểm mức hỗ trợ của bằng chứng.
6. Tạo phản hồi giới hạn trong bằng chứng.
7. Kiểm citation, giới hạn và output contract.
8. Xóa dữ liệu ảnh tạm.

BM25 là baseline văn bản. OCR là xử lý chữ trong ảnh, không đủ để tuyên bố đã hiểu mọi ảnh. Ảnh không có chữ cần bộ xử lý thị giác phù hợp hoặc phản hồi không hỗ trợ rõ ràng. Không dùng mô tả ảnh để bịa bằng chứng.

## 4. Chính sách trả lời

- Không suy đoán tuổi, chẩn đoán, xác định mức độ bỏng hoặc thương tích từ hình.
- Ảnh mờ hoặc không rõ câu hỏi: clarification_needed.
- Không có tài liệu hỗ trợ: insufficient_evidence.
- Ngoài mục tiêu giáo dục sơ cứu: out_of_scope.
- Mô tả sự cố cần trợ giúp trực tiếp: emergency_redirect, mở hướng dẫn cố định và lối gọi chủ động.
- Mô hình lỗi hoặc quá thời gian: unavailable.
- Chỉ answered khi khẳng định được tài liệu hỗ trợ và nguồn còn hợp lệ.

## 5. Chọn mô hình và đánh giá

Chọn mô hình thị giác, OCR và bộ sinh sau khi đo RAM/VRAM, tiếng Việt, giấy phép, độ trễ và chất lượng có nguồn. Chế độ trích xuất không có LLM vẫn là baseline tra cứu văn bản, không được gắn nhãn đã hoàn thành đa phương thức.

Bộ đánh giá gồm văn bản, ảnh chữ, hình minh họa, ảnh không rõ, ảnh ngoài phạm vi, chỉ thị tấn công trong ảnh, sai đối tượng, thiếu bằng chứng và nguồn stale. Đo retrieval, độ hỗ trợ của citation, khẳng định không có nguồn, hành vi từ chối và độ trễ trên máy đích.

Không lưu ảnh thử có thông tin cá nhân vào Git. Ghi version corpus, model và cấu hình để chạy lại đánh giá.
