# First Aid Content Catalog

Baseline 2.0 | Tài liệu quản lý phạm vi và dữ liệu, **không phải bản phác đồ để sử dụng sơ cứu trực tiếp**.

## 1. Nguyên tắc tổ chức

Giữ đủ 18 nhóm tình huống trong ứng dụng. Mỗi nhóm là Category có mã FA01–FA18, thuộc một trong bốn group_code. Một Category có một hoặc nhiều Article tùy biến thể đối tượng/nguyên nhân. Chỉ thêm bài con khi có khác biệt cần thiết, không sao chép một bài để tăng số lượng.

Các bài dùng chung template, schema và renderer trong 06. Mục tiêu đủ nội dung không đồng nghĩa 18 flow tương tác hoặc 18 module code. Chỉ một số luồng ngắn ở FA01/FA02/FA03 có thể dùng lựa chọn cố định sau khi đã kiểm các nhánh.

## 2. Danh mục chính thức của baseline

| Code | Tên nhóm | group_code | Bài con/đối tượng cần xem xét | Từ khóa tìm kiếm gợi ý |
| --- | --- | --- | --- | --- |
| FA01 | Người bất tỉnh hoặc không đáp ứng | CIRCULATION | Phân biệt đối tượng và tình huống theo nguồn; không tự chẩn đoán nguyên nhân | bất tỉnh, không đáp ứng, bất động |
| FA02 | Ngừng tim và CPR/AED | CIRCULATION | Người lớn/trẻ em/nhũ nhi không dùng chung thủ thuật nếu khác; AED là section hoặc bài con | CPR, ép tim, hồi sức, AED |
| FA03 | Hóc dị vật | CIRCULATION | Người lớn, trẻ em, nhũ nhi; các tình huống đặc biệt chỉ khi có nguồn | hóc, nghẹn, sặc, dị vật |
| FA04 | Đuối nước | CIRCULATION | Chỉ dẫn an toàn người trợ giúp; đối tượng khác nhau khi nội dung yêu cầu | đuối nước, ngạt nước |
| FA05 | Chảy máu ngoài | TRAUMA | Phân biệt vết thương nhỏ với chảy máu nghiêm trọng; không tự thêm kỹ thuật nâng cao | chảy máu, cầm máu, mất máu |
| FA06 | Vết thương nhỏ và trầy xước | TRAUMA | Bài phổ thông; dẫn sang bài khác khi không còn phù hợp | trầy xước, đứt tay, vết thương |
| FA07 | Chảy máu cam | TRAUMA | Bài phổ thông có dấu hiệu cần trợ giúp | chảy máu cam, máu mũi |
| FA08 | Nghi gãy xương | TRAUMA | Bài cơ bản, giới hạn việc di chuyển/thao tác theo nguồn | gãy xương, nghi gãy, biến dạng |
| FA09 | Bong gân và trật khớp | TRAUMA | Có thể cần hai bài riêng; không làm người dùng hiểu là một tình trạng | bong gân, trật khớp, lật cổ chân |
| FA10 | Chấn thương đầu cổ hoặc cột sống | TRAUMA | Bài cơ bản về nhận biết, giới hạn và liên hệ hỗ trợ | chấn thương đầu, cổ, cột sống |
| FA11 | Bỏng | ENVIRONMENT | Bỏng nhiệt là bài đầu; hóa chất/điện có bài hoặc dẫn khác, không áp dụng mọi cách xử trí chung | bỏng, phỏng, nước nóng |
| FA12 | Điện giật | ENVIRONMENT | Nguồn nguy hiểm và an toàn hiện trường; không nhầm đáp án sai trong quiz | điện giật, rò điện |
| FA13 | Say nóng và sốc nhiệt | ENVIRONMENT | Phân biệt các mức/tình trạng bằng nội dung có nguồn; không khẳng định chẩn đoán | say nóng, sốc nhiệt, nắng nóng |
| FA14 | Dấu hiệu nghi đột quỵ | OTHER | Nhận biết và liên hệ hỗ trợ, không xác định loại đột quỵ | đột quỵ, méo miệng, yếu tay |
| FA15 | Co giật | OTHER | Hướng dẫn ban đầu và điều tránh; không đoán nguyên nhân | co giật, động kinh |
| FA16 | Dị ứng nặng và phản vệ | OTHER | Dấu hiệu cần hỗ trợ; không tự thêm liều hoặc chỉ định thuốc | phản vệ, dị ứng nặng |
| FA17 | Nghi ngộ độc | OTHER | Khác đường phơi nhiễm/nguyên nhân phải giữ giới hạn, không hướng dẫn gây nôn/thuốc tự do | ngộ độc, uống nhầm, hóa chất |
| FA18 | Động vật cắn và côn trùng đốt | OTHER | Chó/mèo cắn, rắn cắn, ong/côn trùng nên tách khi khác xử trí; không bắt user nhận loài để AI đoán | chó cắn, mèo cắn, rắn cắn, ong đốt |

Keyword là hỗ trợ tìm kiếm, không chứng minh triệu chứng đó xác định một bệnh. Các keyword không được dùng tự động để chọn thủ thuật trong guided flow. Tên/ID Category giữ ổn định; Article có thể được bổ sung sau đối chiếu nguồn.

## 3. Cấu trúc mỗi bài

| Section | Nội dung cần chuẩn bị | Field trong 06 |
| --- | --- | --- |
| Định danh | Tên, danh mục, bài con, người lớn/trẻ/nhũ nhi/dùng chung | title, category_id, variant_key, age_group |
| Phạm vi | Áp dụng khi nào, giới hạn đối tượng/bối cảnh | applies_to |
| Tóm tắt | Giải thích ngắn cho người không chuyên | summary |
| Nhận biết | Dấu hiệu có nguồn, không diễn đạt thành chẩn đoán chắc chắn | recognition |
| Cần làm ngay | Những ưu tiên đã kiểm, đủ điều kiện áp dụng | quick_actions |
| Từng bước | Một hành động/mục đích chính mỗi bước, không bỏ ngoại lệ | steps |
| Điều tránh | Hành động không phù hợp theo nguồn và phạm vi | warnings |
| Liên hệ hỗ trợ | Dấu hiệu/điều kiện cần gọi hoặc đến cơ sở | seek_help |
| Minh họa | Ảnh đúng nội dung, có quyền dùng, alt text | asset_key, image_url, alt_text |
| Nguồn | Tài liệu, edition, số trang PDF, section cần đối chiếu | references |
| Trạng thái | Draft/published và xác nhận đã kiểm | status, content_checked, checked_at |

Không tự đặt timer, tần số, độ sâu, liều hoặc giới hạn tuổi nếu nguồn chưa xác minh. Nếu một section không áp dụng, phải có diễn giải phù hợp thay vì lời khuyên bịa. Không giữ placeholder trong bài PUBLISHED.

## 4. Đối tượng và biến thể

Các nhãn ADULT, CHILD, INFANT và ALL là metadata dữ liệu, không phải lời khẳng định mọi trẻ cùng một nhóm đều thực hiện giống nhau. Phạm vi diễn giải phải theo nguồn. Ở FA02/FA03 cần kiểm đặc biệt việc không dùng nhầm bài giữa các nhóm.

Ví dụ variant_key kỹ thuật có thể là `adult_basic`, `child_basic`, `infant_basic`, `thermal_burn`, `dog_cat_bite`. Đây không phải danh sách bắt buộc; chỉ tạo khi có bài thật đủ nguồn. `variant_key` duy nhất trong category và giữ ổn định khi đổi tiêu đề. Nếu bài đã nêu rõ dùng chung thật, ALL hợp lệ; không dùng ALL để lấp thiếu nội dung nhi khoa.

Mục tiêu nghiệm thu đủ 18 nhóm có nội dung phù hợp người dùng đã chọn; không cam kết mọi nhóm đều có đủ mọi lứa tuổi trong bản đầu. UI phải cho biết nhóm nào chưa có biến thể tương ứng. Khi chưa có nội dung phù hợp, không chuyển sang adult mặc định.

## 5. Tài liệu đầu vào và vị trí cần chú ý

| Code nguồn | Tệp | Định danh đã xác nhận | Mục sử dụng |
| --- | --- | --- | --- |
| PNT2024 | CẨM NANG SƠ CẤP CỨU.pdf | CLB Cấp Cứu Ngoại Viện, trường ĐH Y khoa Phạm Ngọc Thạch, 2024, 47 trang PDF | Nguồn tham khảo cho nhiều tình huống cộng đồng |
| NHI2022 | TÀI LIỆU Sơ cấp cứu ban đầu thường gặp ở trẻ em, học sinh.pdf | BV Nhi Trung ương và Vụ Giáo dục thể chất, 2022, 112 trang PDF | Nguồn tham khảo trẻ em/trường học, cần lọc phạm vi và phần lượng giá |

UUID source phải thống nhất giữa backend seed và corpus; code trên chỉ business key. Không suy năm cập nhật hiện hành hoặc quyền tái sử dụng từ tên file. Trước bàn giao nội dung dùng thật, nhóm cần đối chiếu hướng dẫn phù hợp và xác nhận quyền hình/trích dẫn/chuyển thể.

Các vị trí đã đọc có ích cho rà soát dữ liệu, không phải bảng tự động phê duyệt:

- PNT2024 trang PDF 9 có mục lục; trang 10–13 có nguyên tắc; trang 14–15 dị vật; 16 chảy máu; 18–23 gãy xương/bong gân/trật khớp; 24 dị ứng; 25–30 động vật/côn trùng; 31–33 đột quỵ; 34 đuối nước; 35–37 bỏng; 38–41 điện; 42–45 CPR.
- NHI2022 trang 17–29 phần cấp cứu cơ bản; 58–66 dị vật; 84–90 điện giật/bỏng. Có nhiều câu hỏi lượng giá trong tài liệu, không chỉ các trang này.
- NHI2022 trang 89 có bài chọn đúng/sai chứa phát biểu về kéo dây điện bằng tay và không cần đến cơ sở y tế khi trẻ tỉnh lại. Đây là các phát biểu trong đề bài, không phải khuyến nghị đã được xác nhận đúng. Không ingest như lời hướng dẫn.
- NHI2022 trang 77 và 80 có nội dung thuốc/xử trí ngộ độc cần rà soát riêng; chatbot P0 không tư vấn liều hoặc lấy nguyên kỹ thuật vượt phạm vi cho cộng đồng.

Trang trên là thứ tự trang của PDF, có thể khác số in. Khi gắn citation, phải đối chiếu đúng trang hiện có, không dùng số bài/mục lục thay page_start.

## 6. Coverage matrix phải hoàn thành trước nghiệm thu

Nhóm tạo một bảng làm việc theo các cột: category_code, article_id, variant_key, age_group, source_code, pages, text_checked, image_ready, offline_ready, chat_evidence_ready, owner. Mỗi FA01–FA18 phải có ít nhất một bài đúng phạm vi đã kiểm; những nơi cần biến thể phải thể hiện coverage và thiếu sót rõ.

Không mặc định hai PDF có đủ bằng chứng cho mọi nhóm ở danh mục. Các mục như chảy máu cam, say nóng/sốc nhiệt, co giật hoặc phần cụ thể khác cần đối chiếu bằng trang thực sự tìm được; chưa có thì `[TODO / NEED SOURCE]`. Có thể bổ sung nguồn chính thức phù hợp sau kiểm tra. Không tự tạo source URL hoặc gán số trang để hoàn thành bảng.

## 7. Quy trình chuẩn bị nội dung vừa sức

1. Chia 18 nhóm cho các thành viên, thống nhất template 06.
2. Tìm evidence và ghi trang trước khi biên soạn.
3. Viết bài ngắn, dễ hiểu; giữ điều kiện/ngoại lệ quan trọng.
4. Thành viên khác kiểm lại so với trang gốc; xin ý kiến người có chuyên môn cho nội dung trọng yếu nếu có.
5. Chuẩn bị hình minh họa đúng nội dung và quyền dùng; hình có thể để sau text nhưng không bỏ qua khi bắt buộc để hiểu thao tác.
6. Đánh dấu content_checked, seed public/đưa vào corpus tương ứng.
7. Chạy UI offline và test câu hỏi/mẹo sai trước nghiệm thu.

Đây là checklist làm việc, không tạo role reviewer trong app. Nếu chưa đủ căn cứ chuyên môn để dùng thực tế, trình diễn trong bối cảnh mô phỏng và ghi đúng giới hạn; không dán nhãn phê duyệt chỉ vì một thành viên đã kiểm link.

## 8. Quy tắc cho hình và asset

Mỗi asset có key ổn định và tên rõ, ví dụ `fa11_thermal_step01_v1`; file nằm trong assets của mobile, mapping lưu cùng seed. Không chụp màn hình PDF rồi dùng toàn bộ nếu chưa kiểm quyền và độ rõ. Không dùng ảnh AI tự vẽ thao tác y khoa làm bằng chứng đúng. Có thể dùng placeholder có nhãn khi thiết kế Figma, nhưng bản public phải thay bằng hình được kiểm.

Hình không được là nơi duy nhất chứa chỉ dẫn quan trọng; text phải đủ dùng khi hình không tải/không hiển thị. Alt text mô tả đúng mục đích hình, không thêm hướng dẫn chưa có trong bài.

## 9. Tiêu chí nội dung hoàn thành

Đủ 18 nhóm có bài thật phù hợp phạm vi; nguồn/trang đọc lại được; không quiz sai trong corpus; không thiếu nhãn đối tượng; không hướng dẫn thuốc ngoài scope; không dùng fixture bệnh viện thật giả lẫn nhau; bài quick/learn lấy cùng dữ liệu; các biến thể không nhầm; ngày/nguồn được hiển thị. Những mục chưa hoàn thành phải được ghi vào known limitations, không ghi “đã đủ” theo số category seed.
