# FirstAid Admin

Web quản trị dùng React, TypeScript và Vite. Bốn mục chính gồm bài sơ cứu, danh mục, nguồn tài liệu và cơ sở y tế.

API dùng [contract chung](../docs/baseline-v2/06_SHARED_CONTRACTS.md). Web không tạo tài khoản mobile, tải PDF hoặc huấn luyện AI.

## Chạy local

Yêu cầu Node.js từ 22.12 và npm. Cài đúng phiên bản trong `package-lock.json`:

```powershell
cd admin
npm.cmd ci
```

Để xem và thử giao diện độc lập:

```powershell
npm.cmd run dev:demo
```

Mở <http://127.0.0.1:5173>. Đăng nhập bằng tên `demo` và mật khẩu `demo`.

Chế độ demo có banner riêng. Bộ bài và nguồn lấy từ thư viện tham khảo của dự án. Danh bạ khởi tạo rỗng. Thay đổi chỉ nằm trong bộ nhớ của tab và mất khi tải lại. Demo không ghi backend, SQLite hoặc dữ liệu mobile.

## Nối backend

1. Sao chép `.env.example` thành `.env.local`.
2. Đặt `API_PROXY_TARGET` thành địa chỉ Spring Boot của bạn.
3. Chạy lệnh sau:

```powershell
npm.cmd run dev
```

Web gọi `/api/v1/admin` qua proxy cùng origin. Chế độ thường không tự chuyển sang demo khi API lỗi.

Backend cần cung cấp các endpoint trong mục 8 của contract. Các yêu cầu tích hợp:

| Nhóm | Web gửi / nhận | Backend chịu trách nhiệm |
| --- | --- | --- |
| Phiên | `GET /auth/me`, `credentials: include` | Session ADMIN, cookie HttpOnly, Secure trên HTTPS và SameSite phù hợp |
| CSRF | `GET /auth/csrf`, đọc `token` và `header_name`; gửi header cho mọi request ghi | Kiểm CSRF cả login/logout; cấp lại token sau login |
| CRUD | JSON snake_case; list có `items`, `page`, `page_size`, `total` | Validation, phân quyền và lưu dữ liệu |
| Bài | Full nested steps/references; PUT gửi `expected_revision` | Tăng revision, phát hiện 409 và quản lý trạng thái |
| Xác nhận | Gửi `content_checked` | Ghi `checked_at`; sửa bài public về DRAFT và xóa xác nhận cũ |
| Xuất bản | POST publish/unpublish kèm `expected_revision` | Kiểm đủ điều kiện, nguồn active và cập nhật public data version |
| Xóa | DELETE; nhận 204 hoặc lỗi `RESOURCE_IN_USE` | Chặn liên kết mồ côi trong transaction |
| Lỗi | Đọc `error.code`, `message`, `field_errors` | Trả đúng HTTP status và envelope theo contract |

Web giữ bản nhập khi hết phiên, lỗi mạng, CSRF hoặc xung đột. Người dùng đăng nhập lại hoặc làm mới CSRF rồi chủ động thử lại. Web không tự gửi lại request ghi.

Không lưu mật khẩu, session token hoặc CSRF token vào localStorage. Token CSRF chỉ nằm trong bộ nhớ. Backend phải tự thực thi các ràng buộc; kiểm tra frontend không thay thế kiểm tra server.

## Biên tập nội dung

1. Mở **Bài sơ cứu** và chọn **Tạo bài sơ cứu** hoặc mở một bài.
2. Nhập định danh, đối tượng và phạm vi theo nguồn.
3. Nhập các section, bước và tham chiếu.
4. Dùng nút lên/xuống để đổi thứ tự bước.
5. Kiểm tra panel **Xem trước nội dung**.
6. Chọn **Lưu bản nháp**.
7. Đối chiếu bản cuối với tài liệu và lưu xác nhận nội dung.
8. Chọn **Xuất bản** và xác nhận.

Lưu sửa bài đã xuất bản sẽ đưa bài về nháp và xóa xác nhận trước đó. Web cảnh báo trước khi lưu. Người biên tập phải đối chiếu, lưu xác nhận và xuất bản lại.

Nguồn PDF cần trang trích trong giới hạn tài liệu. Nguồn WEB dùng URL HTTPS và trang null. Preview chỉ hiện tên tài liệu, đơn vị và năm trong phần nguồn dành cho người đọc. Hình bundled được hiển thị trong mobile; preview Admin hiển thị mô tả và asset key.

Cơ sở y tế mới mặc định ngừng sử dụng. Chỉ bật sử dụng sau khi nhập thông tin liên hệ, tọa độ, nguồn và ngày xác minh. Giá trị cấp cứu 24/7 **Chưa xác minh** luôn hợp lệ.

## Kiểm tra và build

```powershell
npm.cmd test
npx.cmd playwright install chromium
npm.cmd run test:e2e
npm.cmd run build
```

Test browser dùng demo local theo contract. Test không chứng minh tích hợp với database thật hoặc chuỗi Admin đến mobile.

Build nằm trong `dist/`. Phục vụ web và `/api` cùng origin qua HTTPS trong môi trường triển khai. Cấu hình fallback về `index.html` cho đường dẫn web. Không triển khai Vite dev server lên production.

Chế độ demo chỉ được nạp khi `import.meta.env.DEV` và `VITE_DEMO=true`. Bản production không chứa adapter demo hoặc thư viện fixture.

## Xử lý lỗi

| Thông báo | Cách tiếp tục |
| --- | --- |
| Không kết nối được máy chủ | Kiểm tra backend và proxy. Giữ tab đang nhập rồi thử lại. |
| Phiên hết hạn | Đăng nhập lại trong hộp thoại. Nội dung đang nhập được giữ trong tab. |
| CSRF thay đổi | Chọn **Làm mới phiên**, sau đó thử lại thao tác. |
| Xung đột nội dung | Sao chép phần cần giữ, rồi chọn **Tải bản mới** để đối chiếu thủ công. |
| Dữ liệu còn được tham chiếu | Xử lý bài liên quan trước khi xóa hoặc ngừng sử dụng. |
| Không đủ điều kiện xuất bản | Sửa các trường được liệt kê, lưu và thử lại. |

Khi tải lại hoặc đóng tab, nội dung chưa lưu sẽ mất. Trình duyệt cảnh báo nếu đang có thay đổi chưa lưu.
