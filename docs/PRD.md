# PRD: Hệ thống Trợ lý Sơ cứu Y tế Khẩn cấp & Điều phối Hỗ trợ Cộng đồng (FirstAid)

**Phiên bản:** 0.1  
**Ngày:** 2026-09-11    
**Chủ sở hữu:** Nhóm FirstAid

## 1. Giới thiệu tổng quan 
Tai nạn sinh hoạt và sự cố giao thông đòi hỏi phản xạ sơ cứu chính xác trong "thời gian vàng" trước khi nhân viên y tế tiếp cận hiện trường. Tại Việt Nam, nhiều người dân xử lý sai cách (như bôi kem đánh răng lên vết bỏng, di chuyển người gãy cột sống) dẫn đến biến chứng nguy hiểm.

**FirstAid AI** là nền tảng di động đa nền tảng (Flutter) tích hợp AI nhằm cung cấp hai giá trị cốt lõi:
1. **Phản ứng khẩn cấp (Emergency Mode):** Sàng lọc nhanh tình trạng nạn nhân, hướng dẫn từng bước bằng giọng nói (TTS), phát nhịp đếm CPR và định vị trạm y tế gần nhất trên bản đồ.
2. **Đào tạo kỹ năng thường ngày (Handbook & AI Simulation):** Cung cấp cẩm nang tình huống đời sống và phòng luyện tập phản xạ qua kịch bản tương tác với AI.

Hệ thống hoạt động theo cơ chế **Hybrid Offline-first**: Tự động tận dụng mô hình AI qua backend khi có mạng và tự động chuyển sang dữ liệu cục bộ khi mất kết nối.

---

## 2. Mục tiêu sản phẩm 
* Cung cấp luồng sơ cứu khẩn cấp kích hoạt trong vòng **1 chạm** (không bắt buộc đăng nhập).
* Đảm bảo hướng dẫn sơ cứu tuân thủ 100% phác đồ của Hội Chữ thập đỏ Việt Nam và Bộ Y tế, loại bỏ hoàn toàn hiện tượng ảo giác (Zero-Hallucination).
* Duy trì độ trễ phản hồi API hệ thống dưới **1.5 giây** đối với các tác vụ cấp cứu.
* Đảm bảo ứng dụng hoạt động ngoại tuyến (Offline Fallback) đối với toàn bộ các bước sơ cứu sinh tử (CPR, hóc dị vật, cầm máu khẩn cấp).
* Xây dựng module luyện tập mô phỏng tương tác giúp tăng tỷ lệ phản xạ đúng của người dùng lên ít nhất 40%.

---

## 3. Người dùng mục tiêu 
- Persona 1 (Người ứng cứu tại chỗ - First Responder): Sinh viên/Người đi đường chứng kiến tai nạn, không có kiến thức y khoa, dễ hoảng loạn, cần hướng dẫn 1 chạm, dứt khoát và ngắn gọn.

- Persona 2 (Người học chủ động - Learner): Bố mẹ trẻ hoặc nhân viên văn phòng muốn tự trang bị kiến thức sơ cứu bỏng, hóc dị vật cho con cái lúc rảnh rỗi.

---

## 4. Danh sách User Stories

### US-001: Kích hoạt Chế độ Khẩn cấp 1 chạm
**Mô tả:** Là một người gặp sự cố tai nạn, tôi muốn mở ngay giao diện sơ cứu khẩn cấp mà không cần đăng nhập hay qua các bước cấu hình để có thể cứu người kịp thời.

**Tiêu chí chấp nhận (Acceptance Criteria):**
- [ ] Màn hình chính có nút "CẤP CỨU KHẨN CẤP" kích thước lớn, màu đỏ tương phản cao.
- [ ] Bấm vào nút chuyển ngay đến giao diện sàng lọc (Triage) trong dưới 300ms.
- [ ] Không hiển thị bất kỳ pop-up yêu cầu đăng nhập hay xác thực nào.

---

### US-002: Sàng lọc nhanh tình trạng nạn nhân (Triage Flow)
**Mô tả:** Là người sơ cứu tại hiện trường, tôi muốn trả lời nhanh các câu hỏi sàng lọc có/không để hệ thống xác định ngay phác đồ cấp cứu phù hợp.

**Tiêu chí chấp nhận (Acceptance Criteria):**
- [ ] Hiển thị 3 câu hỏi liên tiếp: (1) Còn tỉnh không? (2) Còn thở không? (3) Có chảy máu xối xả không?
- [ ] Nút bấm lựa chọn "CÓ" / "KHÔNG" to, rõ ràng, chiếm tối thiểu 40% diện tích màn hình.
- [ ] Nếu "Bất tỉnh + Ngừng thở", tự động kích hoạt ngay phác đồ CPR (Ép tim ngoài lồng ngực).

---

### US-003: Chỉ dẫn sơ cứu từng bước qua Giọng nói (TTS) & Nhịp đếm CPR
**Mô tả:** Là người đang trực tiếp dùng 2 tay ép tim hoặc băng bó, tôi muốn điện thoại tự động đọc to từng bước và phát nhịp đếm để tôi không cần nhìn vào màn hình.

**Tiêu chí chấp nhận (Acceptance Criteria):**
- [ ] Tích hợp Text-to-Speech tự động đọc rõ ràng khẩu lệnh của từng bước hành động.
- [ ] Có nút "Bước tiếp theo" và "Lặp lại bước này" dạng floating button lớn.
- [ ] Trong phác đồ CPR, tích hợp âm thanh nhịp gõ chuẩn 100–120 bpm (chuẩn AHA) có công tắc bật/tắt.
- [ ] Hoạt động trơn tru cả khi không có kết nối mạng (dùng local TTS engine).

---

### US-004: Chụp ảnh phân loại vết thương sơ bộ (Multimodal Vision API)
**Mô tả:** Là người dùng lúng túng trước vết thương, tôi muốn chụp ảnh để hệ thống phân tích nhóm tổn thương và đưa ra các cảnh báo "Không được làm".

**Tiêu chí chấp nhận (Acceptance Criteria):**
- [ ] Giao diện camera cho phép chụp ảnh trực tiếp vết thương.
- [ ] Backend Spring Boot tiếp nhận multipart/form-data, forward sang AI Engine và trả về nhóm tổn thương (Bỏng, Vết cắt sâu, Bầm tím).
- [ ] Hiển thị danh sách: Thẻ đỏ (TUYỆT ĐỐI KHÔNG ĐƯỢC LÀM) và Thẻ xanh (NÊN LÀM NGAY).
- [ ] Nếu mất mạng: Hiển thị bộ sưu tập ảnh tĩnh để người dùng tự nhận dạng thủ công.

---

### US-005: Bản đồ định vị cơ sở y tế gần nhất
**Mô tả:** Là người sơ cứu, tôi muốn xem nhanh vị trí trạm y tế/bệnh viện gần nhất để điều hướng di chuyển hoặc nhờ người hỗ trợ đưa nạn nhân đi viện.

**Tiêu chí chấp nhận (Acceptance Criteria):**
- [ ] Lấy tọa độ GPS của thiết bị khi được cấp quyền.
- [ ] Backend Spring Boot cung cấp API truy vấn danh sách cơ sở y tế theo bán kính (haversine formula hoặc PostGIS).
- [ ] Hiển thị tối thiểu 3 cơ sở y tế gần nhất kèm khoảng cách và nút mở ứng dụng bản đồ chỉ đường (Google Maps/Apple Maps).

---

### US-006: Thư viện Cẩm nang Tình huống Sơ cứu Ngoại tuyến
**Mô tả:** Là người dùng muốn trau dồi kỹ năng, tôi muốn tra cứu các bài hướng dẫn xử lý sự cố sinh hoạt thường ngày mà không cần mạng Internet.

**Tiêu chí chấp nhận (Acceptance Criteria):**
- [ ] Phân loại bài viết rõ ràng: Sinh hoạt gia đình, Học đường/Công sở, Dã ngoại/Thiên tai.
- [ ] Có ô tìm kiếm theo từ khóa thông thường (ví dụ: gõ "bỏng nước sôi" tự chuyển đến bài "Sơ cứu bỏng nhiệt").
- [ ] Toàn bộ nội dung bài viết và hình ảnh đồ họa được lưu trong local storage (Hive/Isar) trên mobile.
- [ ] Backend cung cấp API đồng bộ dữ liệu phiên bản mới khi có mạng.

---

### US-007: Mô phỏng Tình huống Luyện tập Tương tác với AI
**Mô tả:** Là người học, tôi muốn tham gia kịch bản mô phỏng tương tác để AI đánh giá xem cách phản xạ của tôi đã chuẩn xác hay chưa.

**Tiêu chí chấp nhận (Acceptance Criteria):**
- [ ] Hệ thống đưa ra 1 kịch bản ngẫu nhiên (ví dụ: "Gặp người ngã xe máy nằm giữa đường, xung quanh có mùi xăng").
- [ ] Người dùng nhập giải pháp xử lý bằng văn bản.
- [ ] Backend xử lý prompt guardrails kết hợp AI API để chấm điểm, chỉ ra vi phạm an toàn hiện trường hoặc sai lệch y tế.
- [ ] Hiển thị thông báo yêu cầu kết nối Internet nếu người dùng kích hoạt lúc ngoại tuyến.

---

## 5. Yêu cầu chức năng (Functional Requirements)
* **FR-1:** Ứng dụng di động phải lưu trữ toàn bộ cây quyết định sàng lọc y tế (Triage Decision Tree) và dữ liệu cẩm nang cục bộ bằng Isar hoặc Hive DB.
* **FR-2:** Khi bấm nút khẩn cấp, hệ thống phải kiểm tra kết nối: nếu có mạng sẽ gọi backend Spring Boot; nếu mất mạng phải fallback sang local database trong 100ms mà không làm gián đoạn trải nghiệm người dùng.
* **FR-3:** Hệ thống tích hợp bộ đếm nhịp âm thanh metronome 100–120 bpm với độ trễ âm thanh dưới 20ms trong màn hình hướng dẫn CPR.
* **FR-4:** Backend phải serialize và validate toàn bộ payload AI sang chuẩn DTO định dạng JSON nghiêm ngặt (chống sinh văn bản tự do ngoài cấu trúc).
* **FR-5:** Endpoint định vị trên Spring Boot phải tính toán và trả về danh sách các cơ sở y tế gần nhất sắp xếp theo khoảng cách tăng dần.
* **FR-6:** Module luyện tập tình huống phải có cơ chế filter (Domain Guardrail) để từ chối các câu hỏi không liên quan đến sơ cấp cứu y tế.

---

## 6. Phạm vi không thực hiện (Non-Goals)
* Không xây dựng chức năng chẩn đoán bệnh lý lâm sàng mạn tính hoặc kê đơn thuốc điều trị.
* Không tự động thực hiện cuộc gọi VoIP nội bộ mà chỉ kích hoạt trình gọi điện thoại mặc định (Tel Dialer) của hệ điều hành đến đầu số 115.
* Không xây dựng hệ thống quản lý hồ sơ bệnh án điện tử (EMR/EHR) phức tạp.
* Không xử lý video stream thời gian thực độ phân giải cao tại hiện trường (chỉ chụp ảnh tĩnh để tối ưu băng thông và độ trễ).

---

## 7. Yêu cầu thiết kế UI/UX (Design Considerations)
* **Màu sắc chủ đạo:** Chế độ khẩn cấp sử dụng nền tối (Dark mode) kết hợp màu đỏ cảnh báo (#D32F2F) và vàng (#FBC02D) để đạt độ tương phản tối đa ngoài trời.
* **Kích thước thành phần:** Chiều cao tối thiểu của các nút bấm trong chế độ khẩn cấp là 60dp để tránh bấm nhầm khi tay run hoặc hoảng loạn.
* **Đơn giản hóa điều hướng:** Triệt tiêu hoàn toàn drawer menu, tab bar và các pop-up khi đang trong luồng cấp cứu khẩn cấp.

---

## 8. Yêu cầu kỹ thuật (Technical Considerations)
* **Mobile Client:** Flutter Framework ($\ge$ 3.19), quản lý trạng thái bằng BLoC/Riverpod, thư viện âm thanh `audioplayers`, Text-to-Speech `flutter_tts`, định vị `geolocator`.
* **Backend Gateway:** Java 17+, Spring Boot 3.x, Spring Data JPA, Spring Web, Spring Security (cho phân hệ quản trị/nội dung), đóng gói Docker container.
* **Database:** PostgreSQL hoặc MySQL cho Backend; Hive/Isar Database cho Mobile Local Storage.
* **AI Integration:** Spring Boot sử dụng Spring AI hoặc REST Client gọi API Foundation Model (Gemini/OpenAI), áp dụng JSON Schema binding vào Java Record/DTO để loại bỏ ảo giác.

---

## 9. Chỉ số đo lường thành công (Success Metrics)
* **Thời gian tiếp cận phác đồ:** Người dùng từ màn hình khóa điện thoại vào đến bước hướng dẫn CPR đầu tiên trong thời gian 8 giây.
* **Độ trễ phản hồi ngoại tuyến:** Toàn bộ luồng chuyển bước và phát âm thanh offline thực thi tức thì  100ms.
* **Độ chuẩn xác phác đồ:** Tỷ lệ tuân thủ hướng dẫn của Hội Chữ thập đỏ Việt Nam và Bộ Y tế đạt 100% trong bộ test benchmark gồm 50 ca thử nghiệm.
* **Tính sẵn sàng của backend:** Backend Spring Boot phản hồi các API tra cứu cơ sở y tế và cẩm nang dưới 500ms ở điều kiện mạng bình thường.

---

## 10. Open Questions
* Nhóm sẽ sử dụng OpenStreetMap (miễn phí, tích hợp qua Nominatim/Overpass API) hay Google Maps SDK cho module tìm kiếm cơ sở y tế gần nhất?