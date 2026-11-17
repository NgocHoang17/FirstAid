# Đánh giá RAG local

`cases.py` chứa 120 câu tự biên soạn để kiểm hồi quy phần mềm: 60 kiến thức, 20 sự cố, 15 thiếu hoặc mâu thuẫn dữ kiện, 15 phạm vi và 10 injection/quiz. Gold label chỉ định trạng thái và variant bài từ catalogue đã kiểm. Không sinh gold label bằng kết quả tìm kiếm.

Các nhóm diễn đạt tương đương nằm cùng split: 40 câu tune, 80 câu test. Script kiểm hai split không trùng family. Tuy nhiên bộ câu hỏi do cùng bên triển khai biên soạn. Các lỗi đã được dùng để sửa chương trình. Vì vậy đây là regression suite, không phải tập đánh giá độc lập hoặc test chưa từng xem.

Chạy từ `ai/`:

```powershell
.venv/Scripts/python.exe evaluation/run.py --output evaluation/results.json
```

Report gồm trạng thái mong đợi/thực tế, Recall@5 cho câu có gold article, độ hợp lệ citation và thời gian xử lý trong engine. Recall đo pipeline đã lọc topic/tuổi. Không gọi đây là kết quả BM25 thuần. Citation hợp lệ nghĩa là ID, revision và trang khớp artifact; không chứng minh một khẳng định đúng về lâm sàng. Độ trễ không gồm mạng, Spring hoặc điện thoại.

Script trả exit code khác 0 khi sai trạng thái, sai bài hoặc citation không hợp lệ. Báo cáo sinh ra chỉ lưu local. Khi catalogue đổi, rà lại gold label và chạy lại cả unit tests lẫn đánh giá.

Trước nghiệm thu, bổ sung câu hỏi do thành viên khác viết, câu không dấu, lỗi gõ, phủ định và các đoạn trộn học tập với sự cố. Giữ riêng tập này trước khi điều chỉnh quy tắc. Chạy chuỗi mobile, Spring, AI và kiểm trường hợp backend đã gỡ bài hoặc tăng revision.

Nội dung của đồ án được đối chiếu tài liệu, không có chuyên gia y tế trực tiếp thẩm định. Không dùng tỷ lệ vượt test để quảng bá độ chính xác y khoa.
