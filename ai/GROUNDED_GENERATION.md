# Grounded Generation và hội thoại

## Luồng xử lý

1. Kiểm nguy cơ và phạm vi của tin nhắn mới.
2. Dùng tối đa bốn câu hỏi trước để nối chủ đề; không dùng lịch sử như bằng chứng y khoa.
3. Truy xuất bài đúng chủ đề, đối tượng và revision từ corpus đã đối chiếu nguồn.
4. Chọn phần liên quan, gửi câu hỏi, ngữ cảnh và bài nguồn tới mô hình.
5. Sinh JSON có khối nội dung và evidence_ids theo prompt trong `firstaid_rag/prompts.py`.
6. Kiểm schema, ID bằng chứng, số liệu mới và các dấu hiệu chỉ dẫn không có trong nguồn.
7. Gọi lượt kiểm hỗ trợ bằng chứng riêng trước khi dùng phần sinh.
8. Gắn phạm vi, cảnh báo và điều kiện tìm trợ giúp từ nguồn. Giữ citation để gateway kiểm.

Prompt ưu tiên tiếng Việt tự nhiên, lời dẫn ngắn và các bước rõ ràng. Prompt không chứa phác đồ ví dụ tự sáng tác. Chỉ thị trong câu hỏi, lịch sử hoặc tài liệu là dữ liệu, không có quyền thay chính sách.

Đầu ra giữ `answer_blocks[].text`, `citation_ids` và bổ sung `kind`: paragraph, heading, steps, warning, help. Client dùng kind để trình bày; không hiển thị nguồn trong màn chat. `generation_mode` cho biết từng phản hồi thực sự dùng extractive hay grounded.

Nếu mô hình không trả đúng schema, thêm số liệu/ID lạ, không đạt kiểm hỗ trợ, hết thời gian hoặc không kết nối được, hệ thống dùng nội dung trích xuất có nguồn. Câu hỏi giải thích mà nguồn chưa đủ không được thay bằng một câu trả lời suy diễn.

## Cấu hình kết nối

Provider chính là Gemini API cloud, gọi từ dịch vụ AI phía server bằng [generateContent](https://ai.google.dev/api/generate-content) với JSON schema. Mobile không gọi Gemini trực tiếp. Ollama chỉ còn là adapter tùy chọn cho môi trường đã có model local.

Sao chép `ai/generation.example.json` thành `.local/generation.json`. Mặc định:

```json
{
  "mode": "extractive",
  "provider": "gemini",
  "model": "gemini-3.8-flash",
  "generation_timeout_seconds": 30,
  "gateway_timeout_seconds": 35
}
```

### Bật Gemini trên máy phát triển

1. Tạo khóa tại [Google AI Studio](https://aistudio.google.com/apikey). Model mẫu là `gemini-3.8-flash`; có thể đổi sang model hỗ trợ structured output được cấp quyền cho project của nhóm, theo [danh sách model](https://ai.google.dev/gemini-api/docs/models).
2. Tạo `.local/gemini-key.txt` ở thư mục gốc dự án, dán duy nhất API key vào đó và lưu. Hoặc khai báo biến môi trường `GEMINI_API_KEY` trước khi chạy launcher; biến môi trường được ưu tiên. Không gửi khóa trong chat, không đặt vào Flutter hoặc file cấu hình mẫu trên Git. Thư mục `.local/` đã được Git bỏ qua.
3. Sao chép cấu hình mẫu ở trên vào `.local/generation.json`, đổi `mode` thành `grounded`. Không thêm API key vào JSON. File JSON chỉ chứa lựa chọn provider/model và thời gian chờ.
4. Khởi động lại dịch vụ bằng các lệnh bên dưới rồi chạy `flutter run` từ `mobile/`. Thời gian chờ chat mặc định của mobile là 40 giây.

Khi bật `grounded`, câu hỏi hiện tại, tối đa bốn câu hỏi trước và các đoạn tài liệu truy xuất sẽ được gửi tới Gemini. Mỗi lượt có tối đa hai lần gọi model (soạn và kiểm); hạn mức và chi phí áp dụng theo project Gemini. Không gửi toàn bộ PDF hoặc toàn bộ corpus. Với ảnh học liệu, dịch vụ FastAPI kiểm tra JPEG/PNG, giải mã trong bộ nhớ, loại metadata, thu cạnh dài xuống tối đa 1024 px rồi gửi một ảnh đến Gemini. Model chỉ trả mã chủ đề hoặc yêu cầu làm rõ. Câu trả lời lấy từ bài đã đối chiếu trong corpus. Phần này cần gateway Spring chuyển tiếp multipart theo hợp đồng 9.1 và khóa Gemini ở server.

Khi thành viên pull code: cài dependency như README rồi chạy stack. Cấu hình mẫu được theo dõi trên Git; API key và cấu hình local không được đồng bộ. Không có cấu hình thì mặc định `extractive`, vẫn tra cứu tài liệu được. Muốn bật Gemini trên từng máy phát triển, mỗi máy phải có cấu hình và khóa được cấp riêng. Nếu dùng server chung, chỉ server giữ khóa, app của các thành viên kết nối backend chung.

Chạy `tools/start-local.ps1 -Stop`, sau đó `tools/start-local.ps1` từ thư mục gốc để áp dụng cấu hình toàn bộ stack. File cấu hình và model runtime không lên Git. Launcher khởi động lại RAG khi mã AI hoặc cấu hình sinh thay đổi.

Chạy từ thư mục gốc:

```powershell
.\tools\start-local.ps1 -Stop
.\tools\start-local.ps1
cd mobile
flutter run
```

Nếu thay thời gian chờ, có thể cấu hình mobile bằng:

```powershell
flutter run --dart-define=AI_CHAT_TIMEOUT_SECONDS=40
```

Ngân sách sinh dùng chung cho lượt soạn và lượt kiểm. Gateway phải chờ lâu hơn ngân sách sinh; mobile phải chờ lâu hơn gateway. Các mốc là cấu hình, không phải kết quả đo trên phần cứng.

Nếu chạy FastAPI riêng, khai báo `AI_GENERATION_MODE=grounded`, `AI_GENERATION_PROVIDER=gemini`, `AI_GEMINI_MODEL`, `GEMINI_API_KEY` và `AI_GENERATION_TIMEOUT_SECONDS=30` trong môi trường tiến trình. `.env.example` chỉ là mẫu, FastAPI không tự nạp file này. Đặt `AI_REQUEST_TIMEOUT_SECONDS=35` cho Spring. Không cần cài SDK model trong Flutter hoặc Ollama trên máy thành viên.

Để dùng adapter local tùy chọn, đặt `provider: "ollama"`, thêm `ollama_url` và tên `model` vào JSON. Khi chạy AI riêng, dùng `AI_GENERATION_PROVIDER=ollama`, `AI_OLLAMA_URL` và `AI_OLLAMA_MODEL`. Không tự tải model.

### Kiểm tra sau cấu hình

Launcher từ chối bật Gemini nếu chưa có khóa. Nếu chạy FastAPI riêng và cấu hình model sai, corpus vẫn được nạp và dùng chế độ trích xuất. Khóa sai, hết quota (429), provider lỗi, JSON không hợp lệ hoặc kết quả bị chặn/hết token đều dẫn tới fallback có nguồn, không trả nguyên thông báo lỗi/khóa cho mobile. Không tự retry để tránh tăng chi phí.

`/health` nội bộ cần `X-Internal-Token`; mode `grounded` chỉ xác nhận adapter đã được cấu hình. Kiểm response `/internal/v1/query` hoặc phản hồi gateway: `generation_mode: "grounded"` mới xác nhận câu trả lời đó thực sự qua model và lượt kiểm. `extractive` nghĩa là không dùng model hoặc đã fallback.

## Kiểm và giới hạn

Kiểm thử tự động bao phủ prompt/schema, ID giả, số liệu thêm, model lỗi, lượt kiểm từ chối và việc không gửi sự cố khẩn cấp tới mô hình. Các test provider dùng MockTransport để kiểm hợp đồng, không chứng minh chất lượng của model thật.

JSON đúng cấu trúc và citation tồn tại không tự chứng minh tính đúng của diễn giải. Lượt kiểm ngữ nghĩa cũng có thể sai, nhất là khi dùng cùng model. Cần chạy đánh giá với model thật cho phủ định, đối tượng, số/đơn vị, thiếu bằng chứng và prompt injection trước khi công bố chế độ sinh.

Chỉ gọi một lượt sinh tại một thời điểm trong mỗi tiến trình AI. Khi bận, dùng fallback trích xuất để tránh xếp hàng vô hạn. Không lưu raw câu hỏi, bản sinh hoặc ảnh vào log. `/health` thể hiện cấu hình chế độ; `generation_mode` trong từng câu trả lời mới phản ánh kết quả xử lý thực tế.
