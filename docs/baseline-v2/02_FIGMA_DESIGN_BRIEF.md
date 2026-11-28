# Figma Design Brief

Baseline 2.0 | Đầu vào thiết kế, không phải yêu cầu chỉnh một file Figma cụ thể. Đọc [01_SYSTEM_SPEC.md](01_SYSTEM_SPEC.md), [06_SHARED_CONTRACTS.md](06_SHARED_CONTRACTS.md) và [07_CONTENT_CATALOG.md](07_CONTENT_CATALOG.md).

## 1. Mục tiêu thiết kế

Thiết kế mobile FirstAid dễ tìm, dễ đọc và ít thao tác trong tình huống căng thẳng; đồng thời có giao diện học kiến thức, hỏi đáp bằng văn bản hoặc câu hỏi kèm hình ảnh. Thiết kế thêm web Admin vừa đủ cho CRUD, không làm dashboard bệnh viện hoặc workflow quản trị nhiều vai trò.

Người dùng không đăng nhập. Không thiết kế màn hình đăng ký, hồ sơ cá nhân, hồ sơ nạn nhân, bảng thành tích, quiz, camera, voice recording, thông báo đẩy hay điều xe. Không đưa các tính năng ngoài scope vào mockup chỉ để lấp chỗ trống.

## 2. Đầu ra Figma cần có

- Page `00 Cover and flows`: phạm vi và sơ đồ điều hướng.
- Page `01 Foundations`: màu, chữ, spacing, icon và trạng thái.
- Page `02 Components`: component và variants thực sự được dùng.
- Page `03 Mobile`: màn hình happy path và các trạng thái quan trọng.
- Page `04 Admin`: quản lý nội dung, hình và nguồn.
- Page `05 Handoff`: mapping screen → FR → API/data, ghi chú responsive và prototype.

Dùng Auto Layout, constraints và component variants; không dựng mỗi màn hình bằng một ảnh phẳng. Nội dung và nút phải chỉnh sửa được. Brief này không yêu cầu tạo design system lớn hay variable modes phức tạp.

## 3. Phong cách và nền tảng

Phong cách rõ ràng, tin cậy, nhẹ, ưu tiên chữ và hình hướng dẫn. Nền xanh lam rất nhạt, xanh biển đậm tạo cấu trúc và điều hướng, xanh ngọc nhấn icon và lựa chọn. Đỏ dành cho hành động khẩn cấp. Header có thể dùng gradient xanh biển nhẹ; tránh ảnh nạn nhân gây sợ, banner marketing, gradient rực hoặc nhiều animation. Logo đơn giản có thể chỉ dùng chữ FirstAid và một biểu tượng trung tính.

Frame mobile chính 390 × 844; kiểm thêm 360 × 800 và màn hình lớn 430 × 932. Đây là vùng thiết kế logic, không đặt pixel cố định khi triển khai Flutter. Giữ safe area cho system bars. Khả năng tăng cỡ chữ và cuộn quan trọng hơn giữ mọi nội dung trong một màn hình.

Admin desktop 1440 × 900; kiểm tại 1280 px. Web Admin không bắt buộc thao tác hoàn chỉnh trên điện thoại trong P0, nhưng không vỡ layout ở tablet.

## 4. Foundations đề xuất

| Token | Giá trị gợi ý | Mục đích |
| --- | --- | --- |
| color/background | #ECF4F8 | Nền chung |
| color/surface | #FFFFFF | Card, sheet, form |
| color/text/primary | #153C4D | Chữ chính |
| color/text/secondary | #4D6878 | Nội dung phụ |
| color/primary | #005A78 | Điều hướng và hành động thường |
| color/primary-dark | #003F57 | Bottom navigation, header |
| color/accent | #27C8C5 | Điểm nhấn; dùng chữ/icon xanh đậm trên nền này |
| color/accent-soft | #D9F4F1 | Icon nền nhạt, lựa chọn |
| color/accent-ink | #005D62 | Chữ nhấn trên nền sáng |
| color/tint | #DCEEF5 | Khối nội dung phụ, hình minh họa |
| color/emergency | #B32F46 | Nút gọi trợ giúp |
| color/border | #CADFE8 | Border, divider |
| color/info-bg | #E1F3F5 | Trạng thái thông tin |
| color/warning-bg | #FFF0D6 | Lưu ý, dữ liệu cũ |

Đây là bảng màu đầu vào. Designer phải kiểm contrast của cặp foreground/background sử dụng thật; không mặc định mọi tổ hợp màu trong bảng đều đạt chuẩn. Warning luôn có icon/nhãn, không dùng riêng màu để truyền nghĩa.

Phân bổ theo hướng 60% nền sáng, 30% xanh biển và các khối hỗ trợ, 10% điểm nhấn xanh ngọc; điều chỉnh theo chức năng từng màn, không ép tỷ lệ diện tích cố định. Không dùng chữ trắng cỡ nhỏ trên xanh ngọc sáng. Khi phóng chữ lớn, thanh điều hướng có thể chuyển thành hai hàng để giữ nhãn đầy đủ và vùng chạm rõ ràng.

Font hỗ trợ tiếng Việt tốt, đề xuất Be Vietnam Pro hoặc font hệ thống phù hợp. Mobile: tiêu đề 24–28, section 20, body 16–18; quick steps ưu tiên 18–20; label 14–16. Tránh body dài 12 px. Line height 1.4–1.5. Spacing scale 4, 8, 12, 16, 24, 32. Vùng chạm tối thiểu đề xuất 48 × 48 logical pixels, có khoảng cách giữa các lựa chọn.

Bo góc card 12–16, button 10–12. Không biến mọi thông tin thành card lồng nhau; phần bước hướng dẫn nên có nhịp đọc rõ. Các đoạn y khoa dài dùng list/section, không ép thành dòng rất nhỏ.

## 5. Điều hướng

Ba tab: Trang chủ, Kiến thức, Hỏi đáp. Cài đặt trên app bar. Không có quiz, danh bạ, bản đồ, định vị hoặc chỉ đường.

## 6. Màn hình

| Màn hình | Thành phần |
| --- | --- |
| Trang chủ | Giới thiệu học tập, nhóm tình huống, lối tra cứu theo bước |
| Danh mục | Tìm kiếm, nhóm, đối tượng |
| Chọn bài | Nhãn người lớn/trẻ em/dùng chung và phạm vi |
| Bài học | Nhận biết, hướng dẫn, hình, điều tránh và nguồn |
| Theo bước | Tiêu đề, nội dung, hình trong cùng khối; trước/tiếp theo |
| Nguồn | Tên tài liệu, đơn vị biên soạn, năm |
| Hỏi đáp | Câu hỏi, chọn/bỏ ảnh, thumbnail, gửi, trạng thái và citation |
| Cài đặt | Nội dung ngoại tuyến và cập nhật thủ công |

Ảnh đi kèm câu hỏi do người dùng chọn chủ động. Thiết kế trạng thái chưa chọn, đang xử lý, file lỗi, ảnh mờ, thiếu bằng chứng và dịch vụ lỗi. Không thể hiện kết quả chẩn đoán, đánh giá độ nặng hoặc suy tuổi từ hình.

## 7. Admin

Ba menu Bài sơ cứu, Danh mục và Nguồn tài liệu. Form bài có bước, chọn hình và tham chiếu. Preview dùng cùng dữ liệu với mobile. Lưu nháp, xuất bản và gỡ xuất bản cần diễn giải tác động rõ ràng. Chỉ một role ADMIN.

## 8. Handoff và nghiệm thu

Map component vào [06](06_SHARED_CONTRACTS.md). Giữ chữ khi hình không tải được. Kiểm 320–430 px, chữ 200%, bàn phím, screen reader và safe area. Hình nhắc nhớ không được trình bày như tranh hướng dẫn tư thế thao tác.

Prototype nối từ nhóm bài tới nội dung/nguồn, từ câu hỏi có ảnh tới phản hồi/citation, từ offline tới bài local. Không thêm tính năng ngoài [01](01_SYSTEM_SPEC.md).
