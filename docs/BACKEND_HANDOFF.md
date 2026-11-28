# Bàn giao backend và kiểm tích hợp

Backend dùng Node.js + Express + PostgreSQL. API giữ prefix `/api/v1`; Admin React và mobile Flutter dùng cùng hợp đồng JSON. Hướng dẫn chạy tại [README gốc](../README.md#phát-triển-local), [backend](../backend/README.md), [mobile](../mobile/README.md) và [AI](../ai/README.md).

## Các luồng đã triển khai

| Luồng | Mã và cách phối hợp |
| --- | --- |
| Admin | Session PostgreSQL, cookie HttpOnly, CSRF trước thao tác ghi, CRUD bài/danh mục/nguồn, revision và publish/unpublish. Danh mục giới hạn FA01–FA18 giống mobile. Tìm danh mục/nguồn hỗ trợ không dấu và phân trang sau lọc. |
| Nội dung public | Chỉ xuất bài PUBLISHED đã kiểm, danh mục/nguồn còn active. Snapshot v1/v2 đọc cùng dữ liệu trong transaction REPEATABLE READ và có ETag riêng. |
| Mobile | Nhận snapshot qua Cài đặt → Kiểm tra cập nhật, kiểm schema/nguồn/ID rồi ghi SQLite nguyên tử. Hỏng bản cập nhật thì giữ bản hiện tại. |
| Ảnh bước | Upload JPEG/PNG, tối đa 5 MiB/16 MP. Backend chuẩn hóa ảnh và chỉ cho public đọc khi gắn bài public hợp lệ. Mobile nhận gallery xếp dọc, lưới hoặc vuốt ngang. |
| AI | Backend chuyển JSON hoặc multipart `request` + `image` tới FastAPI nội bộ, cùng token. Gateway kiểm lại citation và article/source revision trong PostgreSQL. |
| Migration | Runner Node.js thực thi V1–V4 trong `backend/db/migrations`. Nhận lịch sử Flyway V1–V3 khi checksum đúng; không sửa migration cũ. |

Các luồng có mã triển khai vẫn cần được kiểm cùng nhau trên môi trường đích. Test giả lập provider không xác nhận chất lượng Gemini thật.

## Chạy và cấu hình

```powershell
powershell -ExecutionPolicy Bypass -File tools/start-local.ps1
```

Mặc định launcher dùng PostgreSQL trong `backend/.env` nếu file có sẵn. Thêm `-PortableDatabase` để dùng database local riêng, hoặc `-SkipAi` khi chỉ cần API/Admin. Backend seed bộ bài khi bảng bài đang trống; giữ nội dung Admin đã chỉnh. Launcher duy trì token/session secret trong `.local/credentials.json` và không ghi đè `.env`.

Admin gọi API qua proxy, cấu hình `API_PROXY_TARGET`. Mobile emulator dùng `http://10.0.2.2:8080/api/v1`; điện thoại thật dùng IP LAN. Snapshot v1 cần `PILOT_REGION_CODE` trùng `PUBLIC_REGION` (mặc định `VN-DN`). Bật v2 bằng `FIRSTAID_SNAPSHOT_V2=true` khi cả môi trường đã sẵn sàng.

AI mặc định dùng trích xuất có nguồn, không cần provider cloud. Cấu hình Gemini và khóa chỉ ở server theo [Grounded Generation](../ai/GROUNDED_GENERATION.md). Dùng corpus từ snapshot backend đang phục vụ.

## Nghiệm thu trên môi trường riêng

1. Chạy unit test backend bằng `npm.cmd test`. Đặt `TEST_DATABASE_URL` trỏ database kiểm thử riêng và chạy `npm.cmd run test:integration` trong `backend/`. Bộ này tạo/xóa schema của chính nó để kiểm migration, seed, session/CSRF, xung đột, xuất bản, media, snapshot và gateway AI.
2. Chạy Admin thật bằng `npm.cmd run dev`; không dùng `dev:demo` để nghiệm thu kết nối PostgreSQL. Các ca Playwright mặc định dùng demo và chỉ xác minh giao diện.
3. Kiểm tạo bài nháp → lưu xác nhận → xuất bản → snapshot có bài → mobile nhận đúng revision. Sau đó gỡ bài, kiểm ETag đổi và mobile loại bài ở lần đồng bộ tiếp theo.
4. Chạy `tools/tests/test_step_media_live.py` trên backend kiểm thử đã seed. Đặt `FIRSTAID_MEDIA_TEST_URL` gồm `/api/v1`, `FIRSTAID_MEDIA_TEST_USER`, `FIRSTAID_MEDIA_TEST_PASSWORD` và `FIRSTAID_TEST_SNAPSHOTS` là đường dẫn xuất fixture. Bộ kiểm tạo bài riêng, kiểm ảnh trước/sau xuất bản và xuất snapshot trước/sau gỡ bài.
5. Truyền cùng `FIRSTAID_TEST_SNAPSHOTS` cho `flutter test test/publication_sync_test.dart`. Kiểm persistence SQLite bằng `flutter test test/snapshot_persistence_test.dart`. Android chạy toàn luồng qua `integration_test/real_data_test.dart`, cần emulator/thiết bị và backend/AI thật.
6. Gỡ bài hoặc đổi revision rồi kiểm gateway ngừng trả citation cũ. Với Gemini thật, kiểm thêm văn bản/ảnh, ảnh mờ/ngoài phạm vi, chỉ thị trong ảnh và ghi độ trễ p50/p95 theo [nghiệm thu](baseline-v2/08_ACCEPTANCE_AND_PLAN.md).

## Phần cần xác minh trước phát hành

- Luồng Android trên thiết bị đích, mất mạng, cập nhật khi đang đọc và chữ 200%.
- Chất lượng Gemini văn bản/ảnh bằng provider thật; bộ hồi quy phần mềm không thay kết quả đo này.
- HTTPS, proxy, cookie Secure, ký APK và cách sao lưu/khôi phục database của môi trường triển khai.
- Nguồn và quyền sử dụng ảnh, việc đối chiếu nội dung khi bài thay đổi.

Các route danh bạ/GPS không thuộc phạm vi hiện tại; dữ liệu legacy vẫn được giữ trong PostgreSQL. Không tự xóa bảng legacy khi triển khai.
