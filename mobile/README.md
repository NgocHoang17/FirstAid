# FirstAid mobile

Flutter client dùng BLoC và SQLite, tổ chức theo feature với repository tách giao diện khỏi dữ liệu.

## Tài liệu

Đọc [README dự án](../README.md), [hướng dẫn đọc](../docs/baseline-v2/README.md), [đặc tả](../docs/baseline-v2/01_SYSTEM_SPEC.md) và [contract](../docs/baseline-v2/06_SHARED_CONTRACTS.md). Frontend đọc thêm [03](../docs/baseline-v2/03_FRONTEND_GUIDE.md), [brief thiết kế](../docs/baseline-v2/02_FIGMA_DESIGN_BRIEF.md) và [tiêu chí nghiệm thu](../docs/baseline-v2/08_ACCEPTANCE_AND_PLAN.md).

## Nguyên tắc

Không login mobile. Nội dung core bundled vào SQLite; quick/learn dùng cùng Article. Cập nhật full snapshot thủ công và không làm mất dữ liệu khi lỗi. Chat RAG text chỉ online; danh bạ vẫn xem được khi không cấp quyền vị trí. Không thay bài người lớn cho đối tượng khác khi thiếu bài phù hợp.

## Phát triển local

Dùng phiên bản Flutter/Dart tương thích cấu hình build và lockfile:

```powershell
flutter pub get
flutter run
```

API chính dùng prefix `/api/v1`; base URL lấy từ cấu hình môi trường. Android emulator truy cập máy phát triển qua `10.0.2.2`. Kiểm nghiệm offline, quyền vị trí, font lớn và external actions theo tài liệu nghiệm thu.

Truyền địa chỉ API gồm cả prefix khi chạy, ví dụ trên Android emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1 --dart-define=PILOT_REGION_CODE=VN-PILOT --dart-define="PILOT_REGION_LABEL=Khu vực thí điểm"
```

`PILOT_REGION_CODE` phải khớp vùng dữ liệu của máy chủ; `PILOT_REGION_LABEL` là tên vùng hiển thị. Bản release dùng API HTTPS. Khi không cấu hình API, các bài đã lưu vẫn đọc được; tính năng cần máy chủ hiển thị trạng thái chưa sẵn sàng.

Snapshot và danh bạ được lưu bằng SQLite trên Android/iOS. Cập nhật chỉ thay dữ liệu sau khi kiểm tra hợp lệ và ghi thành công. Danh bạ không kèm cơ sở minh họa; dữ liệu active cần được xác minh theo contract. Chat giữ câu hỏi trong bộ nhớ của phiên ứng dụng và không gửi lịch sử lên máy chủ.

## Bản đồ cơ sở y tế

Trong Cơ sở y tế, chọn **Danh sách** hoặc **Bản đồ**. Tìm kiếm áp dụng cho cả hai chế độ. Chạm ghim để xem thông tin, gọi cơ sở hoặc mở **Chỉ đường**. Bấm **Dùng vị trí hiện tại** để hiển thị vị trí vừa lấy; ứng dụng không theo dõi vị trí nền. Từ chối quyền vẫn xem được bản đồ cơ sở.

Ghim lấy từ danh bạ active đã tải vào thiết bị. Nhập dữ liệu theo [hướng dẫn Đà Nẵng](../data/facilities/README.md), sau đó tải danh bạ hoặc cập nhật snapshot trên app. File JSON trong repository không tự xuất hiện trên bản đồ khi chưa nhập và đồng bộ.

Nền bản đồ dùng `flutter_map` và OpenStreetMap, không cần API key. Khi mất mạng hoặc lỗi tile, chọn **Xem danh sách đã lưu**. Cache tile của thư viện phục vụ tải nền thông thường, không bảo đảm bản đồ offline. Giữ attribution và User-Agent của ứng dụng; không thêm tải tile hàng loạt. Kiểm [chính sách tile OSM](https://operations.osmfoundation.org/policies/tiles/) trước khi phát hành hoặc tăng quy mô sử dụng.

Kiểm thử bản đồ dùng tile giả lập, không gọi máy chủ bản đồ:

```powershell
flutter test --no-pub test/facilities_map_test.dart
```
