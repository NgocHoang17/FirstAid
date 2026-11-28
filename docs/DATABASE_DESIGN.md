# Thiết kế dữ liệu FirstAid

## Mô hình

Category phân loại Article theo 18 nhóm. Article có variant_key, age_group, trạng thái, revision và xác nhận kiểm biên soạn. Article sở hữu các Step và SourceReference theo thứ tự. Source lưu metadata nguồn, loại tài liệu, năm, revision và quyền sử dụng. AdminUser phục vụ quản trị một role.

Không có thực thể quiz, lượt thi, Facility, vị trí, hồ sơ bệnh nhân, hội thoại hoặc ảnh người dùng mặc định.

## Toàn vẹn

- UUID ổn định; code danh mục FA01–FA18; slug và biến thể không trùng.
- AgeGroup ADULT/CHILD/ALL; ALL chỉ dùng chung cho phạm vi người lớn và trẻ em.
- Bước liên tiếp từ 1, không trộn hai đối tượng có cách xử trí khác nhau.
- SourceReference giữ trang/section cho kiểm nội bộ, kiểm bounds với PDF.
- Chỉ bài hợp lệ, đã công bố và nguồn đang dùng được xuất public.
- expected_revision ngăn ghi đè bản sửa đồng thời.

## Ngoại tuyến

SQLite lưu metadata bộ hiện hành, danh mục, bài, bước, nguồn và tham chiếu. Assets hình đi kèm ứng dụng. Không lưu ảnh chat vào bộ nội dung ngoại tuyến.

Snapshot giáo dục schema 2 theo [06](baseline-v2/06_SHARED_CONTRACTS.md). Kiểm trước ghi, thay dữ liệu trong transaction, lỗi rollback. Client/server chuyển phiên bản có điều phối; không phá bộ đọc v1 khi backend chưa chuyển.

## SQL và migration

[PostgreSQL](database/001_postgresql_schema.sql) và [SQLite](database/002_sqlite_schema.sql) là SQL thiết kế cho cơ sở dữ liệu mới. Đây là lược đồ tham chiếu. Backend thực thi [migration Node.js](../backend/db/migrations); V1–V3 giữ tương thích checksum Flyway cũ. Flutter lưu snapshot JSON trong bảng SQLite `snapshot`. Lược đồ SQLite chuẩn hóa dùng để mô tả quan hệ dữ liệu.

Thành viên backend tạo migration tiến về trước, xử lý sao lưu và chuyển đổi API. Không sửa migration đã áp dụng hoặc xóa bảng/dữ liệu đang dùng một cách tự động.
