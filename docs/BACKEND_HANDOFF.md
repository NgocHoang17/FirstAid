# Bàn giao backend FirstAid

Mốc đối chiếu mã nguồn ngày 22/11/2026. Người nhận là thành viên phụ trách Spring Boot và PostgreSQL. Dùng tài liệu này để giao việc. Ghi kết quả từng hạng mục trong PR. Đặc tả sản phẩm và hợp đồng API dùng chung nằm ở [01](baseline-v2/01_SYSTEM_SPEC.md) và [06](baseline-v2/06_SHARED_CONTRACTS.md).

## Điểm bắt đầu

| Thành phần | Căn cứ bàn giao |
| --- | --- |
| Spring và PostgreSQL | Public API nội dung, auth Admin, CRUD, upload ảnh bước, snapshot v1 và gateway chat văn bản đã có mã triển khai. Flyway dùng V1–V3. [Hướng dẫn backend](../backend/README.md) |
| Flutter | Đọc snapshot v1/v2. Mặc định gọi v1, gửi thêm `schema_version=2` khi bật `FIRSTAID_SNAPSHOT_V2`. Có giao diện chọn ảnh và gửi multipart qua Spring. [Hướng dẫn mobile](../mobile/README.md) |
| FastAPI | Đọc snapshot public v1/v2. Có endpoint ảnh nội bộ và bộ kiểm ảnh không dùng khóa. Dịch vụ local mặc định trả lời văn bản bằng nội dung trích xuất. [Hướng dẫn AI](../ai/README.md) |

## BE-01. Snapshot giáo dục v2

**Người phụ trách** · Backend. Phối hợp với mobile và AI khi mở phiên bản mới.

1. Bổ sung chọn schema trong `OfflineController`. Giữ v1 cho request không chỉ định phiên bản. V1 tiếp tục nhận `region_code`. V2 cho phép bỏ tham số này, đồng thời chấp nhận request từ Flutter vẫn gửi mã vùng cũ.
2. Trả v2 theo mục 6 của hợp đồng. Dùng cùng nguồn dữ liệu public, giới hạn và transaction `REPEATABLE_READ`. Giữ thứ tự bước, ID, revision, tham chiếu và metadata gallery.
3. Sinh `data_version` riêng theo schema. Đồng bộ ETag với token trong payload theo quy tắc của client. Không cắt âm thầm danh sách khi vượt giới hạn.
4. Sau nghiệm thu, chuyển cấu hình mobile và `AI_PUBLIC_SNAPSHOT_URL` sang v2. Cập nhật launcher, công cụ seed và test tích hợp cùng đợt chuyển.

**Nghiệm thu:** v1 và v2 cho cùng danh sách bài hợp lệ. V2 bỏ `region_code` và `facilities` trong payload. Gửi ETag v1 sang v2 nhận 200. Gửi lại ETag của cùng bản v2 nhận 304 với body rỗng. Xuất bản, sửa bài đã xuất bản và gỡ bài làm thay đổi snapshot. Kiểm nâng cấp từ SQLite đã có v1 và khởi động lại app sau khi nhận v2. FastAPI đổi corpus và gateway từ chối citation của revision đã gỡ. [Hợp đồng snapshot](baseline-v2/06_SHARED_CONTRACTS.md#6-offlinesnapshot-giáo-dục)

## BE-02. Gateway hỏi đáp bằng ảnh

**Người phụ trách** · Backend. AI phụ trách đánh giá Gemini sau khi gateway hoạt động.

1. Thêm `POST /api/v1/assistant/query-with-image` vào `AssistantController`. Sửa `SecurityConfig` để cho phép đúng POST này và miễn CSRF theo cách của chat văn bản. Giữ nguyên quyền và CSRF của Admin.
2. Tách phần kiểm câu hỏi, giới hạn yêu cầu, chính sách sự cố và kiểm phản hồi để dùng chung trong `AssistantService`. Chuyển `client_request_id` sang `request_id` trong part JSON nội bộ.
3. Chuyển đúng hai part `request` và `image` đến `POST /internal/v1/query-with-image`. Spring gắn `X-Internal-Token`. Giới hạn một JPEG/PNG, 5 MiB, tối đa 16 megapixel khi giải mã. FastAPI giải mã, kiểm định dạng và loại metadata trước khi gọi Gemini.
4. Map 400, 413 và 415 thành envelope lỗi public. Áp dụng giới hạn tốc độ và thời gian trong hợp đồng. Khi provider lỗi hoặc hết hạn, trả trạng thái `unavailable` theo quy tắc chung. Dọn ảnh tạm khi kết thúc request.

**Nghiệm thu không cần khóa:** gửi multipart từ Flutter qua Spring hoặc fixture HTTP. Kiểm ảnh trắng, part bị thiếu/trùng, MIME không hợp lệ, file quá giới hạn, upstream timeout, request ID sai và citation đã cũ. Xác nhận lỗi hiển thị đúng trên mobile và Admin vẫn yêu cầu CSRF. Dùng stub nội bộ cho ca `answered` có nguồn và ca sai đối tượng.

**Nghiệm thu với Gemini:** chạy bộ ca ảnh, kiểm phản hồi tiếng Việt và nguồn ở luồng mobile → Spring → FastAPI. Đo độ trễ và kiểm chính sách cho ảnh mờ, ảnh ngoài phạm vi, chỉ thị trong ảnh và yêu cầu suy đoán tuổi hoặc chẩn đoán. Khóa thuộc môi trường AI. [Hợp đồng multipart](baseline-v2/06_SHARED_CONTRACTS.md#91-câu-hỏi-kèm-hình-ảnh) · [Bộ đánh giá ảnh](../ai/evaluation/image_cases.py)

## BE-03. Loại bỏ danh bạ khỏi Spring

**Người phụ trách** · Backend. Làm sau khi có phương án tương thích BE-01.

1. Gỡ public/Admin routes `/facilities` ở `PublicController` và `AdminContentController`. Gỡ truy vấn và hàm chuyển đổi bản ghi ở `CatalogService` và `Rows` khi hết nơi gọi.
2. Chốt với nhóm việc giữ dữ liệu cũ. Xuất bản sao lưu và kiểm khôi phục trên DB thử trước migration. Giữ nguyên checksum migration V1–V3. Tạo migration tiếp theo sau khi nhóm duyệt phương án dữ liệu.
3. Giữ trường `facilities: []` trong v1 để client cũ đọc được sau khi backend ngừng cung cấp danh bạ. Bỏ truy vấn danh bạ khỏi snapshot ở cùng đợt chuyển đổi.

**Nghiệm thu:** chạy Flyway trên DB mới và DB nâng từ V3 có dữ liệu. Kiểm các bài, bước, nguồn, media, tài khoản Admin và phiên bản nội dung. Các route danh bạ không còn trả dữ liệu. Mobile cài mới và mobile đã có cache đều đọc được bài học. [Thiết kế và migration](DATABASE_DESIGN.md)

## BE-04. Kiểm tích hợp trên môi trường riêng

1. Tạo DB thử với cấu hình tại [README backend](../backend/README.md). Chạy kiểm tra Maven, sau đó kiểm đăng nhập, CSRF, cập nhật xung đột, publish/unpublish, quyền đọc ảnh và ETag.
2. Dùng `tools/tests/test_step_media_live.py` trên backend thử để tạo hai snapshot trước và sau khi gỡ bài. Đặt `FIRSTAID_MEDIA_TEST_URL` gồm prefix `/api/v1`. Cấp `FIRSTAID_MEDIA_TEST_USER` và `FIRSTAID_MEDIA_TEST_PASSWORD` cho DB thử. Dùng cùng đường dẫn tuyệt đối trong `FIRSTAID_TEST_SNAPSHOTS` để xuất fixture từ Python và đọc bằng `mobile/test/publication_sync_test.dart`.
3. Kiểm lệnh smoke backend khi đổi snapshot. Script `backend/scripts/smoke.ps1` hiện gửi mã vùng `VN-PILOT`. Khi chạy fixture cũ, đặt `PUBLIC_REGION=VN-PILOT` trên backend thử. Khi nâng script theo v2, kiểm cả đường dẫn v1.
4. Ghi trong PR phiên bản Flyway, cách tái hiện, môi trường kiểm thử, kết quả và bước chuyển cấu hình.

## Phối hợp với các phần khác

| Chủ trì | Việc còn lại |
| --- | --- |
| AI | Kiểm Gemini thật cho văn bản và ảnh khi có khóa. Ghi chất lượng, p50/p95 và chi phí. Bộ hồi quy local phục vụ kiểm phần mềm, còn chất lượng Gemini cần đo bằng API thật. |
| Mobile | Kiểm v2 và hỏi đáp ảnh theo API mới trên Android Emulator Windows. Bao phủ mạng lỗi, quay lại bài học khi dịch vụ không khả dụng và chữ 200% theo tiêu chí nghiệm thu. |
| Nội dung | Bổ sung hình hướng dẫn có nguồn và quyền sử dụng cho các bước cần minh họa. Duy trì việc đối chiếu nguồn khi dữ liệu thay đổi. |
| Phát hành | Chốt môi trường triển khai khi cần sử dụng ngoài máy phát triển. Android Emulator là môi trường demo hiện tại. |
