# Backend Implementation Guide

## 1. Trách nhiệm

Spring cung cấp API nội dung học tập, nguồn, Admin, snapshot và gateway AI. PostgreSQL lưu Category, Article, Step, Source, SourceReference, AdminUser. Không có chức năng danh bạ hoặc dữ liệu định vị trong mô hình sản phẩm.

## 2. Nội dung và quản trị

Public chỉ trả bài đã xuất bản và nguồn đang dùng. Admin dùng session cookie, CSRF và một role ADMIN. Kiểm đầu vào và revision trước cập nhật. Validate đối tượng, thứ tự bước và tham chiếu trước publish. Không coi validation là thẩm định y khoa.

Xóa hoặc gỡ nguồn phải bảo vệ liên kết và chặn citation cũ không còn hợp lệ. Corpus phải được cập nhật theo revision nội dung.

## 3. Snapshot

Snapshot giáo dục gồm danh mục, bài, nguồn, cấu hình và version. Không phân vùng địa lý. Schema được version hóa; không thay payload v1 làm ứng dụng đã phát hành mất khả năng đọc. Phương án chuyển đổi nằm trong [06](06_SHARED_CONTRACTS.md).

## 4. Gateway đa phương thức

Văn bản dùng JSON. Câu hỏi kèm ảnh dùng multipart theo [06](06_SHARED_CONTRACTS.md). Kiểm file thực tế bằng bộ giải mã, không chỉ kiểm extension hoặc MIME do client cung cấp.

Giới hạn một JPEG/PNG, 5 MiB, 16 megapixel. Loại metadata không cần thiết. Không nhận URL ảnh tùy ý và không tải URL do người dùng cung cấp. Không ghi request body, ảnh, văn bản trích hoặc thông tin cá nhân vào log.

FastAPI chỉ truy cập nội bộ. Token và provider secret nằm ở server. Giới hạn kích thước, tốc độ, đồng thời, thời gian và thời hạn file tạm. Dọn file khi thành công, lỗi hoặc timeout.

## 5. Bàn giao và migration

Backend do thành viên phụ trách thực hiện. Tài liệu đặc tả không đồng nghĩa endpoint đã triển khai.

- Gỡ public/Admin API danh bạ và quyền truy cập tương ứng.
- Tạo migration tiến về trước. Không sửa Flyway migration đã áp dụng.
- Không tự xóa dữ liệu trong database đang chạy. Sao lưu và chốt chuyển đổi trước thao tác loại bảng.
- Cung cấp snapshot giáo dục, giữ v1 trong giai đoạn client chuyển đổi.
- Triển khai gateway ảnh và kiểm tích hợp với dịch vụ đa phương thức thật.

## 6. Kiểm thử

Auth/CSRF, public không lộ draft, revision conflict, publish, ETag/304, snapshot nhất quán, nguồn stale, file giả MIME, file quá lớn, ảnh giải nén quá mức, timeout và dọn file tạm.
