# Acceptance Criteria and Implementation Plan

Baseline 2.0 | Kế hoạch cho 3 sinh viên trong khoảng 5 tuần và vài ngày dự phòng. Không phải cam kết mọi hạng mục đã triển khai.

## 1. Phân công

| Vai trò nhóm | Phụ trách chính | Phối hợp |
| --- | --- | --- |
| A — Mobile | Flutter, local data, quick/learn, guided flow, permission, chat UI | B chốt API, C chốt nội dung và response |
| B — Backend và Admin | Spring Boot, PostgreSQL, API, web Admin CRUD, deploy và tích hợp AI | A fixture/contract, C source IDs |
| C — AI và dữ liệu | Corpus, RAG, source mapping, benchmark; điều phối chuẩn bị nội dung | Cả nhóm chia 18 chủ đề và kiểm chéo |

Không để C một mình viết và kiểm toàn bộ 18 nhóm; công nội dung là phần việc đáng kể, không chỉ copy PDF. Không đặt nhiệm vụ chuyên môn vào một role phần mềm mới.

## 2. Các giai đoạn

| Giai đoạn | Kết quả cần bàn giao | Điều kiện qua |
| --- | --- | --- |
| Tuần 1 | Kiểm repo, baseline/contract, wireframe, seed danh mục, một bài local; migration và public read; corpus mẫu | Mobile offline mở được bài demo rõ nhãn; cả ba bên dùng cùng ID/schema |
| Tuần 2 | Quick/learn, tìm kiếm, Admin login + CRUD cơ bản, nguồn metadata; nội dung các nhóm đầu | Không lộ draft; form bài/steps/source round trip; nội dung có evidence |
| Tuần 3 | Danh bạ, external actions, snapshot update; RAG baseline và chat fixtures | Offline/error states có UI; RAG trả đủ status và citation |
| Tuần 4 | Tích hợp chatbot thật, guided flow giới hạn, hoàn thiện coverage 18 nhóm | API đúng contract, citation/version checks; đủ bài phù hợp để kiểm thử |
| Tuần 5 | Benchmark, device tests, usability nhỏ, sửa lỗi, triển khai thử | Không còn lỗi nghiêm trọng; chạy được từ hướng dẫn sạch |
| Dự phòng cuối | Video, báo cáo, đóng gói và regression trọng tâm | Known limitations đúng thực tế, P1 không làm hỏng P0 |

Nếu vẫn giữ mốc 30/11/2026 trong đề cương, nhóm có thể bắt đầu từ 23/10 và dành các ngày cuối cho báo cáo/nộp. Cần xác nhận lại mốc với giảng viên; không mặc định những đầu việc dự kiến trong đề cương đã làm xong.

## 3. Lát cắt triển khai đầu tiên

Một Article fixture theo 06 → seed vào SQLite → hiển thị danh sách và trang quick/learn → mở source metadata. Song song backend lưu/đọc lại chính Article đó và Admin tạo/sửa nó. AI dùng cùng source ID cho một response fixture. Sau khi cả chuỗi khớp mới nhân lên đủ chủ đề và nối provider thật.

Không yêu cầu Codex dựng toàn bộ dự án, 18 phác đồ và AI hoàn chỉnh trong một prompt. Mỗi task kết thúc bằng thay đổi cụ thể, cách chạy và bằng chứng kiểm phù hợp.

## 4. Tiêu chí P0 hoàn thành

### 4.1 Nội dung và mobile

- Có 18 category codes chính thức; mỗi nhóm có bài thật phù hợp phạm vi, không rỗng/placeholder.
- Các biến thể quan trọng có nhãn; không lấy bài người lớn thay bài trẻ em.
- Article quick và learn hiển thị cùng nội dung nguồn, điều kiện và references.
- Cài app mới rồi ngắt mạng vẫn đọc được core, hình bundled và metadata nguồn.
- Tìm kiếm có/không dấu trên tập keyword chuẩn bị.
- Guided flow chỉ mở bài đã tồn tại phù hợp; unknown không bị suy thành an toàn.
- Gọi/map là thao tác chủ động; từ chối vị trí không làm mất danh bạ.

### 4.2 Backend và Admin

- Một role ADMIN; public không cần login và không thấy draft.
- CRUD Category/Article/Source/Facility theo contract; publish có kiểm trường/nguồn.
- Xóa tài nguyên đang tham chiếu được chặn rõ.
- Snapshot đủ liên kết, ETag đúng và cập nhật mobile không mất dữ liệu hiện tại khi lỗi.
- Không có API mobile account, patient, reviewer workflow hoặc upload-to-train tự động.

### 4.3 AI

- RAG chỉ dùng curated corpus, không index đề cương/tài liệu kỹ thuật/quiz sai.
- Output đủ sáu ChatStatus, nguồn đúng ID/trang/revision.
- Mô tả sự cố nguy cơ chuyển hướng thay vì sinh thủ thuật tự do.
- Không đủ nguồn và provider lỗi có fallback đúng, không bịa câu trả lời.
- Benchmark khóa tập test; báo đủ kết quả và lỗi, không tuyên bố an toàn tuyệt đối.

## 5. Mục tiêu chất lượng có thể đo

| Mã | Mục tiêu gợi ý | Cách đo |
| --- | --- | --- |
| NFR01 | Trang quick mở từ trang chủ đến màn hình dùng được ≤ 2 giây P95 | 30 lần trên Android thật được ghi cấu hình, offline |
| NFR02 | Cold start đến trang chủ dùng được ≤ 5 giây P95 | 20 lần, seed đã bundled, ghi build release/debug |
| NFR03 | Đọc bài/tìm local không cần request mạng | Chặn mạng, chạy luồng từ cài mới |
| NFR04 | Chat có kết quả hoặc lỗi kiểm soát trong 15 giây | Fixture, provider thật và timeout; không chỉ đo request thành công |
| NFR05 | Core dữ liệu và ảnh mục tiêu ≤ 30 MB ngoài binary/framework | Đo artifact; không bỏ điều kiện/hình thiết yếu để ép dung lượng |
| NFR06 | Cỡ chữ 200% vẫn đọc và bấm được | Kiểm màn hình nhỏ, nút gọi, nội dung dài |
| NFR07 | Không lỗi mất dữ liệu khi update thất bại | Mất mạng, JSON sai, FK sai, ghi DB lỗi |
| NFR08 | Không lộ bí mật/thông tin user qua log mặc định | Kiểm repo/config/log bằng dữ liệu giả |

Các ngưỡng là mục tiêu cho đồ án; điều chỉnh phải ghi lý do và bằng chứng. Không báo số liệu chưa đo. Nếu thiết bị yếu hơn giả định, báo kết quả thực và tối ưu đúng nút thắt thay vì đổi cách tính.

## 6. Ca kiểm thử nghiệm thu trọng tâm

| ID | Thử nghiệm | Kết quả mong đợi | FR |
| --- | --- | --- | --- |
| TC01 | Cài mới, airplane mode, mở bài | Core và nguồn đọc được, không login | FR01, FR07 |
| TC02 | Tìm có/không dấu và keyword | Cùng nhóm/bài phù hợp trong tập chuẩn bị | FR02 |
| TC03 | Xem quick rồi learn cùng ID | Section có cùng text/reference, khác thứ tự hiển thị | FR03, FR04 |
| TC04 | Chọn đối tượng chưa có bài | Nêu giới hạn, không mở adult khác | FR05 |
| TC05 | Guided chọn không chắc/nhánh thiếu bài | Nhánh định nghĩa hoặc trạng thái unsupported, không crash | FR05 |
| TC06 | Bấm gọi rồi hủy, quay lại | Giữ vị trí đọc; không báo kết nối thành công | FR06 |
| TC07 | Hình online không tải | Asset bundled/text vẫn dùng được | FR03, FR07 |
| TC08 | Update mất mạng/JSON sai/FK sai | Dữ liệu cũ còn nguyên, có thông báo | FR08 |
| TC09 | Snapshot mới bỏ bài đang public | Sau update bài không còn trong list; route thiếu xử lý rõ | FR08 |
| TC10 | Chat answered có nguồn | Citation mở đúng source/trang, không URL tự bịa | FR09, FR11 |
| TC11 | Chat hỏi thiếu dữ kiện/ngoài phạm vi | Status đúng và không suy đoán | FR10 |
| TC12 | Mô tả nguy cơ và câu hỏi học gần giống | Redirect phù hợp, báo false/missed redirects trong đánh giá | FR10 |
| TC13 | Provider timeout, invalid JSON hoặc citation giả | unavailable/insufficient_evidence, không lộ raw output | FR10 |
| TC14 | Hỏi phát biểu sai trong trang quiz | Không dùng phương án sai làm lời khuyên | FR09, FR10 |
| TC15 | Từ chối vị trí/không có GPS | Vẫn xem danh bạ theo vùng | FR12, FR18 |
| TC16 | Có vị trí và cơ sở 24/7 UNKNOWN | Distance ghi đường thẳng; không gán huy hiệu xác nhận | FR13 |
| TC17 | Không mở được map/dialer | Hiện địa chỉ/số để tiếp tục, không crash | FR14 |
| TC18 | Public đoán ID bài draft, gọi API ghi thiếu auth | Không đọc draft; ghi bị chặn | FR15 |
| TC19 | Publish thiếu nguồn/sai trang/chưa kiểm | CONTENT_NOT_READY và lỗi rõ | FR16 |
| TC20 | Update bài bằng expected_revision cũ | 409 CONTENT_CONFLICT; không ghi đè | FR16 |
| TC21 | Xóa source/category có bài public | RESOURCE_IN_USE; không orphan | FR16 |
| TC22 | Thay source/article revision sau AI indexing | Gateway chặn citation cũ, không bỏ kiểm để hiển thị | FR09, FR11 |
| TC23 | CRUD cơ sở, thiếu tọa độ/sai phone | Validate và trạng thái active phù hợp | FR17 |
| TC24 | Font 200%, title dài, bàn phím chat | Nút chính không bị che; cuộn được | FR18 |

CPR P1 nếu triển khai cần thêm test play/stop, audio interruption, không tự resume và cấu hình nhịp có nguồn. Không đưa test này làm cổng chặn P0 nếu chức năng chưa làm.

## 7. Cách tổ chức test thực tế

Unit test logic chọn variant/search/distance/policy, integration cho auth/publish/snapshot/citation, widget/E2E smoke cho các luồng. Không cần automated UI cho mọi form ngay từ đầu; các ca thủ công được ghi thiết bị, dữ liệu, bước và kết quả. Không viết test chỉ phản chiếu implementation mà không có expectation độc lập.

Kiểm y khoa và usability là hai việc khác nhau. Người dùng thử giúp tìm lỗi đọc/điều hướng, không tự xác nhận nội dung y khoa đúng. Dùng 5–8 người cho vòng usability nhỏ, kịch bản giả lập; đo thời gian tìm bài, thao tác sai và việc hiểu đúng giới hạn chatbot/danh bạ. Không thử bằng nạn nhân thật.

## 8. Bộ bàn giao cuối

Mã nguồn và lockfile; README chạy từ đầu; `.env.example` không secret; migration/seed; app cài kiểm được; web Admin; API docs; source/corpus mapping; script build/evaluate RAG; báo cáo test; coverage 18 nhóm; video demo online/offline/lỗi; known limitations. Kết quả nghiệm thu và giới hạn được ghi trong báo cáo bàn giao hoặc task/PR. Bộ đặc tả không dùng để theo dõi tiến độ; chỉ sửa khi có quyết định thay đổi yêu cầu, kiến trúc hoặc contract.

## 9. Quy tắc cắt phạm vi khi chậm

Cắt CPR P1, hybrid/reranker, animation và trang trí trước. Giữ nội dung 18 nhóm, nguồn, offline core, CRUD cơ bản và RAG text. Có thể dùng retrieval-only trả đoạn/bài kiểm tra nếu generation không đạt chất lượng; ghi rõ quyết định và tác động trải nghiệm.

Không cắt bằng cách bỏ nhãn đối tượng, bịa bài để đủ 18, mở toàn bộ endpoint không auth hoặc bỏ fallback lỗi. Nếu không hoàn thành nội dung đúng nguồn thì báo chính xác phần thiếu; không gọi category rỗng là tình huống đã hỗ trợ.
