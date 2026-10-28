# Shared Data and API Contracts

Baseline 2.0 | Đây là nguồn thống nhất của Frontend, Backend và AI. Các ID trong ví dụ là dữ liệu minh họa, không phải hồ sơ y tế thật.

## 1. Quy ước chung

- API chính: `/api/v1`. RAG nội bộ: `/internal/v1`; mobile không gọi trực tiếp FastAPI.
- JSON UTF-8; field dùng `snake_case`; UUID dạng chuỗi cho ID đối tượng; mã danh mục `FA01` đến `FA18` là business code ổn định.
- Timestamp ISO 8601 UTC, ví dụ `2026-10-23T00:00:00Z`.
- `null` = chưa có/không áp dụng; không thay bằng `""`, `0` hay `false`.
- Thứ tự bước là `position` bắt đầu từ 1; duy nhất và liên tiếp trong một bài.
- Nội dung text thuần hoặc đoạn Markdown giới hạn được renderer cho phép; không nhận raw HTML/script.
- Các UUID dạng toàn số trong ví dụ chỉ phục vụ fixture; seed thật tạo UUID riêng và giữ mapping ổn định.

Success envelope:

```json
{
  "data": {"items": []},
  "meta": {"trace_id": "request-trace"}
}
```

Error envelope:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Dữ liệu chưa hợp lệ",
    "field_errors": [{"field": "title", "message": "Không được để trống"}]
  },
  "meta": {"trace_id": "request-trace"}
}
```

Chi tiết một tài nguyên nằm trực tiếp trong `data`. List dùng `data.items`. List Admin có `data.page`, `data.page_size`, `data.total`; page bắt đầu 1, page_size mặc định 20, tối đa 100. Public trả tập nhỏ có giới hạn ở mục 7, không phải API phân trang vô hạn.

## 2. Enum

| Tên | Giá trị |
| --- | --- |
| ContentStatus | `DRAFT`, `PUBLISHED` |
| GroupCode | `CIRCULATION`, `TRAUMA`, `ENVIRONMENT`, `OTHER` |
| AgeGroup | `ADULT`, `CHILD`, `ALL` |
| ChatStatus | `answered`, `clarification_needed`, `emergency_redirect`, `insufficient_evidence`, `out_of_scope`, `unavailable` |
| Emergency24h | `YES`, `NO`, `UNKNOWN` |
| AppViewMode | `quick`, `learn` — giá trị UI, không tạo bảng riêng |

Phạm vi chỉ gồm người lớn và trẻ em, không bao gồm nhũ nhi. `ALL` chỉ có nghĩa dùng chung cho hai nhóm trong phạm vi, không mở rộng sang nhũ nhi.

`ALL` chỉ dùng khi người chuẩn bị nội dung đã xác nhận hướng dẫn đó dùng chung được. Không có bài đúng AgeGroup thì hiển thị không hỗ trợ, không lấy ADULT mặc định. Nhóm tuổi trong UI cần diễn giải theo nội dung nguồn, không tự gán ranh giới tuổi y khoa bằng code.

Filter một AgeGroup cụ thể trả bài đúng nhóm đó và bài ALL thật sự phù hợp. Không truyền age_group thì trả danh sách có nhãn để người dùng chọn, không tự suy nhóm tuổi. Không dùng query param để thay đổi nội dung/thao tác bên trong một bài thuộc nhóm khác.

## 3. Category và Source

Category:

```json
{
  "id": "00000000-0000-4000-8000-000000000001",
  "code": "FA01",
  "name": "Người bất tỉnh hoặc không đáp ứng",
  "group_code": "CIRCULATION",
  "description": "Nhóm nội dung hướng dẫn đã được chuẩn bị",
  "keywords": ["từ khóa và cách gọi thường gặp đã được nhóm chọn"],
  "sort_order": 1,
  "is_active": true
}
```

Source — chỉ metadata, không nhét PDF vào snapshot:

```json
{
  "id": "00000000-0000-4000-8000-000000000101",
  "code": "PNT2024",
  "title": "CẨM NANG SƠ CẤP CỨU",
  "publisher": "CLB Cấp Cứu Ngoại Viện, trường ĐH Y khoa Phạm Ngọc Thạch",
  "publication_year": 2024,
  "page_count": 47,
  "revision": 1,
  "original_url": null,
  "is_active": true,
  "rights_note": "Cần xác nhận quyền chuyển thể và sử dụng hình ảnh"
}
```

Admin có thể lưu ghi chú nội bộ về đường dẫn file/hash; API public không lộ server path. `revision` tăng khi thay tệp gốc hoặc thay metadata có ảnh hưởng provenance. Không coi mỗi sửa typo metadata là một tài liệu y khoa mới; quy tắc tăng revision phải thống nhất trong service.

## 4. Article

Article là một biến thể hướng dẫn. Một Category có thể có nhiều Article: người lớn, trẻ em, hoặc bài con khác nguyên nhân. `variant_key` duy nhất trong category, không phụ thuộc tiêu đề để định danh.

```json
{
  "id": "00000000-0000-4000-8000-000000000201",
  "category_id": "00000000-0000-4000-8000-000000000001",
  "slug": "sample-adult-guide",
  "variant_key": "adult_basic",
  "title": "Bài minh họa cấu trúc dữ liệu",
  "age_group": "ADULT",
  "applies_to": "Phạm vi áp dụng đã kiểm tra theo nguồn",
  "summary": "Tóm tắt do nhóm chuẩn hóa",
  "recognition": ["Dấu hiệu đã được kiểm tra"],
  "quick_actions": ["Việc cần làm đã được kiểm tra"],
  "steps": [
    {
      "id": "00000000-0000-4000-8000-000000000301",
      "position": 1,
      "title": "Tên bước đã duyệt nội dung",
      "instruction": "Chỉ dẫn theo nguồn, không dùng mẫu này để sơ cứu",
      "asset_key": "fa01_step01_v1",
      "image_url": null,
      "alt_text": "Mô tả hình minh họa"
    }
  ],
  "warnings": ["Điều không nên làm, đã kiểm tra"],
  "seek_help": ["Điều kiện liên hệ hỗ trợ, đã kiểm tra"],
  "references": [
    {
      "source_id": "00000000-0000-4000-8000-000000000101",
      "page_start": 10,
      "page_end": 10,
      "section_key": "all",
      "note": "Ví dụ schema, không xác nhận nguồn này hỗ trợ nội dung mẫu"
    }
  ],
  "status": "DRAFT",
  "content_checked": false,
  "checked_at": null,
  "content_revision": 1,
  "updated_at": "2026-10-23T00:00:00Z"
}
```

`asset_key` trỏ asset đã bundled trong Flutter, không phải đường dẫn tùy ý trên filesystem. `image_url` là hình online bổ sung được Admin cấu hình; khi offline thiếu hình này thì dùng asset_key hoặc text đầy đủ. Nội dung thiết yếu không được chỉ nằm trong hình online. Ảnh, alt_text và text phải nhất quán.

API Admin create/update nhận nội dung bài và nested steps/references trong một request; server tạo ID step mới nếu chưa có ID. Public chỉ trả PUBLISHED, content_checked=true, category/source còn active. Hai trường content_checked/checked_at thể hiện xác nhận nhập liệu của Admin, không tạo vai trò duyệt mới và không tự chứng minh thẩm định y khoa.

`content_revision` là bộ đếm thay đổi nội dung, không lưu lịch sử revision và không hỗ trợ rollback. Chỉ server tăng; client không tự gửi revision mới. Update dùng `expected_revision` để tránh ghi đè khi mở hai tab. Nếu khác revision hiện tại: trả 409 `CONTENT_CONFLICT`.

Validation publish: đủ title, category, variant, age_group, applies_to, summary, recognition, quick_actions, steps, warnings, seek_help, references; bước có text; reference có trang hợp lệ trong nguồn; nội dung đã kiểm tra và checked_at có giá trị. Mảng không áp dụng có thể chứa diễn giải được kiểm tra, không chèn lời khuyên giả để qua validator.

## 5. Facility

```json
{
  "id": "00000000-0000-4000-8000-000000000401",
  "name": "Cơ sở minh họa — không dùng để liên hệ thật",
  "region_code": "VN-PILOT",
  "address": "Địa chỉ phải được thay bằng dữ liệu xác minh",
  "phone": null,
  "latitude": null,
  "longitude": null,
  "emergency_24h": "UNKNOWN",
  "verification_note": "Chưa xác minh, chỉ là fixture",
  "verified_at": null,
  "is_active": false,
  "distance_km": null,
  "distance_type": null
}
```

Fixture này không xuất hiện trong danh bạ thật. Cơ sở active cần tên, địa chỉ, vùng, điện thoại được kiểm tra, tọa độ hợp lệ, verification_note và verified_at. Nếu không xác minh được thông tin 24/7, để UNKNOWN và hiển thị rõ.

`distance_km`/`distance_type` là trường tính toán, không lưu cột DB; có vị trí hợp lệ thì distance_type=`straight_line`, nếu không thì cả hai null. Latitude trong [-90,90], longitude trong [-180,180]; không chấp nhận chỉ một trường có giá trị. App và server dùng cùng Haversine để kết quả/sắp xếp nhất quán. Không có ETA trong P0.

## 6. OfflineSnapshot

```json
{
  "schema_version": 1,
  "data_version": "opaque-version-from-server",
  "generated_at": "2026-10-23T00:00:00Z",
  "region_code": "VN-PILOT",
  "app_config": {
    "locale": "vi-VN",
    "emergency_number": "115"
  },
  "categories": [],
  "articles": [],
  "sources": [],
  "facilities": []
}
```

Mảng rỗng chỉ minh họa schema; seed nghiệm thu phải có nội dung cho 18 nhóm. Số hỗ trợ trong ví dụ phải được nhóm xác minh cho khu vực trước sử dụng thật. Không suy số cấp cứu từ locale thiết bị.

`data_version` là token opaque (ví dụ UUID server), chỉ so bằng/khác; không so thứ tự thời gian từ chuỗi. Backend thay token trong transaction mỗi khi dữ liệu public thay đổi, kể cả gỡ bài/source/facility. API hỗ trợ ETag bằng token; If-None-Match trùng thì 304 không body. Mobile validate schema/ID/references rồi thay nội dung local trong một transaction; không download PDF hoặc tự chạy migration từ server.

Nếu snapshot vượt schema hỗ trợ, báo cần cập nhật app; giữ dữ liệu hiện tại. Không lưu nhiều bundle. Bài đang mở giữ object hiện tại; cập nhật chỉ bắt đầu khi đã về trang không đọc bài. Guided route phải được kiểm liên kết sau cập nhật; route không còn bài phù hợp sẽ unavailable, không mở ID cũ.

## 7. Public API

Mọi path dưới đây có prefix `/api/v1`.

| Method | Path | Input | Output |
| --- | --- | --- | --- |
| GET | `/categories` | Không | `data.items: Category[]` active |
| GET | `/articles` | category_id?, age_group?, q? | `data.items: ArticleSummary[]` |
| GET | `/articles/{id}` | UUID | `data: Article` public |
| GET | `/sources` | Không | `data.items: Source[]` active công khai |
| GET | `/sources/{id}` | UUID | `data: Source` public |
| GET | `/facilities` | region_code?, latitude?, longitude? | `data.items: Facility[]` active, có distance nếu đủ tọa độ |
| GET | `/facilities/{id}` | UUID | `data: Facility` public |
| GET | `/offline-snapshot` | region_code, If-None-Match? | `data: OfflineSnapshot`, hoặc 304 |
| POST | `/assistant/query` | ChatRequest | `data: ChatResponse` |

ArticleSummary chỉ gồm id, category_id, slug, variant_key, title, age_group, summary, content_revision, updated_at. Public list bounded cho dataset đồ án: category ≤ 30, article ≤ 500, facility ≤ 100 mỗi vùng, source ≤ 100. Nếu vượt giới hạn, mở thay đổi contract phân trang; không cắt kết quả âm thầm. Mobile dùng local snapshot cho danh mục/tìm bài, không gọi public API từng bước.

## 8. Admin API

Prefix đầy đủ `/api/v1/admin`. Chỉ GET csrf và POST login là không yêu cầu session trước; vẫn bảo vệ login bằng CSRF/rate limit theo cấu hình. Mọi endpoint còn lại cần session ADMIN.

| Method | Path sau prefix | Input/ghi chú |
| --- | --- | --- |
| GET | `/auth/csrf` | Lấy CSRF token cho web client |
| POST | `/auth/login` | `{username,password}`; trả admin metadata và Set-Cookie session |
| GET | `/auth/me` | Admin hiện tại |
| POST | `/auth/logout` | Hủy session, có CSRF |
| GET/POST | `/categories` | List/create Category |
| GET/PUT/DELETE | `/categories/{id}` | Read/update/delete; chặn delete nếu có bài |
| GET/POST | `/articles` | List filter status/category/q/page/page_size; create draft |
| GET/PUT/DELETE | `/articles/{id}` | Full nested article update; delete xử lý child rows trong transaction; mobile guided route resolve thiếu bài phải hiện unsupported |
| POST | `/articles/{id}/publish` | expected_revision; kiểm đủ trường và content_checked |
| POST | `/articles/{id}/unpublish` | expected_revision; đổi DRAFT và cập nhật data_version |
| GET/POST | `/sources` | List/create metadata, không upload PDF tùy ý |
| GET/PUT/DELETE | `/sources/{id}` | Chặn delete/deactivate khi bài public còn tham chiếu |
| GET/POST | `/facilities` | List/create Facility |
| GET/PUT/DELETE | `/facilities/{id}` | Read/update/delete hoặc deactivate theo UI |

Khi PUT bài public: nếu chỉ sửa nội dung, server đưa về DRAFT, tăng content_revision và data_version vì bài không còn trong public snapshot; Admin kiểm và publish lại. UI cảnh báo rõ trước lưu. Không cần workflow reviewer. Source file revision thay đổi phải ngăn citation corpus cũ hợp lệ nhầm; AI reindex do nhóm chạy thủ công.

Cookie HttpOnly, Secure khi HTTPS, SameSite phù hợp same-origin. Web gửi credentials; các request ghi kèm CSRF token. Không lưu password hoặc session token vào localStorage. Một tài khoản Admin seed từ biến môi trường/CLI, không endpoint đăng ký công khai. Không yêu cầu JWT nếu session cùng origin đã đủ.

DTO auth để hai bên tích hợp thống nhất:

- GET csrf: `data: {"token":"opaque-csrf-value","header_name":"X-CSRF-TOKEN"}`; token là ví dụ và không được hardcode.
- POST login và GET me: `data: {"id":"UUID","username":"admin-name","role":"ADMIN"}`. Login đặt session cookie; không trả access_token/refresh_token.
- POST logout: HTTP 204 không body. Các DELETE thành công cũng 204, trừ khi backend trả RESOURCE_IN_USE.
- POST create tài nguyên: 201 và `data` đối tượng vừa tạo; PUT: 200 và `data` đối tượng mới. Publish/unpublish: 200 và `data: Article` sau thay đổi. Admin API có thể thấy DRAFT, public API không được thấy.
- Article update request thêm `expected_revision` bên cạnh field nội dung; server bỏ qua ID/status/counter do client cố ghi trái quy tắc, hoặc trả lỗi validation rõ; không silently sửa quyền/trạng thái.

## 9. ChatRequest và ChatResponse

```json
{
  "client_request_id": "00000000-0000-4000-8000-000000000501",
  "message": "Tôi muốn tìm kiến thức trong tài liệu sơ cứu",
  "age_group": null,
  "context_mode": "learning"
}
```

`message` 1–2000 ký tự sau trim; age_group nullable enum. context_mode=`learning` hoặc `unspecified`, là gợi ý UI chứ không quyền bỏ qua policy. P0 mỗi request độc lập; không gửi lịch sử hội thoại lên server. UI ghi “Mỗi câu hỏi được xử lý độc lập” và khuyến khích nêu đủ bối cảnh; không tạo cảm giác chatbot nhớ chi tiết nạn nhân.

```json
{
  "request_id": "00000000-0000-4000-8000-000000000501",
  "status": "answered",
  "answer_blocks": [
    {"text": "Nội dung minh họa, chưa phải hướng dẫn y khoa", "citation_ids": ["c1"]}
  ],
  "citations": [
    {
      "id": "c1",
      "evidence_id": "PNT2024-p010-block01",
      "source_id": "00000000-0000-4000-8000-000000000101",
      "source_revision": 1,
      "source_title": "CẨM NANG SƠ CẤP CỨU",
      "page_start": 10,
      "page_end": 10,
      "article_id": null,
      "article_revision": null
    }
  ],
  "suggested_category_code": null,
  "suggested_article_id": null,
  "safety_message_code": null,
  "clarification_question": null,
  "corpus_version": "corpus-demo-1"
}
```

Mọi key trên luôn có; các trường không dùng là null hoặc mảng rỗng. Không có confidence lâm sàng.

| status | Quy tắc output | Hành vi UI |
| --- | --- | --- |
| answered | answer_blocks có nội dung; khẳng định y khoa có citation hợp lệ | Hiện câu trả lời và nguồn bấm được |
| clarification_needed | clarification_question khác null; không kèm lời khuyên theo giả định | Hiện câu hỏi và input cho câu hỏi đầy đủ tiếp theo |
| emergency_redirect | safety_message_code cố định; suggested category/article có thể null | Thẻ gọi hỗ trợ và mở danh mục/bài local phù hợp; không sinh thủ thuật tự do |
| insufficient_evidence | Không có bằng chứng đủ; không bịa nguồn | Thông báo và gợi ý tìm bài/nhờ chuyên môn |
| out_of_scope | Trả lời ngắn trong giới hạn sản phẩm | Hiện giới hạn và mở kiến thức nếu muốn |
| unavailable | Provider/lỗi dịch vụ được xử lý; answer rỗng | Giữ câu hỏi, nút thử lại và tìm local |

`suggested_article_id` chỉ được server trả nếu tồn tại, public và đúng đối tượng. Nếu mobile chưa có bài đó, mở category/tìm local; không mở một bài khác tuổi như fallback. Title nguồn/URL không lấy từ LLM mà map từ metadata.

## 10. Giao tiếp Spring và FastAPI

`POST /internal/v1/query`, JSON body gồm request_id, message, age_group, context_mode; response là ChatResponse **không có envelope public**. Spring bọc envelope khi trả mobile. FastAPI có health `/health` cho kiểm nội bộ, không public.

Spring map `client_request_id` của public request thành `request_id` nội bộ và response; không tự phát sinh hai ID không liên kết. trace_id phục vụ kỹ thuật có thể khác request_id nhưng phải theo dõi được trong log đã loại thông tin riêng.

Token nội bộ qua header `X-Internal-Token`, secret ở server, không ở mobile. Chỉ mở FastAPI trên private network hoặc localhost. P0 không cần OAuth nội bộ. Spring kiểm lại nguồn và article revision từ DB trước trả client; không tin ID nguồn do model tự viết.

Timeout thống nhất: provider tối đa 7 giây; FastAPI ngân sách tổng 9 giây; Spring chờ AI tối đa 12 giây; mobile timeout toàn request 15 giây. Không retry tự động chat ở từng tầng; người dùng bấm thử lại. Khi nội bộ timeout, Spring trả status unavailable có kiểm soát nếu còn xử lý được; lỗi mạng gateway vẫn có thể là HTTP 503 và UI xử lý tương tự.

## 11. Mã lỗi và giới hạn

| HTTP | Code | Tình huống |
| --- | --- | --- |
| 400 | VALIDATION_ERROR | Input sai field/schema |
| 401 | AUTH_REQUIRED hoặc INVALID_CREDENTIALS | Chưa login hoặc sai tài khoản |
| 403 | ACCESS_DENIED hoặc CSRF_INVALID | Không có quyền/token phù hợp |
| 404 | NOT_FOUND | Không tồn tại hoặc không public |
| 409 | CONTENT_CONFLICT hoặc RESOURCE_IN_USE | Sai expected_revision, xóa đối tượng còn tham chiếu |
| 422 | CONTENT_NOT_READY | Publish thiếu nội dung/nguồn/kiểm tra |
| 429 | RATE_LIMITED | Chat/login bị giới hạn, có Retry-After |
| 503 | SERVICE_UNAVAILABLE | Hạ tầng không xử lý được request |

Không đủ bằng chứng, ngoài phạm vi và chuyển hướng khẩn cấp là kết quả nghiệp vụ HTTP 200, không phải lỗi 500. Chat quota đề xuất configurable theo IP với giới hạn thận trọng cho mạng trường dùng chung; không xây hệ thống quota tài khoản mobile. Không log raw request body hoặc tọa độ.

## 12. Kiểm tra tương thích bắt buộc

Frontend dùng fixture theo chính schema này. Backend có serialization/validation tests. AI trả đúng ChatStatus, source_revision và citation format. Có ít nhất một integration test cho answered, emergency_redirect và unavailable. Không chấp nhận `articleId` từ một bên và `article_id` từ bên khác mà không cập nhật contract.
