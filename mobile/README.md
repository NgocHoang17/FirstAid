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
