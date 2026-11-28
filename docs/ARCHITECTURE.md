# Kiến trúc FirstAid

## Thành phần

| Thành phần | Trách nhiệm |
| --- | --- |
| Flutter | Bài học trực quan, tra cứu theo bước, nguồn và hỏi đáp văn bản/hình ảnh |
| SQLite và assets | Bài, bước, nguồn và hình thiết yếu để đọc ngoại tuyến |
| Spring Boot | Public API, Admin, validation, snapshot và gateway AI |
| PostgreSQL | Category, Article, Step, Source, SourceReference, MediaAsset và AdminUser |
| React Admin | Biên tập danh mục, bài học, hình và metadata nguồn |
| FastAPI RAG | Xử lý câu hỏi/ảnh, retrieval, phản hồi có nguồn và policy |

## Ranh giới

Mobile chỉ gọi Spring. FastAPI chỉ phục vụ mạng nội bộ. Secret của mô hình nằm ở server. Dữ liệu ảnh xử lý tạm thời, không có kho ảnh hội thoại mặc định.

Ứng dụng không có quiz, danh bạ, GPS, bản đồ hoặc hồ sơ bệnh nhân. Không tạo tài khoản mobile.

## Luồng dữ liệu

Admin biên tập và xuất bản bài có nguồn. Spring cung cấp snapshot đã validate. Mobile lưu snapshot nguyên tử và đọc local. Nhóm AI xây corpus có source_id/revision từ nội dung được phép sử dụng.

Với câu hỏi kèm ảnh, gateway kiểm file. AI xử lý ảnh để phục vụ retrieval, sau đó kiểm nguồn hỗ trợ phản hồi. Ảnh không thay thế bằng chứng y khoa.

## Tài liệu

Phạm vi theo [01](baseline-v2/01_SYSTEM_SPEC.md). Payload theo [06](baseline-v2/06_SHARED_CONTRACTS.md). Nội dung theo [07](baseline-v2/07_CONTENT_CATALOG.md). Backend do thành viên phụ trách triển khai và chuyển đổi theo [04](baseline-v2/04_BACKEND_GUIDE.md).
