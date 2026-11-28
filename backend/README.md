# FirstAid backend — Node.js + PostgreSQL

Backend dùng Node.js 22.12+ (khuyến nghị Node 24 LTS), Express và PostgreSQL 15+. API vẫn ở `/api/v1`, cổng mặc định 8080. Mobile Flutter, React Admin và dịch vụ FastAPI giữ nguyên. Không cần Java hoặc Maven cho backend này.

Chọn PostgreSQL vì dự án đã dùng quan hệ Category → Article → Step/SourceReference, revision và giao dịch xuất bản. Giữ database này cho phép chuyển runtime mà vẫn giữ UUID, nội dung, media và mật khẩu bcrypt đã có. Không cần chuyển dữ liệu sang MongoDB.

## Cấu trúc thư mục

```text
backend/
├── src/
│   ├── app.js                   # Middleware và đăng ký route
│   ├── server.js                # Khởi động/dừng HTTP server
│   ├── config/                  # Biến môi trường và danh sách asset hợp lệ
│   ├── database/                # Pool, transaction, migration runner, bootstrap, seed
│   ├── modules/
│   │   ├── auth/                # Đăng nhập, session và CSRF
│   │   ├── catalog/             # Danh mục và nguồn tham khảo
│   │   ├── articles/            # Bài viết, bước và xuất bản
│   │   ├── media/               # Upload, chuẩn hóa và đọc ảnh
│   │   ├── snapshot/            # Snapshot offline v1/v2
│   │   └── assistant/           # Gateway AI văn bản/ảnh
│   └── shared/                  # Envelope, validation, lỗi và query parameters
├── db/
│   ├── migrations/              # SQL có phiên bản; giữ nguyên checksum
│   └── seeds/                   # SQL nhập nháp tùy chọn, không tự thực thi
├── scripts/
│   ├── database/                # CLI migrate và seed
│   └── smoke/                   # Kiểm API và gateway AI
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── helpers/
│   └── fixtures/                # HTTP server AI giả lập
├── .env.example
├── package.json
└── package-lock.json
```

Mỗi module có `*.routes.js` xử lý HTTP và `*.service.js` chứa logic nghiệp vụ; module `auth` gom session, middleware và route trong `auth.js`. Các route dùng chung kết nối transaction được tạo tại `app.js`. `src/database` chứa mã JavaScript làm việc với database; `db` chứa các tệp SQL. Script CLI chỉ đọc cấu hình và gọi mã trong `src`, kiểm thử dùng trực tiếp service và helper riêng.

## Chạy backend

Từ thư mục `backend` trong PowerShell:

```powershell
npm.cmd ci
Copy-Item .env.example .env
node -e "console.log(require('node:crypto').randomBytes(48).toString('hex'))"
```

Sửa `.env`: đặt `DATABASE_URL`, `DB_USER`, `DB_PASSWORD` theo PostgreSQL đang chạy; dán chuỗi vừa tạo vào `SESSION_SECRET`. Database phải tồn tại và user cần quyền tạo bảng. Đặt `ADMIN_SEED_USERNAME` và `ADMIN_SEED_PASSWORD` cùng nhau khi tạo Admin đầu tiên (12–72 ký tự, tối đa 72 byte UTF-8). Seed không thay mật khẩu của tài khoản đã tồn tại.

```powershell
npm.cmd run migrate
npm.cmd run seed
npm.cmd start
```

`start` cũng tự áp dụng migration trước khi mở HTTP. `seed` đọc bộ nội dung đã biên soạn trong `mobile/assets/content/`, giữ các ID và kiểm điều kiện xuất bản trong cùng giao dịch. Nếu database đã có bất kỳ bài viết nào, lệnh giữ nguyên dữ liệu, không nhập đè chỉnh sửa từ Admin. Chỉ chạy seed cho database mới cần bộ nội dung mẫu. Có thể chạy backend độc lập mà không seed; V2 chỉ tạo metadata danh mục/nguồn.

Kiểm nhanh: `http://127.0.0.1:8080/api/v1/categories`. Phát triển với tự tải lại: `npm.cmd run dev`.

## Nối các thành phần hiện có

- Admin: chạy `npm.cmd run dev` trong `admin`; proxy hiện tại đã trỏ cổng 8080. Đặt `ADMIN_ORIGIN=http://127.0.0.1:5173` khi dùng địa chỉ này, hoặc origin chính xác đang mở trên trình duyệt.
- Mobile: giữ URL debug `http://10.0.2.2:8080/api/v1` trên Android emulator. V1 mặc định dùng `PUBLIC_REGION=VN-DN`, khớp cấu hình mobile. Release dùng API HTTPS theo môi trường.
- FastAPI: chạy theo [README AI](../ai/README.md), đặt cùng `AI_INTERNAL_TOKEN` ở cả hai tiến trình. `AI_BASE_URL` là địa chỉ nội bộ. Gemini key chỉ thuộc tiến trình AI. Có thể đặt `AI_PUBLIC_SNAPSHOT_URL=http://127.0.0.1:8080/api/v1/offline-snapshot?schema_version=2` cho AI đồng bộ corpus.

**Launcher ở gốc `tools/start-local.ps1` / `tools/run_local.py` còn gọi Maven/JAR và yêu cầu JDK.** Các file ngoài backend được giữ nguyên theo phạm vi chuyển đổi. Dùng các lệnh riêng ở trên và hướng dẫn từng thành phần để chạy Node.js; launcher gốc không khởi động backend mới. Các tài liệu chung vẫn có thể gọi API là “Spring”; hợp đồng JSON và URL vẫn được giữ.

## Nâng cấp database từ Spring

1. Sao lưu database và dừng tiến trình Spring đang phục vụ cùng database.
2. Trỏ biến database của Node.js tới database đó. Cấu hình cũ `DB_URL=jdbc:postgresql://...`, `DB_USER`, `DB_PASSWORD` vẫn được nhận; `DATABASE_URL` ưu tiên hơn `DB_URL`.
3. Đặt `SESSION_SECRET` và chạy `npm.cmd run migrate`, sau đó `npm.cmd start`. Không chạy lại SQL V1 thủ công.

Các file V1–V3 ở [db/migrations](db/migrations) được di chuyển nguyên nội dung từ Flyway. Runner khóa migration bằng PostgreSQL advisory lock, kiểm checksum Flyway rồi ghi nhận vào `node_schema_history`; không chạy lại migration đã được xác nhận. Database mới được áp dụng V1–V4 trong giao dịch. V4 chỉ thêm bảng session Node.js. Không xóa bảng/dữ liệu legacy `facilities`. Khi checksum sai, lịch sử có migration lỗi hoặc database có bảng mà thiếu lịch sử, runner dừng để xử lý đúng dữ liệu.

Tài khoản/mật khẩu bcrypt cũ vẫn dùng được. Session Spring cũ không được nhập sang Node.js; Admin đăng nhập lại. Các lần khởi động Node tiếp theo dùng session lưu PostgreSQL và cùng `SESSION_SECRET`. Không chạy đồng thời hai runtime để ghi chung database trong đợt chuyển.

## API và quy tắc được giữ

- Envelope `{data,meta.trace_id}` và `{error:{code,message,field_errors},meta.trace_id}`, UUID, snake_case, mã lỗi và phân trang Admin theo [hợp đồng chung](../docs/baseline-v2/06_SHARED_CONTRACTS.md).
- Admin đăng nhập bằng session cookie HttpOnly, CSRF `X-CSRF-TOKEN`, không dùng JWT. Lấy token qua `GET /admin/auth/csrf` trước login và lấy lại sau login. Session ID/token đổi khi login, logout hủy session. HTTPS cần `SESSION_COOKIE_SECURE=true`; khi qua proxy, đặt đúng `TRUST_PROXY_HOPS`.
- CRUD categories/sources/articles; nested steps/references lưu nguyên tử; `expected_revision` ngăn ghi đè; sửa bài public đưa về DRAFT, bỏ xác nhận và tăng revision. Publish kiểm trường bắt buộc, nguồn/trang, category active và content_checked. Không xóa/gỡ category hay source đang được bài public dùng. Metadata nguồn ảnh hưởng provenance làm tăng source revision.
- Public chỉ đọc bài PUBLISHED, đã kiểm và category/sources active. Ảnh bước tối đa 6/bước; URL do server tạo. Upload JPEG/PNG tối đa 5 MiB/16 MP, giải mã và bỏ metadata; media chỉ công khai khi gắn bài public. Gỡ bài chặn đọc ảnh công khai ngay request tiếp theo.
- `GET /offline-snapshot?region_code=VN-DN` giữ v1 và `facilities: []`. `?schema_version=2` trả v2 không cần vùng; v1/v2 có ETag riêng. Snapshot đọc trong giao dịch REPEATABLE READ, không cắt âm thầm dữ liệu vượt giới hạn.
- `/assistant/query` nhận JSON; `/assistant/query-with-image` nhận đúng part `request` (JSON) và `image`. Gateway chuyển request_id/token tới AI, kiểm lại citation/source/article/age/revision bằng database, thay title nguồn bằng metadata và trả fallback khi upstream lỗi. Ảnh chỉ ở RAM trong vòng đời request, không ghi chat/ảnh lên disk hoặc log. Timeout ảnh tối đa 35 giây; timeout văn bản cấu hình 5–100 giây.
- Theo phạm vi giáo dục hiện tại, không cung cấp route `/facilities`; dữ liệu legacy trong DB được giữ. Không thêm chức năng danh bạ/GPS.

Giới hạn login: 10 lần/10 phút/IP. Chat mặc định 20 lần/phút/IP, tối đa đồng thời 8 request văn bản và 2 request ảnh mỗi tiến trình. Quota lưu trong RAM; triển khai nhiều replica cần giới hạn chung ở reverse proxy nếu muốn quota toàn cụm.

## Kiểm thử

```powershell
npm.cmd test
$env:TEST_DATABASE_URL='postgresql://test_user:test_password@127.0.0.1:5432/firstaid_test'
npm.cmd run test:integration
```

Integration test cần user được tạo schema. Mỗi ca tạo schema riêng tên `firstaid_test_<UUID>`, chạy trên PostgreSQL thật và chỉ xóa schema của chính nó khi kết thúc. Không trỏ test vào database đang phục vụ người dùng.

Test bao phủ database mới/nâng Flyway, seed bảo toàn dữ liệu, session/CSRF, nested rollback, cạnh tranh revision, xuất bản/gỡ bài, quyền media, snapshot/ETag, age group và AI qua fixture HTTP thực (văn bản/multipart, revision cũ, MIME giả, giới hạn ảnh, timeout/rate/concurrency). Fixture kiểm tính tương thích phần mềm; không xác nhận chất lượng Gemini thật.

Smoke API chạy trên backend test đã seed. Script này mặc định gửi vùng VN-PILOT, nên cấu hình `PUBLIC_REGION=VN-PILOT` cho lần kiểm đó:

```powershell
$env:TEST_ADMIN_USERNAME='your-test-admin'
$env:TEST_ADMIN_PASSWORD='your-test-password'
npm.cmd run smoke:api -- -BaseUrl http://127.0.0.1:8080/api/v1
```

`npm.cmd run fixture:ai` chạy HTTP server giả lập ở `tests/fixtures/mock-ai-server.js` trên cổng 18081. Trỏ backend thử tới fixture bằng `AI_BASE_URL=http://127.0.0.1:18081` và `AI_INTERNAL_TOKEN=LocalInternalTestToken`, rồi chạy `npm.cmd run smoke:ai`. Gateway smoke mặc định gọi backend cổng 18080; dùng `TEST_API_URL` để đổi URL đầy đủ `/api/v1/assistant/query` khi cần. Tắt fixture AI trước khi nối dịch vụ thật.
