# Frontend Implementation Guide

## 1. Phạm vi

Mobile phục vụ học và tra cứu kiến thức sơ cứu cho người lớn, trẻ em. Không có quiz, danh bạ, bản đồ hoặc quyền vị trí. Dùng [01](01_SYSTEM_SPEC.md), [02](02_FIGMA_DESIGN_BRIEF.md), [06](06_SHARED_CONTRACTS.md) và [07](07_CONTENT_CATALOG.md).

## 2. Mobile

- Ba tab: Trang chủ, Kiến thức, Hỏi đáp. Cài đặt nằm trên app bar.
- Trang chủ ưu tiên nhóm bài và nội dung học tập. Lối tra cứu theo bước dùng chung Article.
- Tìm kiếm không dấu; bộ lọc nhóm và đối tượng; không tự thay bài theo tuổi.
- Bài có hình ngay sau hướng dẫn trong cùng khối của bước. Luôn giữ chữ khi hình lỗi.
- Đọc đầy đủ, theo bước và trang nguồn giữ trạng thái khi quay lại.
- Seed bài, hình và nguồn đi kèm ứng dụng. Không gọi AI để mở bài local.
- Cập nhật snapshot nguyên tử. Không đổi bài đang đọc giữa chừng.

## 3. Hỏi đáp đa phương thức

Màn hỏi đáp dùng bong bóng hội thoại, ô nhập cố định phía dưới, trạng thái đang trả lời và tự cuộn khi có tin mới. Người dùng hỏi tiếp trong phiên hoặc chọn Cuộc trò chuyện mới để xóa ngữ cảnh. Chỉ gửi tối đa bốn câu hỏi gần nhất theo contract; không lưu lịch sử mặc định. Citation được kiểm bên trong nhưng không hiển thị thành nút nguồn ở màn chat. Trang bài học và nguồn của bài vẫn hoạt động độc lập.

Người dùng nhập câu hỏi và tùy chọn một ảnh. Hiển thị ảnh thu nhỏ, nút bỏ ảnh, giới hạn dung lượng và trạng thái gửi. Chỉ gửi sau thao tác xác nhận của người dùng.

Kiểm JPEG/PNG, tối đa 5 MiB và 16 megapixel. Không hiển thị ảnh lỗi như đã gửi thành công. Không tự suy tuổi từ ảnh. Không tự gửi lại khi kết nối trở lại.

Thiếu bằng chứng, ảnh không rõ, ngoài phạm vi và lỗi dịch vụ phải có thông báo riêng. Giữ câu hỏi để sửa hoặc thử lại chủ động. Ảnh tạm được xóa khi bỏ ảnh, rời phiên hoặc hết thời hạn xử lý.

Không có đường truy cập nguồn qua citation thì không trình bày nguồn như đã xác minh. Nguồn hiển thị tên, đơn vị biên soạn, năm.

## 4. Admin

Ba menu: Bài sơ cứu, Danh mục, Nguồn tài liệu. Bài gồm bước, hình và tham chiếu. Admin dùng session và CSRF. Kiểm expected_revision, giữ bản nhập khi xung đột và xác nhận trước khi bỏ sửa đổi.

## 5. Nghiệm thu

Kiểm màn 320–430 px, chữ 200%, bàn phím, offline, hình lỗi, chọn/bỏ ảnh và không gửi lại ngầm. Quy trình hình ảnh chỉ được công bố sau khi gọi dịch vụ xử lý ảnh thật theo [06](06_SHARED_CONTRACTS.md).
