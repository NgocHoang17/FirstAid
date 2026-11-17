# Danh bạ thí điểm Đà Nẵng

Mã vùng dùng chung là `VN-DN`. Danh bạ bao phủ bệnh viện và trung tâm y tế có tiếp nhận người bệnh trong danh sách 1022 thành phố Đà Nẵng công bố ngày 29/08/2025. Phạm vi nguồn gồm khu vực trung tâm, Hội An, Điện Bàn, Tam Kỳ và các khu vực miền núi được liệt kê trong danh bạ thành phố.

Trường `coverage` ghi từng mục nguồn được đưa vào dữ liệu, tách cơ sở khi có nhiều địa chỉ, và lý do loại những đơn vị kiểm nghiệm hoặc pháp y. Các phòng khám tư và trạm y tế xã/phường ngoài danh sách nguồn cần được bổ sung từ danh mục chính thức tương ứng. Số lượng record và trạng thái hiện hành được script kiểm tra báo ra, cùng bằng chứng trong từng record.

`danang.json` lưu payload cơ sở và bằng chứng đối chiếu riêng. Phần `evidence` phục vụ người quản trị. Không gửi phần này vào API Facility hoặc hiển thị nguyên văn trong app. `verification_note` cho người dùng biết loại số liên hệ và giới hạn thông tin.

Nguồn chính là [danh bạ 1022 Đà Nẵng](https://1022.vn/benh-vien-trung-tam-y-te/). Các mục cần đối chiếu thêm dẫn tới website cơ sở hoặc Sở Y tế trong `contact_urls`. `directory_phone_text`, `directory_address` và `directory_map_url` giữ thông tin gốc để kiểm lại khi có mâu thuẫn. `listed_website_urls` là website do danh bạ giới thiệu, tách với những trang đã đọc để kiểm trong `contact_urls`.

Ngày và phương pháp kiểm nằm trong dữ liệu. Cơ sở active được đối chiếu thông tin liên hệ công khai và điểm bản đồ có nhãn phù hợp. Bằng chứng tọa độ ghi rõ lấy từ điểm địa điểm hoặc điểm hiển thị của iframe. Chưa có xác nhận qua điện thoại hoặc khảo sát thực địa. Bệnh viện chuyên khoa có thể chỉ tiếp nhận theo phạm vi chuyên môn; gọi cơ sở để hỏi nơi tiếp nhận phù hợp.

## Kiểm tra và nhập dữ liệu

Chạy tại thư mục gốc repository:

```powershell
python tools/validate_facilities.py
python tools/validate_facilities.py --export-admin tmp/danang-admin.json
```

Script không gọi API và không ghi database. Tệp xuất là mảng payload cho các request tạo riêng lẻ. API không có endpoint import hàng loạt.

Validator kiểm thêm tọa độ khớp điểm trong URL nguồn, tính đầy đủ của mapping danh bạ và số tổng đài 1900. Khi thay dữ liệu đã nhập, dùng UUID server để cập nhật bản ghi cũ, tránh tạo trùng các cơ sở đã có.

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
