# Acceptance Criteria and Implementation Plan

## 1. Mục tiêu nghiệm thu

FirstAid phục vụ giáo dục sơ cứu ngoại viện, bài học trực quan và hỏi đáp RAG bằng văn bản/hình ảnh. Không có quiz, danh bạ, bản đồ hoặc GPS.

## 2. Các gói công việc

1. Chốt đặc tả, nội dung và nguồn của 18 nhóm tình huống.
2. Hoàn thiện bài học và tra cứu theo bước, hình có mô tả và quyền sử dụng.
3. Hoàn thiện Admin nội dung, database và snapshot giáo dục.
4. Triển khai RAG văn bản, nguồn và chính sách không trả lời.
5. Triển khai xử lý ảnh thật, giao diện chọn ảnh và gateway.
6. Kiểm tích hợp, accessibility, bảo mật, hiệu năng và phát hành.

Backend và migration do thành viên backend phụ trách. Không coi giao diện chọn ảnh hoặc API nhận file là hoàn thành AI đa phương thức.

## 3. Tiêu chí

| Mã | Điều kiện nghiệm thu |
| --- | --- |
| EDU-T01 | Cài mới, không mạng: mở được các nhóm bài, hình và metadata nguồn |
| EDU-T02 | Tìm không dấu và lọc đối tượng cho kết quả phù hợp |
| EDU-T03 | Đọc đầy đủ và từng bước dùng cùng nội dung, hình thuộc đúng bước |
| EDU-T04 | Không có menu, route danh bạ, bản đồ hoặc yêu cầu quyền vị trí |
| EDU-T05 | Không có quiz, chấm điểm hoặc chứng nhận |
| EDU-T06 | Admin auth/CSRF, revision, nháp/xuất bản và kiểm nguồn hoạt động |
| EDU-T07 | Cập nhật nguyên tử, ETag/304 và giữ bài khi lỗi hoặc đang đọc |
| EDU-T08 | Hỏi văn bản: citation đúng nguồn/revision và hỗ trợ câu trả lời |
| EDU-T09 | Chọn/bỏ ảnh, xem trước, giới hạn file và xử lý thất bại rõ ràng |
| EDU-T10 | Ảnh thật đi qua OCR/thị giác, retrieval và phản hồi có bằng chứng |
| EDU-T11 | Ảnh mờ, ảnh ngoài phạm vi và thiếu bằng chứng không tạo khẳng định giả |
| EDU-T12 | Chỉ thị trong ảnh không thay đổi chính sách hoặc truy cập dữ liệu |
| EDU-T13 | Không lưu ảnh/chat mặc định; file tạm được dọn sau timeout và lỗi |
| EDU-T14 | Màn 320–430 px, chữ 200%, nhãn và vùng chạm còn dùng được |
| EDU-T15 | Nguồn bị gỡ hoặc đổi revision không được mở như bằng chứng còn hiệu lực |
| EDU-T16 | APK ký riêng, thiết bị đích và bộ chạy local được nghiệm thu |

## 4. Đo và bàn giao

Ghi phần cứng, version model/corpus, tập câu hỏi và ảnh kiểm. Báo độ trễ p50/p95 và chất lượng bằng chứng riêng cho văn bản và ảnh. Không thay kết quả đo bằng số ước lượng.

Bàn giao source, hướng dẫn chạy, cấu hình mẫu không secret, tài liệu nguồn, quyền sử dụng hình, contract, báo cáo test và giới hạn đã biết. Tiến độ ghi ở task/PR hoặc checklist local, không ghi vào đặc tả sản phẩm.
