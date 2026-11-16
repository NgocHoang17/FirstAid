# Danh bạ thí điểm Đà Nẵng

Mã vùng dùng chung là `VN-DN`. Đây là mã nghiệp vụ của dự án, không phải tuyên bố mã hành chính chuẩn. Bộ dữ liệu chọn một số cơ sở trong khu vực đô thị Đà Nẵng, không đại diện toàn bộ thành phố.

`danang.json` lưu payload cơ sở và bằng chứng đối chiếu riêng. Phần `evidence` phục vụ người quản trị. Không gửi phần này vào API Facility hoặc hiển thị nguyên văn trong app. `verification_note` cho người dùng biết loại số liên hệ và giới hạn thông tin.

Nguồn gồm [danh bạ 1022 Đà Nẵng](https://1022.vn/benh-vien-trung-tam-y-te/), [Bệnh viện C](https://bvcdn.org.vn/), [Bệnh viện Quân y 17](https://benhvienquany17.com/) và [trang liên hệ FAMILY](https://familyhospital.vn/lien-he/). Ngày và phương pháp kiểm nằm trong dữ liệu. Việc đối chiếu website không tương đương gọi điện xác nhận hoặc khảo sát thực địa.

## Kiểm tra và nhập dữ liệu

Chạy tại thư mục gốc repository:

```powershell
python tools/validate_facilities.py
python tools/validate_facilities.py --export-admin tmp/danang-admin.json
```

Script không gọi API và không ghi database. Tệp xuất là mảng payload cho các request tạo riêng lẻ. API không có endpoint import hàng loạt.

1. Kiểm lại các URL và dữ liệu trước khi nhập môi trường sử dụng chung.
2. Đăng nhập web Admin, mở Cơ sở y tế.
3. Kiểm tra danh sách để tránh tạo trùng cùng tên và địa chỉ.
4. Nhập từng payload theo contract Facility.
5. Giữ `is_active=false` cho mục có công việc xác minh chưa xong.
6. Ghi nhận UUID do server trả về nếu cần cập nhật lại bằng API.
7. Đặt `PUBLIC_REGION=VN-DN` trong môi trường backend.
8. Chạy mobile với profile Đà Nẵng và cập nhật nội dung.

Từ thư mục `mobile/`:

```powershell
flutter run --dart-define-from-file=config/danang.example.json
```

Profile dùng địa chỉ máy phát triển nhìn từ Android emulator. Khi chạy điện thoại thật, đổi API URL sang địa chỉ máy chủ truy cập được. Dùng HTTPS cho release.

## Duy trì dữ liệu

Người quản trị danh bạ của nhóm phụ trách kiểm lại thông tin trước nghiệm thu, trước phát hành và khi nhận phản ánh sai. Chưa chỉ định cá nhân; nhóm phân công người chịu trách nhiệm khi triển khai.

Chỉ dùng YES/NO cho cấp cứu 24/7 khi có bằng chứng rõ. Giờ khám hành chính không chứng minh không có cấp cứu 24/7. Giữ UNKNOWN khi chưa xác minh. Không thay số cơ sở bằng 115. Tọa độ là vị trí cơ sở, không mô tả cổng cấp cứu hoặc khả năng tiếp nhận hiện tại.

Giữ inactive khi có liên kết sai, địa chỉ mâu thuẫn hoặc thiếu tọa độ. Sau khi kiểm lại, cập nhật evidence và ngày xác minh trước khi kích hoạt. Kiểm thử tải, lưu ngoại tuyến, gọi và mở bản đồ sau khi nhập. Khoảng cách đường thẳng không phải thời gian di chuyển.
