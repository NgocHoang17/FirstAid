# FirstAid: dịch vụ tra cứu có nguồn

FastAPI nội bộ dùng BM25 để tìm bài đã kiểm biên soạn. Chế độ `extractive` trả nguyên nội dung bài phù hợp, kèm nguồn. Chạy local bằng CPU, không cần API key, model GPU hoặc dịch vụ trả phí.

Đây là bước retrieval và trả lời trích xuất của RAG. Chưa có LLM để diễn giải hoặc tổng hợp nhiều bài. Không coi kết quả là chẩn đoán hoặc xác nhận chuyên môn y khoa.

## Chạy local

Yêu cầu Python 3.11. Chạy từ thư mục `ai/` bằng PowerShell:

```powershell
py -3.11 -m venv .venv
.venv/Scripts/python.exe -m pip install -r requirements-lock.txt
.venv/Scripts/python.exe -m firstaid_rag ../mobile/assets/content/reference_library.json data/index/corpus.json
$env:AI_INTERNAL_TOKEN = (.venv/Scripts/python.exe -c "import secrets; print(secrets.token_urlsafe(32))")
$env:AI_INDEX_PATH = 'data/index/corpus.json'
.venv/Scripts/python.exe -m uvicorn firstaid_rag.app:create_app --factory --host 127.0.0.1 --port 8001 --no-access-log
```

Giữ token trong biến môi trường. Dùng cùng giá trị cho `AI_INTERNAL_TOKEN` của Spring. Không ghi token vào Git, mobile hoặc ảnh chụp màn hình. `.env.example` chỉ mô tả cấu hình; dịch vụ không tự đọc tệp `.env`.

Đặt `AI_BASE_URL=http://127.0.0.1:8001` ở Spring trên cùng máy. Trong container, dùng địa chỉ mạng riêng của dịch vụ AI. Mobile tiếp tục gọi `/api/v1/assistant/query` của Spring.

Gọi kiểm tra từ terminal đã có biến token:

```powershell
$headers = @{ 'X-Internal-Token' = $env:AI_INTERNAL_TOKEN }
Invoke-RestMethod http://127.0.0.1:8001/health -Headers $headers
$body = @{ request_id = [guid]::NewGuid().ToString(); message = 'Kiến thức sơ cứu bỏng nhiệt nhẹ'; age_group = $null; context_mode = 'learning' } | ConvertTo-Json
Invoke-RestMethod http://127.0.0.1:8001/internal/v1/query -Method Post -Headers $headers -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($body))
```

## Corpus và nguồn

Builder nhận thư viện `reference_library` schema 2 hoặc public snapshot schema 1. Snapshot có thể có envelope `data`. Chỉ lấy bài PUBLISHED, đã kiểm và có danh mục active. Builder kiểm UUID, revision, nguồn active và trang PDF hợp lệ. Mỗi bài là một evidence unit đầy đủ, gồm phạm vi, nhận biết, hành động, bước, cảnh báo và tìm trợ giúp.

Builder không nhận raw PDF. Các trường quiz, đáp án, ghi chú nội bộ và thiết kế không được đưa vào index. Nội dung biên soạn vẫn cần được kiểm trước khi đánh dấu `content_checked`. Một nhãn trong JSON không tự chứng minh chất lượng y khoa.

Artifact có hash dữ liệu và `corpus_version`. Ghi tệp tạm rồi thay thế nguyên khối. Hash phát hiện hỏng tệp, không phải chữ ký xác thực. Bảo vệ quyền ghi thư mục index. Không commit PDF gốc, index hoặc báo cáo chạy local.

Khi tích hợp, build từ snapshot của chính backend đang chạy. Dừng và khởi động lại AI sau khi thay artifact. Spring phải kiểm lại source/article revision và trạng thái public cho từng response. Các bài bị gỡ hoặc sửa trên backend không được tiếp tục dùng bằng chứng cũ.

`AI_MAX_REVIEW_DAYS` mặc định 180, cho phép 1 đến 365. Evidence quá hạn bị loại khi truy vấn. Đây là giới hạn vận hành, không phải thời hạn hiệu lực y khoa. Kiểm lại nguồn trước khi cập nhật ngày kiểm.

## Phản hồi và giới hạn

- Sự cố đang xảy ra: `emergency_redirect`, không tạo hướng dẫn mới.
- Thiếu tuổi cho CPR, hóc dị vật, đuối nước: `clarification_needed`. Người dùng chọn tuổi rồi gửi lại câu hỏi đầy đủ.
- Bài dùng chung: trả nội dung ALL cho người lớn và trẻ em. Nhũ nhi ngoài phạm vi.
- Thiếu evidence, sai phạm vi hoặc nội dung hết hạn: không suy diễn bằng kiến thức bên ngoài.
- Nguồn và citation lấy từ artifact, không lấy từ lời người hỏi.
- Thiếu/hỏng index: health 503, câu hỏi kiến thức trả `unavailable`. Policy khẩn cấp vẫn hoạt động.

Bộ phân loại dùng quy tắc tiếng Việt, có thể bỏ sót cách diễn đạt, lỗi chính tả hoặc ngữ cảnh phức tạp. Các alias chỉ phục vụ tìm kiếm. BM25 score không biểu thị độ tin cậy y khoa. Câu trả lời hiện là bài đầy đủ; chưa tối ưu thành câu trả lời ngắn theo ý hỏi. Mỗi request độc lập, không lưu lịch sử chat.

Dịch vụ chỉ lắng nghe localhost hoặc mạng riêng. Không mở trực tiếp ra Internet. Spring chịu trách nhiệm session Admin, giới hạn request public và timeout 12 giây. Chế độ trích xuất không gọi provider và không có retry tự động.

## Kiểm thử

```powershell
.venv/Scripts/python.exe -m pytest -q
.venv/Scripts/python.exe evaluation/run.py
```

Đọc [phương pháp đánh giá](evaluation/README.md). Kiểm tích hợp cuối cần backend/database thật, cùng bộ bài public, ID và revision. Bộ tham khảo trong mobile không tự thay seed DRAFT của backend. Không nới điều kiện kiểm citation để làm demo chạy.
