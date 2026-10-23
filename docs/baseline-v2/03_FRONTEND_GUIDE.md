# Frontend Implementation Guide

Baseline 2.0 | Mobile Flutter và web Admin. Đọc 01, 02 và [06_SHARED_CONTRACTS.md](06_SHARED_CONTRACTS.md) trước khi viết code.

## 1. Nhiệm vụ và ranh giới

Frontend phụ trách trải nghiệm người dùng, đọc dữ liệu local, gọi API theo contract và web CRUD. Không tự viết kiến thức y khoa, không phân loại bệnh bằng code UI và không gọi LLM trực tiếp. Các màn hình không được làm lộ tính năng ngoài scope như đăng ký mobile, voice/camera hoặc hồ sơ nạn nhân.

Stack mobile Flutter theo repo hiện tại. Dùng một state manager thống nhất; nếu repo chưa có, đề xuất Riverpod nhưng phải xác nhận dependency trước khi thêm. Admin mặc định React + TypeScript; giữ stack admin đã có nếu tương thích và báo khác biệt. Không cài nhiều UI/state libraries để làm cùng việc.

## 2. Phân chia mobile theo feature

Đề xuất thư mục `features/home`, `first_aid`, `knowledge`, `assistant`, `facilities`, `settings`; phần chung `core/api`, `core/storage`, `core/errors`, `core/theme`. Đây là cấu trúc gợi ý, không bắt buộc đổi tên các thư mục đang dùng.

Mỗi feature tối thiểu có model/DTO, repository và presentation/controller khi cần. Không tạo lớp trừu tượng hoặc use case chỉ để bọc một getter. Những logic đáng tách: tìm kiếm, chọn đúng article variant, sync transaction và tính khoảng cách.

| Thành phần | Trách nhiệm |
| --- | --- |
| ContentRepository | Đọc category/article/source từ SQLite; tìm kiếm local; không chờ mạng |
| ContentUpdateService | GET full snapshot, validate, thay dữ liệu trong transaction |
| GuidedFlowController | Đọc JSON flow giới hạn và mở article đúng variant |
| AssistantRepository | POST qua Spring, parse sáu status; không đọc API key LLM |
| FacilityRepository | Đọc cơ sở local; lấy dữ liệu online nếu người dùng yêu cầu/cập nhật |
| LocationService | Xin quyền đúng lúc, lấy vị trí foreground và xử lý denied |
| ExternalActionService | Mở dialer/map, xử lý không có app phù hợp |

## 3. Màn hình và route

| Route gợi ý | Screen ID Figma | Input |
| --- | --- | --- |
| `/home` | M01 | Không |
| `/quick` | M02 | query tùy chọn |
| `/category/:id` | M03 | Category ID, mode quick/learn |
| `/article/:id` | M04/M07 | Article ID và mode |
| `/guided/:flowKey` | M05 | Flow key allowlist |
| `/knowledge` | M06 | Search query, age filter tùy chọn |
| `/source/:id` | M08 | Source ID và page_start/page_end tùy chọn |
| `/assistant` | M09 | Không tự truyền hồ sơ nạn nhân |
| `/facilities` | M10 | Region mặc định |
| `/facility/:id` | M11 | Facility ID |
| `/settings` | M12 | Không |

Có thể map theo navigation framework trong repo. Không triển khai deep links public hoặc routing web mobile nếu không cần. Root giữ bottom navigation theo 02; quick/guided là flow riêng.

## 4. Seed local và đọc ngoại tuyến

Ứng dụng đi kèm `core_content.json` theo OfflineSnapshot schema và asset map `{asset_key: bundled_path}`. Lần đầu khởi động đọc seed vào SQLite trong một transaction, sau đó ContentRepository chỉ đọc local. Nếu SQLite chưa sẵn sàng hoặc lỗi seed, hiển thị lỗi có retry; phần hướng dẫn dự phòng chỉ dùng dữ liệu bundled đã validate, không fetch mạng bắt buộc.

Seed không phải các đoạn text lorem ipsum mang nhãn y khoa. Khi phát triển ban đầu được dùng fixture rõ `demo` để dựng UI; bản nghiệm thu cần nội dung kiểm tra đủ danh mục. Không biến việc có 18 category rỗng thành hoàn thành nội dung.

Các bảng local tối thiểu: app_metadata, categories, articles, article_steps, article_references, sources, facilities. Có thể lưu các mảng recognition/quick_actions/warnings/seek_help thành JSON text để giảm số bảng. Không cần bảng users, sessions, patients, chat_messages hoặc bundle_history.

Tìm kiếm local chuẩn hóa Unicode, lowercase, bỏ dấu và chuyển đ/Đ khi tạo search key, kết hợp title/summary/keywords do nhóm chuẩn bị. Kiểm riêng phủ định trong câu hỏi chat; không áp dụng normalize search mất ý nghĩa sang input gửi LLM. Với vài chục bài, chưa cần dựng search engine riêng.

## 5. Một Article cho hai mode

`quick`: hiển thị applies_to/age_group trước; ưu tiên quick_actions và steps; warnings/seek_help dễ tìm; nút gọi; recognition và phần giải thích có thể thu gọn nhưng không giấu điều kiện áp dụng.

`learn`: hiển thị đầy đủ recognition, summary và các section. Cùng Article ID, content_revision và references với quick. Không copy bài để tạo bản learn dẫn đến khác nội dung sau sửa.

Bước tiếp theo chỉ là điều hướng xem, không ghi “đã sơ cứu” hoặc “nạn nhân đã ổn”. Không lưu lịch sử thực hiện. Khi quay lại từ dialer, giữ vị trí đọc trong screen state; không tự đánh dấu cuộc gọi đã kết nối.

## 6. Guided flow nhỏ và cấu hình

P0 giới hạn một số flow liên quan FA01/FA02/FA03, chỉ khi câu hỏi và các nhánh đã được chuẩn bị từ nguồn. Không xây generalized graph engine/editor. JSON flow được developer quản lý cùng app; mỗi node là question, open_article hoặc unsupported. Có thể có vòng quay lại đánh giá chỉ khi đặc tả nội dung yêu cầu, không suy ra từ UI.

Mẫu cấu trúc kỹ thuật, không phải nội dung để sơ cứu:

```json
{
  "flow_key": "demo_flow",
  "entry_node": "q1",
  "nodes": [
    {
      "id": "q1",
      "type": "question",
      "prompt": "Câu hỏi đã chuẩn bị theo nguồn",
      "options": [
        {"code": "option_a", "label": "Lựa chọn A", "next_node": "result_a"},
        {"code": "unknown", "label": "Không chắc", "next_node": "result_unknown"}
      ]
    },
    {"id": "result_a", "type": "open_article", "category_code": "FA01", "variant_key": "adult_basic"},
    {"id": "result_unknown", "type": "unsupported", "message_code": "CONTACT_HELP"}
  ]
}
```

Định tuyến bằng category_code + variant_key ổn định rồi resolve article local; không dựa trên tiêu đề. Variant adult ở ví dụ không được chọn nếu flow chưa hỏi/xác nhận đúng nhóm; fixture này chỉ dùng test cấu trúc. Mỗi flow thật phải khai báo đối tượng đầu vào và test các nhánh. Bài không tồn tại/public/đúng tuổi thì unsupported, không chọn bài khác tự động.

Validate JSON flow lúc build: node IDs duy nhất, entry tồn tại, next_node tồn tại, terminal có dữ liệu cần thiết; test thủ công được người chuẩn bị nội dung xác nhận. Không hardcode thuật ngữ/phác đồ trong widget.

## 7. Cập nhật local đơn giản

Chỉ chạy khi người dùng bấm Cập nhật trong Settings và không đang xem bài/guided flow. Gửi If-None-Match theo data_version hiện có. 304 → thông báo đã mới. 200 → validate schema, duplicate IDs, article references, group code và content public; sau đó thay toàn bộ dataset trong một transaction.

Nếu lỗi mạng/schema/ghi DB: giữ dữ liệu hiện tại và báo cập nhật chưa thành công. Không xóa trước rồi gọi mạng. Không tải PDF gốc; ảnh core đã bundled. image_url mới chỉ bổ sung online, thiếu ảnh không được làm mất text hướng dẫn. Không triển khai custom signing, nhiều bundle hoặc delta sync.

Sau update, xóa/refresh cache repository và search index trong cùng chuỗi công việc. Với article đã unpublish, không còn trong snapshot mới. Máy không cập nhật vẫn có nội dung cũ; hiển thị generated_at và không cam kết thu hồi ngay khi offline.

## 8. Chatbot UI và lỗi

- Message gửi theo ChatRequest 06, tối đa 2000 ký tự; không tự chèn vị trí/định danh.
- Giữ chat trên RAM trong phiên màn hình/app, không ghi SQLite mặc định.
- P0 stateless server: mỗi câu hỏi đầy đủ tự nó; không gửi chỉ “Có” sau clarification như thể có server session.
- Hiện một request loading; disabled gửi lặp; không auto retry nếu timeout.
- Không render raw HTML/URL tự do từ AI; citation UI lấy structured metadata.
- Không stream chữ chưa kiểm; render response cuối.
- Offline hiện lối tìm local, không spinner 15 giây mới thông báo.

| status | Component |
| --- | --- |
| answered | ChatAnswer với citation chips |
| clarification_needed | ClarificationCard và gợi ý gửi câu đầy đủ bổ sung thông tin |
| emergency_redirect | EmergencyRedirectCard với gọi và mở bài/danh mục local |
| insufficient_evidence | StatusView, không hiển thị nguồn giả |
| out_of_scope | Thông báo giới hạn ngắn |
| unavailable hoặc HTTP lỗi | Retry chủ động, giữ câu hỏi và nút tìm local |

Mobile có thể phát hiện vài cụm từ để hiện nút sơ cứu sớm nhưng không coi heuristic là chẩn đoán. Server policy vẫn quyết định response. Nếu suggested_article_id chưa có local, dùng category code nếu hợp lệ rồi cho chọn bài; không fetch một hướng dẫn không kiểm được đối tượng.

## 9. Danh bạ và quyền vị trí

Hiện danh sách local ngay. Khi user chọn Dùng vị trí, xin quyền foreground; denied/permanentlyDenied/unavailable đều có giải thích và tiếp tục xem vùng. Không permission trên launch. Không background location.

Tính Haversine để sắp danh sách nhỏ; label rõ “khoảng cách đường thẳng”. Không có vị trí thì không hiển thị 0 km. Nguồn local/online đều có cùng DTO Facility. UNKNOWN 24/7 không dùng badge “Có cấp cứu 24/7”. Gọi truyền số đã validate sang dialer, map dùng latitude/longitude; không mở URL do LLM cung cấp.

Nếu không mở được app ngoài, cho sao chép số/địa chỉ và hiện thông báo phù hợp. Không khẳng định cuộc gọi thành công, xe đã được điều hoặc bệnh viện nhận nạn nhân.

## 10. Web Admin

Admin shell gồm bốn menu và logout. Login dùng session cookie + CSRF theo 06; gọi `/auth/me` khi reload; không quản lý token localStorage. Dev proxy cùng origin là cách ưu tiên để giảm CORS; production reverse proxy web và `/api` cùng origin.

Danh sách bài có search/filter/pagination; form bài quản lý nested steps và references; có reorder steps bằng nút lên/xuống, không bắt buộc drag-and-drop. Preview có thể là panel dùng chung layout bài, không phải một app mobile chạy trong iframe.

Lưu DRAFT và Publish là hai hành động rõ. Trước lưu bài public, cảnh báo chuyển DRAFT. Hiển thị lỗi field và 409 CONTENT_CONFLICT; không ghi đè tự động. Category/source đang được dùng không xóa được thì giải thích liên kết cần xử lý. Source screen chỉ metadata; không làm upload→train AI hoặc review workflow.

Form cơ sở kiểm định dạng và tọa độ; không thay kiểm dữ liệu thật. Enum UNKNOWN luôn là lựa chọn hợp lệ cho 24/7. Không thêm bảng nhân viên, tài khoản mobile, thống kê nạn nhân hoặc analytics không tồn tại.

## 11. Tích hợp và mock

Tạo fixture theo 06 dùng cho UI trước khi API có. Mock layer phải đổi được qua config dev, không để mock tự bật trong production nếu API lỗi. Nếu chọn mock, màn hình demo ghi rõ dữ liệu giả. Frontend và backend dùng cùng fixture ít nhất cho Article, OfflineSnapshot và sáu ChatStatus.

Không đổi contract để chữa một lỗi parse riêng lẻ; kiểm schema và cập nhật thống nhất nếu thật sự cần. Endpoint base_url từ environment/flavor, không hardcode máy cá nhân. Emulator dùng host phù hợp cấu hình dev và README thực tế; không tự sửa network security production để cho phép mọi HTTP.

## 12. Thứ tự thực hiện

1. Theme/navigation và local seed đọc được một bài demo.
2. Danh mục, tìm kiếm, quick/learn và sources.
3. Tích hợp đủ 18 nhóm và variant selector.
4. Guided flow nhỏ, gọi điện, danh bạ và permission.
5. Snapshot update.
6. Web Admin login và CRUD theo API.
7. Chat UI từ fixtures, sau đó nối backend/RAG.
8. Device tests, font lớn, error states và sửa lỗi.
9. CPR P1 nếu còn thời gian.

## 13. Definition of Done

Không login mobile; core đọc được airplane mode ngay sau cài; cùng Article hiển thị được hai mode; chọn tuổi không nhầm; không thiếu text khi ảnh lỗi; sync lỗi không mất local; sáu ChatStatus có UI; từ chối vị trí không crash; Admin không bypass session/CSRF; không có tính năng ngoài scope trong navigation; smoke test Android thật và báo rõ hạn chế iOS. Bộ test cụ thể ở 08.
