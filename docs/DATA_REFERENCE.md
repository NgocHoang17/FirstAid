# Dữ liệu chuẩn tham chiếu sơ cứu FirstAid

**Mã tài liệu:** DATA-001  
**Phiên bản:** 2.0  
**Ngày đối chiếu nguồn:** 28/10/2026  
**Tính chất:** Bản biên soạn tham khảo, chưa có xác nhận chuyên môn độc lập.  
**Phạm vi:** Người lớn và trẻ em. Không bao gồm nhũ nhi.

Tài liệu quy định nội dung và nguồn cho đủ 18 nhóm. Đây không phải báo cáo tiến độ hoặc chứng nhận an toàn y khoa.
Chỉ dùng hướng dẫn trong phạm vi và đối tượng của từng bài. Không suy có từ khóa là đã có phác đồ phù hợp.

## Mục lục

- [1. Quy tắc dữ liệu](#1-quy-tắc-dữ-liệu)
- [2. Danh sách nguồn](#2-danh-sách-nguồn)
- [3. Độ phủ hai PDF](#3-độ-phủ-hai-pdf)
- [4. Hợp đồng và đối tượng](#4-hợp-đồng-và-đối-tượng)
- [5. Nội dung theo 18 nhóm](#5-nội-dung-theo-18-nhóm)
- [6. Loại trừ và kiểm duyệt](#6-loại-trừ-và-kiểm-duyệt)

## 1. Quy tắc dữ liệu

- Bộ dữ liệu gốc: [reference_library.json](../mobile/assets/content/reference_library.json). Tài liệu này được sinh từ cùng dữ liệu.
- Giữ mã nhóm FA01–FA18. Mỗi bài có variant_key và age_group riêng, không nhân bản tùy ý sang nhóm tuổi khác.
- Hướng dẫn được diễn giải lại bằng tiếng Việt, không sao chép PDF hoặc hình gốc vào app.
- Quick và learn dùng cùng bài, bước và nguồn. Quick đổi cách trình bày, không cắt điều kiện áp dụng.
- Nội dung là bản thảo DRAFT, content_checked=false. Chỉ xem trong bản phát triển, không tự phát hành trên release.
- Không gắn nhãn đã được chuyên gia xác nhận khi chưa có người kiểm duyệt chuyên môn.
- Số liên hệ khẩn được địa phương hóa thành 115 cho Việt Nam. Không đưa số NHS/Anh vào nút gọi của app.
- Không chờ đủ thời gian theo dõi nếu có dấu hiệu đe dọa tính mạng.

## 2. Danh sách nguồn

| Mã | Tên tài liệu | Biên soạn / phát hành | Năm xuất bản | Loại |
| --- | --- | --- | --- | --- |
| PNT2024 | CẨM NANG SƠ CẤP CỨU | CLB Cấp Cứu Ngoại Viện, Hội Sinh viên Việt Nam trường Đại học Y khoa Phạm Ngọc Thạch | 2024 | PDF |
| NHI2022 | Hướng dẫn sơ cấp cứu ban đầu tai nạn thương tích thường gặp ở trẻ em, học sinh | Bệnh viện Nhi Trung ương và Vụ Giáo dục thể chất, Bộ Giáo dục và Đào tạo | 2022 | PDF |
| RCUK_BLS2025 | [Adult basic life support Guidelines](https://www.resus.org.uk/professional-library/2025-resuscitation-guidelines/adult-basic-life-support-guidelines) | Resuscitation Council UK | 2025 | WEB |
| RCUK_PLS2025 | [Paediatric Life Support (basic and advanced)](https://www.resus.org.uk/cy/node/36439) | Resuscitation Council UK | 2025 | WEB |
| RCUK_FIRSTAID2025 | [First Aid Guidelines](https://www.resus.org.uk/professional-library/2025-resuscitation-guidelines/first-aid-guidelines) | Resuscitation Council UK | 2025 | WEB |
| NHS_HEAT | [Heat exhaustion and heatstroke](https://www.nhs.uk/conditions/heat-exhaustion-heatstroke/) | NHS | Không nêu | WEB |
| NHS_SEIZURE | [What to do if someone has a seizure (fit)](https://www.nhs.uk/symptoms/what-to-do-if-someone-has-a-seizure-fit/) | NHS | Không nêu | WEB |
| NHS_NOSE | [Nosebleed](https://www.nhs.uk/conditions/nosebleed/) | NHS | Không nêu | WEB |
| NHS_POISON | [Poisoning](https://www.nhs.uk/conditions/poisoning/) | NHS | Không nêu | WEB |
| NHS_ANAPHYLAXIS | [Anaphylaxis](https://www.nhs.uk/conditions/anaphylaxis/) | NHS | Không nêu | WEB |
| NHS_BURNS | [Burns and scalds](https://www.nhs.uk/conditions/burns-and-scalds/) | NHS | Không nêu | WEB |
| NHS_CUTS | [Cuts and grazes](https://www.nhs.uk/conditions/cuts-and-grazes/) | NHS | Không nêu | WEB |
| NHS_STROKE | [Symptoms of a stroke](https://www.nhs.uk/conditions/stroke/symptoms/) | NHS | Không nêu | WEB |
| WHO_RABIES | [Rabies](https://www.who.int/news-room/fact-sheets/detail/rabies) | World Health Organization | 2026 | WEB |

Hai nguồn gốc người dùng cung cấp: PNT2024, 47 trang PDF; NHI2022, 112 trang PDF. NHI là tài liệu tập huấn, có cả bài học và lượng giá.
Nguồn WEB là nguồn bổ sung chính thức, không phải nội dung trong hai PDF. Ngày truy cập không được thay cho năm xuất bản.
Năm 2025 của RCUK là năm công bố ghi trên trang. NHS không nêu năm xuất bản nên để trống, dù có ngày rà soát.
Giao diện người dùng chỉ hiện tên tài liệu, đơn vị biên soạn và năm. Trang trích dẫn và ghi chú đối chiếu chỉ phục vụ dữ liệu nội bộ.

## 3. Độ phủ hai PDF

Mức độ: có hướng dẫn; có một phần; cần hiệu chỉnh; chỉ nhắc đến; không tìm thấy hướng dẫn.
Số trang dưới đây là thứ tự trang PDF, không suy từ số in. Khoảng trang được kiểm trong bản người dùng cung cấp.

| Mã | Tình huống | PNT2024 | NHI2022 | Đối tượng có bài | Số biến thể |
| --- | --- | --- | --- | --- | --- |
| FA01 | Người bất tỉnh hoặc không đáp ứng | Có một phần · 10–13 | Có hướng dẫn · 19–22 | Người lớn và trẻ em | 1 |
| FA02 | Ngừng tim và CPR/AED | Có hướng dẫn · 42–45 | Có hướng dẫn · 19–26 | Người lớn, Trẻ em | 2 |
| FA03 | Hóc dị vật | Có hướng dẫn · 14–15 | Có hướng dẫn · 59–63 | Người lớn, Trẻ em | 2 |
| FA04 | Đuối nước | Có một phần · 34 | Có hướng dẫn · 103–108 | Người lớn, Trẻ em | 2 |
| FA05 | Chảy máu ngoài | Có hướng dẫn · 16–17 | Có hướng dẫn · 39–48 | Người lớn và trẻ em | 1 |
| FA06 | Vết thương nhỏ và trầy xước | Có một phần · 16 | Có hướng dẫn · 50–51 | Người lớn và trẻ em | 1 |
| FA07 | Chảy máu cam | Có hướng dẫn · 16 | Có hướng dẫn cần hiệu chỉnh · 52–53 | Người lớn và trẻ em | 1 |
| FA08 | Nghi gãy xương | Có hướng dẫn · 18–19 | Có hướng dẫn · 30–35 | Người lớn và trẻ em | 1 |
| FA09 | Bong gân và trật khớp | Có hướng dẫn · 20–23 | Có một phần · 69–70 | Người lớn và trẻ em | 2 |
| FA10 | Chấn thương đầu, cổ hoặc cột sống | Có một phần · 10–12 | Có một phần · 13–14; 68–70 | Người lớn và trẻ em | 1 |
| FA11 | Bỏng | Có hướng dẫn · 35–37 | Có hướng dẫn · 86–88 | Người lớn và trẻ em | 1 |
| FA12 | Điện giật | Có hướng dẫn · 38–41 | Có hướng dẫn · 85–86 | Người lớn và trẻ em | 1 |
| FA13 | Say nóng và sốc nhiệt | Không tìm thấy hướng dẫn | Không tìm thấy hướng dẫn | Người lớn và trẻ em | 1 |
| FA14 | Dấu hiệu nghi đột quỵ | Có hướng dẫn · 31–33 | Không tìm thấy hướng dẫn | Người lớn và trẻ em | 1 |
| FA15 | Co giật | Chỉ nhắc đến · 10 | Chỉ nhắc đến · 76; 79–81 | Người lớn và trẻ em | 1 |
| FA16 | Dị ứng nặng và phản vệ | Có hướng dẫn · 24 | Có một phần · 93–94 | Người lớn và trẻ em | 1 |
| FA17 | Nghi ngộ độc | Không tìm thấy hướng dẫn | Có hướng dẫn · 75–81 | Người lớn và trẻ em | 1 |
| FA18 | Động vật cắn và côn trùng đốt | Có hướng dẫn · 25–30 | Có hướng dẫn · 92–97 | Người lớn và trẻ em | 3 |

**FA13:** Không tìm thấy mục hướng dẫn say nóng/sốc nhiệt trong hai PDF. Bài dùng NHS_HEAT, nguồn ngoài.
**FA15:** Có nhắc co giật ở PNT2024 trang 10 và NHI2022 trang 76, 79–81, nhưng không có bài sơ cứu cơn độc lập. Bài dùng NHS_SEIZURE.
**FA10:** Có nội dung rải trong nguyên tắc và chấn thương. Không coi đây là một phác đồ nẹp/vận chuyển đầy đủ.
Không tìm thấy có nghĩa chưa xác định được hướng dẫn độc lập sau kiểm mục lục, text và trang liên quan; không đồng nghĩa từ đó tuyệt đối không có trong ảnh.

## 4. Hợp đồng và đối tượng

| Trường | Quy tắc |
| --- | --- |
| schema_version | 2, thư viện editorial_preview local. Không giả làm OfflineSnapshot public đã phát hành. |
| category_code | FA01–FA18, liên kết category_id ổn định. |
| age_group | ADULT, CHILD, ALL. CHILD không bao gồm nhũ nhi. ALL chỉ dùng sau xác nhận dùng chung. |
| applies_to | Giới hạn tuổi, nguyên nhân, độ nặng và ngoại lệ phải đọc trước thao tác. |
| steps | ID duy nhất, position bắt đầu 1 và liên tiếp; có title và instruction. |
| references | Chỉ trỏ nguồn tồn tại. PDF có trang hợp lệ; WEB không được bịa số trang. |
| media_type | PDF hoặc WEB. WEB cần original_url HTTPS, page_count=null và page_start/page_end=null. |
| publication_year | Năm xuất bản đã xác minh hoặc null. Không dùng ngày truy cập thay năm. |
| content_checked | Xác nhận kiểm nội dung riêng; đọc nguồn và chạy test không phải thẩm định chuyên môn. |

Bài CHILD phải giữ giới hạn cụ thể. Ví dụ bài hóc dị vật ở trẻ trên 5 tuổi không được dùng cho toàn bộ trẻ em.
Không có biến thể đúng đối tượng thì báo chưa có bài; không tự mở ADULT hoặc ALL làm fallback.
Nguồn/trang và ghi chú không hiển thị trong hướng dẫn chính. Các điều kiện an toàn vẫn phải xuất hiện trong bài.

Dùng bài chung khi thao tác sơ cứu giống nhau và nguồn hỗ trợ cả hai nhóm tuổi. Lưu ý về giám sát, nguy cơ và thời điểm khám nằm trong cùng bài. Chỉ tách khi kỹ thuật xử trí khác nhau; không suy việc nguồn không nêu tuổi thành bằng chứng áp dụng cho mọi tuổi.

| Nhóm | Quy tắc đối tượng |
| --- | --- |
| FA01 | Dùng chung kiểm tra đáp ứng, gọi hỗ trợ và theo dõi thở; khi cần CPR phải dùng bài đúng độ tuổi. |
| FA02 | Tách người lớn/trẻ em: độ sâu ép, cách đặt tay, thổi ban đầu và tỉ lệ ép/thổi khác nhau. |
| FA03 | Tách người lớn/trẻ em: tư thế và lực thao tác theo kích thước; bài trẻ em giới hạn trên 5 tuổi theo nguồn đã chọn. |
| FA04 | Tách người lớn/trẻ em vì hồi sức sau đuối nước dùng kỹ thuật CPR theo độ tuổi. |
| FA05 | Dùng chung ép trực tiếp và bảo vệ vết thương; giữ lưu ý giám sát và gọi hỗ trợ sớm cho trẻ. |
| FA06 | Dùng chung rửa sạch và che vết nông; trẻ cần người lớn hỗ trợ. |
| FA07 | Dùng chung cúi trước và bóp phần mềm mũi; giữ chỉ định khám riêng cho trẻ dưới 2 tuổi. |
| FA08 | Dùng chung giữ yên, đỡ chi, không nắn và chuyển đánh giá y tế. |
| FA09 | Dùng chung chăm sóc ban đầu theo loại chấn thương; tách bong gân/trật khớp, không tách theo tuổi. |
| FA10 | Dùng chung hạn chế di chuyển và ưu tiên đường thở; không hướng dẫn kỹ thuật nẹp cổ. |
| FA11 | Dùng chung làm mát bỏng nhiệt nhỏ, da chưa tróc; giữ lưu ý đánh giá y tế cho trẻ và tránh hạ thân nhiệt. |
| FA12 | Dùng chung an toàn điện và theo dõi; CPR phải phù hợp độ tuổi. |
| FA13 | NHS mô tả triệu chứng và làm mát chung cho người lớn/trẻ em. |
| FA14 | Dùng chung nhận biết triệu chứng thần kinh đột ngột và gọi cấp cứu; NHS xác nhận có thể xảy ra ở mọi tuổi. |
| FA15 | Dùng chung bảo vệ trong cơn và theo dõi sau cơn; không hướng dẫn thuốc hay điều trị nguyên nhân. |
| FA16 | Dùng chung gọi cấp cứu, tư thế và hỗ trợ bút đã kê; không suy liều theo tuổi. |
| FA17 | Dùng chung ngừng phơi nhiễm và gọi y tế; không tự gây nôn hay dùng thuốc. CPR theo độ tuổi. |
| FA18 | Dùng chung cho hai nhóm tuổi; tách chó cắn/rắn cắn/ong đốt vì cách xử trí khác nhau. |

## 5. Nội dung theo 18 nhóm

### FA01. Người bất tỉnh hoặc không đáp ứng

**Nhận xét nguồn:** Dùng bài tiếp cận, không suy nguyên nhân mất ý thức. Không kích thích đau cho người không chuyên.

#### Không đáp ứng: kiểm tra và gọi trợ giúp

- Mã bài: `358c7197-a3b5-5d61-b225-cc087be9800a`.
- Biến thể: `shared_unresponsive`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em không đáp ứng khi gọi hỏi. Không mặc định họ đang ngủ hoặc đã ổn.
- Tóm tắt: Đảm bảo an toàn và gọi 115 ngay; bật loa ngoài để nhận hướng dẫn.

**Nhận biết**

- Gọi lớn và chạm nhẹ vai nhưng người đó không trả lời hoặc không có phản ứng.

**Cần làm ngay**

- Đảm bảo an toàn và gọi 115 ngay; bật loa ngoài để nhận hướng dẫn.

**Các bước**

1. **Tiếp cận an toàn.** Kiểm tra nguy cơ điện, lửa, giao thông. Gọi hỏi và chạm nhẹ vai; không gây đau để thử phản ứng. Nhờ người gọi 115 ngay khi không đáp ứng; nếu một mình có điện thoại, bật loa ngoài.
2. **Kiểm tra thở.** Mở đường thở, kiểm tra thở không quá 10 giây. Không thở bình thường hoặc thở ngáp: gọi 115, bật loa ngoài và bắt đầu CPR phù hợp người lớn hoặc trẻ em theo hướng dẫn; không chờ tìm mạch.
3. **Nếu vẫn thở bình thường.** Nếu không nghi chấn thương, đặt nằm nghiêng an toàn. Nếu nghi chấn thương đầu/cổ, hạn chế di chuyển và làm theo tổng đài. Liên tục theo dõi thở.

**Điều tránh**

- Không cho ăn, uống hay nhét vật vào miệng.
- Không đặt nằm nghiêng người đang thở ngáp thay cho CPR.

**Khi cần trợ giúp**

- Mọi trường hợp không đáp ứng đều cần gọi 115.

**Nguồn nội bộ**

- PNT2024, trang PDF 10–13. Nguyên tắc an toàn và tiếp cận.
- RCUK_BLS2025, bản WEB, không có trang PDF. Gọi sớm, nhận biết hô hấp bất thường.
- RCUK_FIRSTAID2025, bản WEB, không có trang PDF. Tư thế hồi phục và ngoại lệ chấn thương.
- NHI2022, trang PDF 14–22. Tư thế an toàn và cấp cứu cơ bản.
- RCUK_PLS2025, bản WEB, không có trang PDF. Gọi cấp cứu sớm và không trì hoãn hồi sức.

### FA02. Ngừng tim và CPR/AED

**Nhận xét nguồn:** Loại bắt mạch cho người không chuyên. RCUK 2025 làm nguồn đối chiếu cho vị trí ép, gọi sớm và AED.

#### CPR và AED ở người lớn

- Mã bài: `e414b8de-9284-5c4e-8369-cdab430db812`.
- Biến thể: `adult_cpr`.
- Đối tượng: Người lớn.
- Phạm vi: Người lớn không đáp ứng và không thở bình thường. Đây không phải bài CPR trẻ em.
- Tóm tắt: Gọi 115, bật loa ngoài và bắt đầu ép tim; nhờ người tìm AED.

**Nhận biết**

- Không đáp ứng, không thở hoặc chỉ thở ngáp.

**Cần làm ngay**

- Gọi 115, bật loa ngoài và bắt đầu ép tim; nhờ người tìm AED.

**Các bước**

1. **Chuẩn bị.** Đảm bảo an toàn, gọi trợ giúp. Để người bệnh nằm ngửa; bắt đầu hồi sức ngay theo tổng đài, tránh trì hoãn vì tìm mạch.
2. **Ép tim.** Đặt gót bàn tay ở giữa ngực, trên nửa dưới xương ức; tay kia chồng lên, đan ngón, giữ tay thẳng. Ép 5–6 cm, 100–120 lần/phút; thả ngực nảy lại hoàn toàn.
3. **Hỗ trợ thở.** Nếu đã học và có thể thổi ngạt: 30 lần ép, 2 lần thổi đủ làm ngực nhô. Nếu không thể thổi: ép liên tục và nghe tổng đài.
4. **Dùng AED.** Bật máy khi có, dán điện cực lên ngực trần theo hình trên miếng dán. Không ai chạm người bệnh khi máy phân tích/phóng điện. Tiếp tục ép ngay theo máy.
5. **Tiếp tục.** Tiếp tục tới khi nhân viên y tế tiếp nhận, người bệnh có đáp ứng và thở bình thường, hoặc bạn không thể tiếp tục vì kiệt sức/nguy hiểm.

**Điều tránh**

- Không dừng CPR chỉ vì tiếng thở ngáp.
- Không dùng độ sâu ép người lớn cho trẻ em.

**Khi cần trợ giúp**

- Gọi 115 ngay; không để việc tìm AED làm chậm ép tim.

**Nguồn nội bộ**

- PNT2024, trang PDF 42–45. Thao tác CPR người lớn.
- RCUK_BLS2025, bản WEB, không có trang PDF. Vị trí ép, AED, gọi sớm và CPR chỉ ép khi không thể thổi.

#### CPR trẻ em cho người sơ cứu

- Mã bài: `1ba9dcb0-aba2-5c1d-a28d-859efa70f7c4`.
- Biến thể: `child_cpr`.
- Đối tượng: Trẻ em.
- Phạm vi: Trẻ em không đáp ứng, không thở bình thường; loại trừ nhũ nhi. Ưu tiên hướng dẫn của 115.
- Tóm tắt: Gọi 115 bằng loa ngoài, nhờ người hỗ trợ; bắt đầu hồi sức.

**Nhận biết**

- Trẻ không đáp ứng, không thở bình thường hoặc chỉ ngáp.

**Cần làm ngay**

- Gọi 115 bằng loa ngoài, nhờ người hỗ trợ; bắt đầu hồi sức.

**Các bước**

1. **Mở đường thở.** Đảm bảo an toàn. Đặt nằm ngửa, mở đường thở và kiểm tra thở không quá 10 giây; không mất thời gian tìm mạch.
2. **Thổi ngạt ban đầu.** Thổi 5 nhịp đầu nếu có thể: nâng cằm, ngửa đầu phù hợp, bịt mũi và áp kín miệng trẻ. Mỗi nhịp khoảng 1 giây, vừa đủ thấy ngực nhô.
3. **Ép ngực.** Dùng một hoặc hai bàn tay theo kích thước trẻ ở nửa dưới xương ức. Ép khoảng 1/3 bề dày ngực, 100–120 lần/phút, để ngực nảy lại; không dùng độ sâu người lớn.
4. **Tiếp tục hồi sức.** Người không được đào tạo CPR nhi khoa chuyên biệt dùng 30 ép : 2 thổi; người đã học PBLS dùng 15:2 theo đào tạo. Nếu không thể thổi, vẫn ép tim và nghe 115. Dùng AED theo hướng dẫn thiết bị khi có.

**Điều tránh**

- Không áp dụng kỹ thuật nhũ nhi hoặc độ sâu 5–6 cm mặc định.
- Không trì hoãn ép tim khi không thể thổi ngạt.

**Khi cần trợ giúp**

- Tiếp tục tới khi đội cấp cứu tiếp nhận hoặc trẻ có đáp ứng và thở bình thường.

**Nguồn nội bộ**

- NHI2022, trang PDF 19–26. Hồi sức trẻ em, 5 nhịp đầu và tần số ép.
- RCUK_PLS2025, bản WEB, không có trang PDF. Tỉ lệ theo mức đào tạo; gọi 115 sớm khi có điện thoại.

### FA03. Hóc dị vật

**Nhận xét nguồn:** Đọc hình PDF để tránh đảo thứ tự text. Trẻ chỉ biên soạn biến thể trên 5 tuổi. Không dùng chung thủ thuật trẻ nhỏ.

#### Hóc dị vật ở người lớn còn tỉnh

- Mã bài: `35917c54-3ba6-513f-96ae-3b23190e30cc`.
- Biến thể: `adult_choking`.
- Đối tượng: Người lớn.
- Phạm vi: Người lớn còn tỉnh; không áp dụng ép bụng cho người mang thai hoặc khi không vòng tay được quanh bụng. Xin hướng dẫn 115 cho ngoại lệ.
- Tóm tắt: Ho còn hiệu quả: khuyến khích ho. Ho kém hoặc không thở được: nhờ người gọi 115.

**Nhận biết**

- Đột ngột không nói, ho hiệu quả hoặc thở được khi ăn/ngậm vật.

**Cần làm ngay**

- Ho còn hiệu quả: khuyến khích ho. Ho kém hoặc không thở được: nhờ người gọi 115.

**Các bước**

1. **Khuyến khích ho.** Khi còn ho mạnh và thở được, động viên ho, theo dõi; không làm thủ thuật khi ho còn hiệu quả.
2. **Vỗ lưng.** Ho không hiệu quả: đỡ ngực, cho cúi về trước; dùng gót bàn tay vỗ tối đa 5 lần giữa hai bả vai. Dừng khi dị vật bật ra.
3. **Ép bụng.** Nếu chưa đỡ: đứng sau, nắm tay đặt giữa rốn và mũi xương ức, tay còn lại ôm nắm tay, giật vào trong và lên trên tối đa 5 lần. Tiếp tục xen kẽ 5 vỗ lưng và 5 ép bụng khi còn tỉnh.
4. **Theo dõi.** Bất tỉnh: hạ nằm an toàn, gọi 115 và bắt đầu CPR. Sau ép bụng thành công vẫn cần được khám.

**Điều tránh**

- Không móc mù vào miệng; không cho ăn uống để đẩy dị vật.
- Không tiếp tục vỗ/ép khi đã thở và ho hiệu quả.

**Khi cần trợ giúp**

- Không nói/ho/thở được hoặc bất tỉnh: cần cấp cứu ngay.

**Nguồn nội bộ**

- PNT2024, trang PDF 14–15. Dấu hiệu và ép bụng. Văn bản trích xuất bị đảo thứ tự, đã kiểm hình trang.
- RCUK_FIRSTAID2025, bản WEB, không có trang PDF. Bổ sung quy trình vỗ lưng trước ép bụng cho tắc nặng.

#### Hóc dị vật ở trẻ trên 5 tuổi

- Mã bài: `f96a8b6b-a49a-5216-bbdf-9efd7dc65481`.
- Biến thể: `child_choking`.
- Đối tượng: Trẻ em.
- Phạm vi: Chỉ trẻ trên 5 tuổi, còn tỉnh; không dùng cho nhũ nhi. Không mở rộng các thao tác này cho trẻ nhỏ hơn khi chưa có bài phù hợp.
- Tóm tắt: Nhờ người gọi 115 nếu trẻ không ho/thở hiệu quả; không chờ trẻ tím.

**Nhận biết**

- Đột ngột không ho hiệu quả, không nói/khóc hoặc không thở được.

**Cần làm ngay**

- Nhờ người gọi 115 nếu trẻ không ho/thở hiệu quả; không chờ trẻ tím.

**Các bước**

1. **Khi ho hiệu quả.** Động viên trẻ ho và theo dõi. Không gây nôn, không cho ăn uống.
2. **Ho không hiệu quả.** Đỡ trẻ cúi về trước, vỗ tối đa 5 lần giữa hai bả vai; kiểm tra sau mỗi lần và dừng nếu đã thông.
3. **Nếu vẫn tắc.** Đứng hoặc quỳ phía sau theo chiều cao trẻ. Đặt nắm tay trên rốn, dưới mũi ức; kéo vào trong và lên trên tối đa 5 lần. Xen kẽ vỗ lưng/ép bụng khi còn tỉnh.
4. **Nếu mất ý thức.** Đặt trẻ nằm an toàn, bắt đầu CPR trẻ em với 5 nhịp thổi ban đầu nếu có thể và làm theo 115. Khám y tế sau sự cố dù đã đỡ.

**Điều tránh**

- Không móc miệng khi không thấy rõ dị vật.
- Không dùng bài cho trẻ dưới phạm vi tuổi nêu trên.

**Khi cần trợ giúp**

- Khó thở tăng, không phát âm được hoặc bất tỉnh: cấp cứu ngay.

**Nguồn nội bộ**

- NHI2022, trang PDF 59–63. Giới hạn trên 5 tuổi theo kỹ thuật Heimlich trong tài liệu.
- RCUK_PLS2025, bản WEB, không có trang PDF. Đối chiếu vỗ lưng và ép bụng theo lứa tuổi.

### FA04. Đuối nước

**Nhận xét nguồn:** Phần người lớn trong PNT rất ngắn; chọn bài trẻ em có hướng dẫn đầy đủ hơn. Không tự xuống nước cứu.

#### Đuối nước , người lớn

- Mã bài: `8d98fcdc-56a0-5937-bcf5-5e3f531edbf0`.
- Biến thể: `adult_drowning`.
- Đối tượng: Người lớn.
- Phạm vi: Người lớn sau tai nạn dưới nước; không tự xuống nước nếu chưa có kỹ năng cứu hộ.
- Tóm tắt: Hô gọi cứu hộ và 115; đưa phao/gậy từ vị trí an toàn.

**Nhận biết**

- Trẻ gặp nạn dưới nước, sau đưa lên có thể ho, khó thở hoặc không đáp ứng.

**Cần làm ngay**

- Hô gọi cứu hộ và 115; đưa phao/gậy từ vị trí an toàn.

**Các bước**

1. **Cứu an toàn.** Nhờ cứu hộ. Từ chỗ vững, đưa vật nổi hoặc gậy để hỗ trợ; không mạo hiểm xuống nước hay để người khác xuống cứu.
2. **Sau đưa lên.** Ở nơi an toàn trên cạn, kiểm tra đáp ứng và thở. Không thở bình thường: gọi 115, cho 5 nhịp thổi ban đầu nếu có thể rồi CPR người lớn theo tổng đài. Không trì hoãn hồi sức.
3. **Theo dõi và giữ ấm.** Nếu còn thở, theo dõi liên tục; thay quần áo ướt khi phù hợp và phủ chăn. Nhờ đưa đi đánh giá y tế; không kết luận an toàn chỉ vì người đó tỉnh.

**Điều tránh**

- Không dốc ngược/vác chạy để đổ nước; không làm chậm hồi sức.
- Không dùng nguồn nhiệt nóng trực tiếp lên da.

**Khi cần trợ giúp**

- Gọi 115 nếu giảm ý thức, khó thở, thở bất thường hoặc cần hồi sức.

**Nguồn nội bộ**

- RCUK_FIRSTAID2025, bản WEB, không có trang PDF. Đuối nước: an toàn cứu hộ, 5 nhịp thổi ban đầu rồi CPR, AED và giữ ấm.
- RCUK_BLS2025, bản WEB, không có trang PDF. Kỹ thuật CPR người lớn sau thổi ban đầu trong đuối nước.

#### Đuối nước , trẻ em

- Mã bài: `1d6be1d2-a3a8-50f6-bb6e-90016a3d6d4c`.
- Biến thể: `child_drowning`.
- Đối tượng: Trẻ em.
- Phạm vi: Trẻ em sau tai nạn dưới nước; người trợ giúp không tự xuống nước khi chưa có kỹ năng cứu hộ.
- Tóm tắt: Hô gọi cứu hộ và 115; đưa phao/gậy từ vị trí an toàn.

**Nhận biết**

- Trẻ gặp nạn dưới nước, sau đưa lên có thể ho, khó thở hoặc không đáp ứng.

**Cần làm ngay**

- Hô gọi cứu hộ và 115; đưa phao/gậy từ vị trí an toàn.

**Các bước**

1. **Cứu an toàn.** Nhờ cứu hộ. Từ chỗ vững, đưa vật nổi hoặc gậy để hỗ trợ; không mạo hiểm xuống nước hay để trẻ khác xuống cứu.
2. **Sau đưa lên.** Ở nơi an toàn, kiểm tra đáp ứng và thở tối đa 10 giây. Không thở bình thường: bắt đầu CPR trẻ em, ưu tiên 5 nhịp thổi đầu nếu có thể; nghe 115.
3. **Theo dõi và giữ ấm.** Nếu còn thở, theo dõi liên tục; thay quần áo ướt khi phù hợp và phủ chăn. Nhờ đưa đi đánh giá y tế; không kết luận an toàn chỉ vì trẻ tỉnh.

**Điều tránh**

- Không dốc ngược/vác chạy để đổ nước; không làm chậm hồi sức.
- Không dùng nguồn nhiệt nóng trực tiếp lên da.

**Khi cần trợ giúp**

- Gọi 115 nếu giảm ý thức, khó thở, thở bất thường hoặc cần hồi sức.

**Nguồn nội bộ**

- NHI2022, trang PDF 105–108. Cứu hộ an toàn, hồi sức và giữ ấm; không áp dụng phần nhũ nhi.
- RCUK_PLS2025, bản WEB, không có trang PDF. Sau đuối nước: 5 nhịp thổi đầu và CPR; không trì hoãn gọi khi có điện thoại.

### FA05. Chảy máu ngoài

**Nhận xét nguồn:** Giữ riêng người lớn/trẻ em; không trì hoãn gọi khi chảy máu nặng.

#### Chảy máu ngoài

- Mã bài: `89f60168-45f5-555a-a646-d1a013f5a0d7`.
- Biến thể: `shared_external_bleeding`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em có vết thương ngoài da đang chảy máu. Không áp dụng cho chảy máu nội tạng, mắt, vết thương ngực/bụng hoặc vật đang cắm trong vết thương.
- Tóm tắt: Dùng vật liệu sạch để tạo áp lực trực tiếp và tìm trợ giúp y tế sớm.

**Nhận biết**

- Thấy máu chảy từ vết thương ngoài da.

**Cần làm ngay**

- Chảy máu nhiều hoặc khó cầm: nhờ người gọi 115 ngay, đồng thời tiến hành cầm máu.

**Các bước**

1. **Bảo vệ người trợ giúp.** Đeo găng nếu có; dùng gạc hoặc vải sạch làm lớp ngăn giữa tay và máu.
2. **Ép trực tiếp.** Nếu không có vật cắm trong vết thương, đặt gạc hoặc vải sạch lên chỗ chảy máu và ấn chắc, duy trì áp lực.
3. **Giữ gạc tại chỗ.** Nếu máu thấm qua, thêm lớp gạc hoặc vải sạch lên trên và tiếp tục ép. Khi kiểm soát được máu, cố định gạc; không băng quá chặt.
4. **Liên hệ hỗ trợ.** Gọi 115 khi chảy máu nhiều hoặc chưa cầm được; tiếp tục giữ áp lực trong lúc chờ hướng dẫn và trợ giúp.

**Điều tránh**

- Không tự rút vật đang cắm trong vết thương; không ép trực tiếp lên vật đó. Tìm trợ giúp y tế.
- Không coi việc máu tạm ngừng là đã loại trừ tổn thương sâu.
- Với trẻ em, luôn có người giám sát; không để trẻ ngậm hoặc gỡ gạc nhỏ cho vào miệng.

**Khi cần trợ giúp**

- Chảy máu nhiều, phun thành tia hoặc không kiểm soát được.
- Vết thương sâu/rộng, có vật cắm, mất cảm giác hoặc khó vận động: cần đánh giá y tế khẩn.
- Ở trẻ em, vẫn không cầm sau 5 phút ép trực tiếp cần gọi 115; chảy máu nặng phải gọi ngay, không chờ đủ thời gian.

**Nguồn nội bộ**

- PNT2024, trang PDF 16–16. Trang in 7, phần Trình tự cầm máu. Bổ sung kiểm tra trường hợp vật cắm, máu thấm gạc và dấu hiệu cần cấp cứu: NHS Cuts and grazes, https://www.nhs.uk/conditions/cuts-and-grazes/ (đọc 28/10/2026).
- NHS_CUTS, bản WEB, không có trang PDF. Nguồn bổ sung đối chiếu; không phải trang PDF.
- NHI2022, trang PDF 39–44. Các phần Tổng quan; Sử dụng băng, gạc; Gọi sự giúp đỡ (đặc biệt trang PDF 39–40, 41–42 và 44). Không dùng phần lượng giá. Ngoại lệ vật cắm đối chiếu NHS Cuts and grazes: https://www.nhs.uk/conditions/cuts-and-grazes/ (đọc 28/10/2026).

### FA06. Vết thương nhỏ và trầy xước

**Nhận xét nguồn:** PNT chỉ nói cầm máu, không đủ bài vệ sinh vết trầy. Chọn NHI 50–51; không tự chỉ định kháng sinh.

#### Vết cắt nhỏ và trầy xước

- Mã bài: `8fe4f201-ed15-5b31-9737-16ec691044da`.
- Biến thể: `shared_minor_wound`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em. Vết nông, nhỏ, không có vật cắm sâu và không chảy máu nhiều. Vết cắn, vết sâu hoặc bẩn khó làm sạch cần đánh giá riêng.
- Tóm tắt: Trấn an người bị thương, làm sạch tay và cầm máu bằng gạc sạch nếu cần.

**Nhận biết**

- Trầy lớp da ngoài hoặc vết cắt nhỏ.

**Cần làm ngay**

- Trấn an người bị thương, làm sạch tay và cầm máu bằng gạc sạch nếu cần.

**Các bước**

1. **Chuẩn bị.** Rửa tay và đeo găng nếu có. Cho người bị thương ngồi, trấn an; hỗ trợ trẻ khi làm sạch và thay băng. Nếu còn chảy máu, ép bằng gạc/vải sạch.
2. **Làm sạch.** Khi máu đã kiểm soát, rửa nhẹ bằng nước sạch; làm sạch vùng da quanh vết thương. Bụi bẩn cắm sâu không tự moi lấy.
3. **Che bảo vệ.** Thấm khô bằng gạc sạch rồi che bằng băng phù hợp, giữ sạch và theo dõi. Cần tư vấn y tế khi đỏ/sưng/đau tăng hoặc có mủ.

**Điều tránh**

- Không dùng bông gòn phủ vào vết hở.
- Không tự bôi kháng sinh hoặc chất lạ để thay việc làm sạch.

**Khi cần trợ giúp**

- Đưa đi khám khi sâu/rộng, còn bẩn, có dị vật, chảy máu không cầm hoặc dấu nhiễm trùng.

**Nguồn nội bộ**

- NHI2022, trang PDF 50–51. Mục 5.4; không đưa chỉ định bôi kháng sinh vào bài cộng đồng.
- NHS_CUTS, bản WEB, không có trang PDF. Đối chiếu làm sạch, che phủ và dấu hiệu cần khám.

### FA07. Chảy máu cam

**Nhận xét nguồn:** NHI trang 52 ghi ngửa đầu, khác PNT 16 và NHS. Không đưa tư thế ngửa đầu vào bài; dùng cúi về trước.

#### Chảy máu cam

- Mã bài: `90ed2110-a47d-571f-8fc5-de491f084ce4`.
- Biến thể: `shared_nosebleed`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em còn tỉnh, tự ngồi và thở được, chảy máu từ mũi. Nếu sau chấn thương đầu, khó thở, yếu/chóng mặt hoặc máu chảy nhiều: tìm trợ giúp khẩn ngay.
- Tóm tắt: Cúi đầu về trước và bóp phần mềm của mũi liên tục 10–15 phút.

**Nhận biết**

- Máu chảy ra từ một hoặc hai bên mũi.

**Cần làm ngay**

- Ngồi và cúi nhẹ về trước; thở bằng miệng.

**Các bước**

1. **Ngồi, cúi về trước.** Ngồi thẳng, đầu hơi cúi về trước, mở miệng và thở bằng miệng.
2. **Bóp phần mềm của mũi.** Dùng ngón cái và ngón trỏ bóp phần mềm ngay trên lỗ mũi, giữ liên tục 10–15 phút.
3. **Kiểm tra và tìm trợ giúp.** Sau 10–15 phút, nếu vẫn chảy máu, đến cơ sở y tế. Nếu máu chảy nhiều, khó thở, yếu/chóng mặt hoặc xảy ra sau va đập đầu: gọi 115 hoặc nhờ đưa đi cấp cứu, không chờ hết thời gian.

**Điều tránh**

- Không ngửa đầu ra sau.
- Không tự lái xe đi cấp cứu khi yếu hoặc chóng mặt.
- Trấn an và hỗ trợ trẻ giữ tư thế, không ngoáy hoặc xì mũi ngay sau cầm máu.

**Khi cần trợ giúp**

- Máu không ngừng sau 10–15 phút.
- Chảy máu nhiều, nuốt nhiều máu gây nôn, khó thở, yếu/chóng mặt hoặc chấn thương đầu: cần cấp cứu.
- Đang dùng thuốc chống đông hoặc chảy máu tái diễn: cần được nhân viên y tế đánh giá.
- Trẻ dưới 2 tuổi bị chảy máu cam cần được bác sĩ đánh giá.

**Nguồn nội bộ**

- PNT2024, trang PDF 16–16. Trang in 7, mục Xử lý chảy máu mũi đúng cách. Thời gian bóp liên tục và tiêu chí tìm trợ giúp bổ sung từ NHS Nosebleed: https://www.nhs.uk/conditions/nosebleed/ (đọc 28/10/2026); số gọi được địa phương hóa thành 115.
- NHS_NOSE, bản WEB, không có trang PDF. Nguồn bổ sung đối chiếu; không phải trang PDF.
- NHI2022, trang PDF 52–53. Có mục chảy máu mũi nhưng tư thế ngửa đầu không dùng; giữ phần theo dõi/chăm sóc.
- PNT2024, trang PDF 16–16. Tư thế cúi về trước.
- NHS_NOSE, bản WEB, không có trang PDF. Nguồn quyết định tư thế cúi, giữ 10–15 phút và tiêu chí đi khám.

### FA08. Nghi gãy xương

**Nhận xét nguồn:** Không biến dấu khám lạo xạo/cử động bất thường thành hành động kiểm tra của người dùng.

#### Nghi gãy xương

- Mã bài: `5a10b0f1-6fd8-500f-b2f7-ec13ea80dbe2`.
- Biến thể: `shared_suspected_fracture`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em. Chấn thương chi nghi gãy; không cố tự chẩn đoán hoặc nắn xương.
- Tóm tắt: Nhờ trợ giúp y tế, giữ vùng bị thương ở tư thế ít đau.

**Nhận biết**

- Đau, sưng/bầm, biến dạng hoặc không cử động được sau chấn thương.

**Cần làm ngay**

- Nhờ trợ giúp y tế, giữ vùng bị thương ở tư thế ít đau.

**Các bước**

1. **Giữ yên.** Dừng vận động; trấn an người bệnh. Không thử bẻ/nắn để tìm tiếng lạo xạo.
2. **Đỡ vùng bị thương.** Dùng quần áo/đệm đỡ và hạn chế cử động ở tư thế hiện có. Không cố kéo thẳng chi hoặc nhét xương lộ trở lại.
3. **Chờ trợ giúp.** Nếu có chảy máu, dùng vật sạch bảo vệ/cầm máu, tránh ép lên xương lộ. Giữ bất động và làm theo nhân viên y tế.

**Điều tránh**

- Không tự di chuyển người nghi tổn thương cột sống/chậu.
- Không kéo chi cho thẳng hoặc tự nắn xương.

**Khi cần trợ giúp**

- Gãy hở, đau dữ dội, biến dạng, chảy máu nhiều hoặc chi lạnh/tê cần cấp cứu.

**Nguồn nội bộ**

- PNT2024, trang PDF 18–19. Dấu hiệu nghi gãy và hỗ trợ bất động.
- NHI2022, trang PDF 30–35. Hướng dẫn sơ cứu chung cho người lớn và trẻ em; không suy liều thuốc từ bài.

### FA09. Bong gân và trật khớp

**Nhận xét nguồn:** Tách bong gân và trật khớp. NHI chỉ nhắc trong phần ngã, không đủ thay cho hai bài riêng.

#### Nghi bong gân

- Mã bài: `a4784455-390d-524b-a8fd-7a75b4ccbf1a`.
- Biến thể: `shared_sprain`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em. Đau/sưng quanh khớp sau vặn xoắn; chưa loại trừ gãy xương. Khớp biến dạng cần xem bài trật khớp/đánh giá y tế.
- Tóm tắt: Dừng hoạt động và giảm cử động vùng đau.

**Nhận biết**

- Đau quanh khớp, sưng, hạn chế vận động sau chấn thương.

**Cần làm ngay**

- Dừng hoạt động và giảm cử động vùng đau.

**Các bước**

1. **Nghỉ.** Đỡ chi ở tư thế thoải mái, không cố chịu lực để thử khớp.
2. **Chườm lạnh.** Bọc túi lạnh bằng vải, chườm 5–10 phút theo nguồn; không áp đá trực tiếp vào da.
3. **Giảm sưng.** Có thể kê cao chi và băng đỡ nhẹ nếu biết cách. Đau tăng, tê hoặc chi lạnh khi băng: nới ngay và đi khám.

**Điều tránh**

- Không chườm đá trực tiếp hoặc băng quá chặt.
- Không coi sưng/đau là chắc chắn chỉ bong gân.

**Khi cần trợ giúp**

- Đi khám nếu đau nhiều, không chịu lực, biến dạng hoặc chưa rõ tổn thương.

**Nguồn nội bộ**

- PNT2024, trang PDF 20–21. RICE; giữ đúng thời gian chườm của nguồn, không tự mở rộng.
- NHI2022, trang PDF 69–70. Bối cảnh chấn thương ở trẻ và chuyển đánh giá y tế; thao tác tại chỗ dùng PNT2024, không tự nắn.

#### Nghi trật khớp

- Mã bài: `96b84301-e630-5fed-acc2-f78909831cd0`.
- Biến thể: `shared_dislocation`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em. Khớp đau/biến dạng sau va chạm hoặc ngã; không tự chỉnh khớp.
- Tóm tắt: Giữ yên khớp, gọi trợ giúp y tế.

**Nhận biết**

- Khớp biến dạng, đau và khó vận động sau chấn thương.

**Cần làm ngay**

- Giữ yên khớp, gọi trợ giúp y tế.

**Các bước**

1. **Trấn an.** Dừng vận động và đỡ vùng bị thương ở tư thế ít đau.
2. **Bất động.** Đệm, đỡ khớp trong tư thế hiện tại. Không thử dấu lò xo hay kéo nắn để kiểm tra.
3. **Liên hệ y tế.** Gọi 115 hoặc nhờ trợ giúp đưa đi đánh giá; giữ khớp bất động trong lúc chờ.

**Điều tránh**

- Không tự nắn, kéo hoặc bẻ khớp.
- Không tiếp tục vận động vì nghĩ khớp sẽ tự vào lại.

**Khi cần trợ giúp**

- Cần đánh giá y tế sớm; tê, lạnh chi hoặc đau dữ dội cần cấp cứu.

**Nguồn nội bộ**

- PNT2024, trang PDF 22–23. Nhận biết và xử trí trật khớp, loại thao tác thử dấu khám chuyên môn.
- NHI2022, trang PDF 69–70. Bối cảnh chấn thương ở trẻ và chuyển đánh giá y tế; thao tác tại chỗ dùng PNT2024, không tự nắn.

### FA10. Chấn thương đầu, cổ hoặc cột sống

**Nhận xét nguồn:** Nội dung rải trong nguyên tắc/tai nạn; chọn hạn chế di chuyển, ưu tiên đường thở. Không chỉ dẫn tự buộc/nẹp cổ.

#### Nghi chấn thương đầu, cổ hoặc cột sống

- Mã bài: `80f87c2e-d9a9-5608-a792-756d8e0c281f`.
- Biến thể: `shared_head_spine`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em. Sau ngã cao/tai nạn; ưu tiên gọi y tế và hạn chế di chuyển. Không hướng dẫn tự nẹp cổ chuyên dụng.
- Tóm tắt: Gọi 115; giữ người bị thương yên và quan sát thở.

**Nhận biết**

- Đau đầu/cổ/lưng, thay đổi ý thức hoặc yếu/tê sau tai nạn.

**Cần làm ngay**

- Gọi 115; giữ người bị thương yên và quan sát thở.

**Các bước**

1. **An toàn và gọi.** Loại nguy cơ hiện trường nếu có thể, nhờ gọi 115. Không vội bế, kéo hoặc đưa người bị thương đi khi không có nguy hiểm trực tiếp.
2. **Hạn chế di chuyển.** Khuyến khích nằm yên; không vặn cổ/lưng hoặc kéo ngồi dậy. Không rút dị vật hay ấn vào vùng sọ bị hở.
3. **Theo dõi.** Quan sát ý thức và thở. Nếu đường thở bị đe dọa hoặc không thở bình thường, báo tổng đài và làm theo hướng dẫn; đường thở luôn được ưu tiên.

**Điều tránh**

- Không tự buộc dây quanh cổ hoặc làm thủ thuật nẹp chưa được đào tạo.
- Không cho ăn uống khi nghi chấn thương nặng.

**Khi cần trợ giúp**

- Giảm ý thức, nôn, co giật, yếu/tê hoặc thở bất thường: cấp cứu ngay.

**Nguồn nội bộ**

- NHI2022, trang PDF 13–14. Cột sống, tư thế và ngoại lệ chấn thương.
- NHI2022, trang PDF 68–70. Tai nạn/ngã: tránh di động trẻ.
- RCUK_FIRSTAID2025, bản WEB, không có trang PDF. Ưu tiên đường thở, hạn chế vận động cổ.

### FA11. Bỏng

**Nhận xét nguồn:** Giới hạn theo tác nhân. Loại uống bù dịch và băng phức tạp; không dùng bài nhiệt thay cho hóa chất/điện.

#### Bỏng nhiệt nhẹ

- Mã bài: `ee664152-773b-59c8-bc4c-20500943f447`.
- Biến thể: `shared_minor_thermal_burn`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em bị bỏng nhiệt nhỏ do nước/vật nóng, da chưa tróc. Không áp dụng cho nhũ nhi, bỏng điện/hóa chất, bỏng rộng/sâu, ở mặt hoặc vùng sinh dục; cần trợ giúp y tế cho các trường hợp đó.
- Tóm tắt: Ngừng tiếp xúc với nguồn nhiệt, làm mát 20 phút, che bảo vệ và tìm tư vấn y tế.

**Nhận biết**

- Vùng da sau tiếp xúc nguồn nóng bị đỏ, đau rát; bài này chỉ dành cho diện tích nhỏ, chưa tróc da.

**Cần làm ngay**

- Đưa người bị bỏng khỏi tác nhân nóng nếu an toàn; bắt đầu làm mát ngay.

**Các bước**

1. **Ngừng tác nhân nóng.** Đảm bảo an toàn rồi đưa người bị bỏng khỏi vật/nước nóng. Tháo trang sức và quần áo gần vùng bỏng nếu không dính; không bóc vật dính trên da.
2. **Làm mát 20 phút.** Làm mát vùng bỏng nhỏ bằng nước sạch mát trong 20 phút. Giữ ấm những phần cơ thể không bị bỏng.
3. **Che bảo vệ.** Sau làm mát, phủ nhẹ bằng gạc vô khuẩn hoặc vải sạch; không dán băng dính trực tiếp vào vùng bỏng.
4. **Nhờ nhân viên y tế.** Tìm tư vấn y tế, đặc biệt khi người bị bỏng là trẻ em. Gọi 115 hoặc nhờ đưa đi cấp cứu khi bỏng rộng/sâu, bỏng ở mặt/vùng sinh dục, do điện/hóa chất hoặc có dấu hiệu nặng.

**Điều tránh**

- Không bôi dầu mỡ, cồn hoặc kem kháng sinh lên vết bỏng.
- Không chọc vỡ bóng nước, bóc da hoặc quần áo dính.
- Không lấy quy trình này thay cho xử trí bỏng điện/hóa chất; không tự dùng thuốc hoặc dung dịch bù dịch.

**Khi cần trợ giúp**

- Bỏng ở trẻ em cần tư vấn y tế; không dựa vào giảm đau để kết luận đã an toàn.
- Bỏng nặng, rộng/sâu, mặt/vùng sinh dục hoặc điện/hóa chất: cần cấp cứu.

**Nguồn nội bộ**

- NHI2022, trang PDF 86–88. Phần II Bỏng; hướng dẫn và lưu ý ở trang PDF 87. Giới hạn làm mát theo nguồn: bỏng nhẹ, chưa tróc da. Bổ sung: NHS Burns and scalds https://www.nhs.uk/conditions/burns-and-scalds/; British Red Cross Burns in babies and children https://www.redcross.org.uk/first-aid/learn-first-aid-for-babies-and-children/burns (đối chiếu 28/10/2026).
- NHS_BURNS, bản WEB, không có trang PDF. Nguồn bổ sung đối chiếu; không phải trang PDF.
- PNT2024, trang PDF 35–37. Loại phần tự bù dịch; không áp dụng quy trình chung cho mọi tác nhân.
- NHS_BURNS, bản WEB, không có trang PDF. Đối chiếu quần áo dính, che phủ và dấu hiệu cần cấp cứu.

### FA12. Điện giật

**Nhận xét nguồn:** Nguồn điện lớn cần điện lực. Không chuyển câu lượng giá NHI 89 thành chỉ dẫn kéo dây bằng tay.

#### Điện giật: an toàn trước khi tiếp cận

- Mã bài: `0c04a405-4ffb-5f7c-b2b2-439495df58da`.
- Biến thể: `shared_electrical_injury`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em gặp điện giật. Đường điện cao thế/dây rơi cần đơn vị điện lực xử lý.
- Tóm tắt: Không chạm nạn nhân khi chưa ngắt điện; gọi 115 và điện lực khi cần.

**Nhận biết**

- Tiếp xúc điện, có thể bỏng, ngã, mất ý thức hoặc thở bất thường.

**Cần làm ngay**

- Không chạm nạn nhân khi chưa ngắt điện; gọi 115 và điện lực khi cần.

**Các bước**

1. **Cắt điện an toàn.** Ngắt nguồn bằng cầu dao/thiết bị an toàn nếu tiếp cận được. Với điện cao thế/dây rơi, giữ xa và chờ điện lực; không dùng gậy để tự xử lý.
2. **Chỉ tiếp cận khi an toàn.** Kiểm tra đáp ứng và thở. Không thở bình thường: CPR theo hướng dẫn 115; chú ý khả năng chấn thương do ngã.
3. **Theo dõi và chuyển viện.** Che vùng bỏng bằng vật sạch; không bóc quần áo dính. Đề nghị đánh giá y tế sau điện giật, theo dõi thở trong lúc chờ.

**Điều tránh**

- Không túm kéo người còn tiếp xúc điện.
- Không cho ăn uống trước đánh giá y tế.

**Khi cần trợ giúp**

- Gọi 115 khi mất ý thức, khó thở, bỏng hoặc chấn thương; không coi tỉnh lại là hết nguy cơ.

**Nguồn nội bộ**

- PNT2024, trang PDF 38–41. An toàn nguồn điện, ABC và theo dõi.
- NHI2022, trang PDF 85–86. Không tiếp xúc trực tiếp, đường điện lớn phải nhờ điện lực.

### FA13. Say nóng và sốc nhiệt

**Nhận xét nguồn:** Không tìm thấy hướng dẫn hoặc mục chủ đề trong hai PDF đã đọc. Nguồn chính cho bài là NHS.

#### Say nóng và nghi sốc nhiệt

- Mã bài: `c36bb404-ecec-5a1f-9179-e8b2bdbf945e`.
- Biến thể: `shared_heat_illness`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em sau tiếp xúc nóng.
- Tóm tắt: Ưu tiên làm mát.

**Nhận biết**

- Mệt/chóng mặt; lú lẫn hoặc co giật là dấu nặng.

**Cần làm ngay**

- Đưa tới chỗ mát và làm mát ngay.

**Các bước**

1. **Nghỉ mát.** Nới quần áo, nghỉ nơi thoáng.
2. **Làm mát.** Lau/phun nước mát và quạt. Túi lạnh phải bọc vải.
3. **Gọi trợ giúp.** Lú lẫn, co giật, bất tỉnh: gọi 115 ngay.

**Điều tránh**

- Chỉ cho uống nước khi tỉnh và nuốt được.

**Khi cần trợ giúp**

- Gọi 115 nếu chưa đỡ sau 30 phút; không chờ khi có dấu nặng.

**Nguồn nội bộ**

- NHS_HEAT, bản WEB, không có trang PDF. Nguồn ngoài hai PDF; bản web không có số trang.

### FA14. Dấu hiệu nghi đột quỵ

**Nhận xét nguồn:** PNT có BE FAST dạng ảnh. Không tìm thấy mục đột quỵ trong NHI. Chỉ biên soạn bài người lớn.

#### Dấu hiệu nghi đột quỵ

- Mã bài: `f4aaec4e-0339-5d35-82e3-b3e025a0411d`.
- Biến thể: `shared_stroke`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em. Triệu chứng thần kinh xuất hiện đột ngột; bài nhận biết và gọi cấp cứu, không phân loại đột quỵ.
- Tóm tắt: Gọi 115 ngay, ghi thời điểm bắt đầu hoặc lần cuối còn bình thường.

**Nhận biết**

- Đột ngột méo mặt, yếu tay/chân, nói khó; có thể mất thăng bằng hoặc thay đổi thị lực.

**Cần làm ngay**

- Gọi 115 ngay, ghi thời điểm bắt đầu hoặc lần cuối còn bình thường.

**Các bước**

1. **Nhận biết.** Yêu cầu cười, nâng hai tay và nói một câu đơn giản nếu làm được; bất thường đột ngột cần gọi 115 ngay.
2. **Chờ hỗ trợ.** Trấn an, để ở vị trí an toàn, thoải mái; không để tự lái xe hoặc đi lại.
3. **Theo dõi thở.** Giảm ý thức, nôn hoặc thở bất thường: báo tổng đài và làm theo hướng dẫn. Không thở bình thường: CPR.

**Điều tránh**

- Không chờ triệu chứng tự hết hoặc chờ đủ giờ vàng.
- Không tự cho aspirin, thuốc hạ áp, ăn hoặc uống.
- FAST không bao quát mọi dấu hiệu. Đột ngột giảm ý thức, yếu liệt, rối loạn thị lực hoặc đau đầu dữ dội cũng cần cấp cứu, kể cả ở trẻ em.

**Khi cần trợ giúp**

- Dấu hiệu nghi đột quỵ dù thoáng qua cũng cần trợ giúp khẩn.

**Nguồn nội bộ**

- PNT2024, trang PDF 31–33. Đã đọc hình BE FAST, không chỉ dựa vào text extraction.
- RCUK_FIRSTAID2025, bản WEB, không có trang PDF. FAST và gọi cấp cứu; không tự dùng thuốc.
- NHS_STROKE, bản WEB, không có trang PDF. Đột quỵ có thể xảy ra ở mọi tuổi; dấu hiệu đột ngột cần cấp cứu, không chỉ dựa vào FAST để loại trừ.

### FA15. Co giật

**Nhận xét nguồn:** Có từ co giật trong nguyên tắc/ngộ độc và lượng giá; không có bài sơ cứu cơn độc lập. Dùng NHS.

#### Co giật

- Mã bài: `0a36c34e-7c2a-5e7c-abff-81018ad31a12`.
- Biến thể: `shared_seizure`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em đang co giật; không tự chẩn đoán nguyên nhân hoặc hướng dẫn thuốc/liều. Không bao gồm nhũ nhi.
- Tóm tắt: Bảo vệ và theo dõi.

**Nhận biết**

- Co cứng/giật người, giảm ý thức.

**Cần làm ngay**

- Dọn nguy hiểm, ghi giờ bắt đầu.

**Các bước**

1. **Bảo vệ.** Đệm mềm dưới đầu.
2. **Giữ an toàn.** Chỉ di chuyển khỏi nguy hiểm; không nhét vật vào miệng.
3. **Sau cơn.** Hết giật, kiểm tra thở; còn thở đặt nằm nghiêng. Không thở bình thường: gọi 115, CPR.

**Điều tránh**

- Không ăn uống khi chưa tỉnh hoàn toàn.

**Khi cần trợ giúp**

- Gọi 115 khi lần đầu, quá 5 phút, lặp cơn không tỉnh, chấn thương nặng hoặc khó thở.

**Nguồn nội bộ**

- NHS_SEIZURE, bản WEB, không có trang PDF. Hai PDF chỉ nhắc co giật trong bối cảnh khác, không có bài sơ cứu độc lập.

### FA16. Dị ứng nặng và phản vệ

**Nhận xét nguồn:** NHI nhắc phản vệ trong côn trùng đốt. Chọn bài người lớn PNT và đối chiếu NHS, không kê liều.

#### Nghi phản vệ

- Mã bài: `8e0fe544-f4b8-5d8c-838c-d4b98260b568`.
- Biến thể: `shared_anaphylaxis`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em. Phản ứng nhanh sau thức ăn, thuốc hoặc côn trùng; cần xử trí y tế khẩn.
- Tóm tắt: Gọi 115 ngay, nói nghi phản vệ.

**Nhận biết**

- Khó thở/khàn tiếng, phù môi/lưỡi, choáng/ngất; có thể kèm mề đay hoặc đau bụng.

**Cần làm ngay**

- Gọi 115 ngay, nói nghi phản vệ.

**Các bước**

1. **Ngừng tiếp xúc.** Ngừng tác nhân nghi gây dị ứng nếu làm được an toàn, không làm chậm gọi cấp cứu.
2. **Tư thế và thuốc đã được kê.** Cho nằm; khó thở có thể nâng vai hoặc ngồi từ từ, duỗi chân. Nếu có bút adrenaline đã được kê, hỗ trợ dùng theo chỉ dẫn thiết bị/đào tạo và 115; không tự pha tiêm.
3. **Theo dõi.** Không cho đứng/đi lại dù đỡ. Theo dõi ý thức và thở; không thở bình thường thì CPR. Cần đánh giá tại bệnh viện ngay.

**Điều tránh**

- Không dùng thuốc kháng histamin để thay cấp cứu phản vệ.
- Không tự thử lại thức ăn/thuốc nghi gây dị ứng.

**Khi cần trợ giúp**

- Khó thở, phù họng/lưỡi, ngất hoặc giảm ý thức: gọi cấp cứu ngay.

**Nguồn nội bộ**

- PNT2024, trang PDF 24–24. Dấu hiệu và ngừng dị nguyên, gọi 115.
- NHS_ANAPHYLAXIS, bản WEB, không có trang PDF. Tư thế và hỗ trợ dùng bút đã kê; không tư vấn liều.

### FA17. Nghi ngộ độc

**Nhận xét nguồn:** Loại gây nôn, than hoạt, thuốc/liều ở NHI 77,79,80. Dùng NHS cho điều tránh an toàn.

#### Nghi ngộ độc

- Mã bài: `297764ce-ff2c-5e1e-9121-e431ff94d63b`.
- Biến thể: `shared_suspected_poisoning`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em. Nghi nuốt/uống thuốc, hóa chất, nấm hoặc chất độc; không gồm xử trí thuốc đặc hiệu hay kê liều.
- Tóm tắt: Gọi 115/nhân viên y tế ngay; không chờ có triệu chứng.

**Nhận biết**

- Có phơi nhiễm nghi ngờ; có thể đau bụng/nôn, buồn ngủ, khó thở hoặc co giật.

**Cần làm ngay**

- Gọi 115/nhân viên y tế ngay; không chờ có triệu chứng.

**Các bước**

1. **Ngừng phơi nhiễm.** Đưa khỏi nguy cơ nếu an toàn; không tự vào khu vực khí độc. Không cho ăn uống hoặc tự gây nôn.
2. **Chuẩn bị thông tin.** Giữ bao bì/tên chất, thời điểm và lượng nghi tiếp xúc nếu biết, không trì hoãn cấp cứu để tìm đủ thông tin.
3. **Theo dõi.** Theo dõi thở và ý thức. Giảm ý thức còn thở: tư thế an toàn nếu không chấn thương. Không thở bình thường: CPR phù hợp người lớn hoặc trẻ em và nghe 115.

**Điều tránh**

- Không móc họng/gây nôn; không tự dùng than hoạt, thuốc hoặc dung dịch trung hòa.
- Không tin đã hết độc chỉ vì nôn/đau bụng tạm giảm.

**Khi cần trợ giúp**

- Nghi nuốt/uống thuốc, hóa chất hoặc chất độc: gọi 115 hoặc đến cấp cứu ngay; không chờ triệu chứng xuất hiện.

**Nguồn nội bộ**

- NHI2022, trang PDF 75–81. Chọn nhận biết và chuyển viện; không dùng các đoạn gây nôn/than hoạt/thuốc liều.
- NHS_POISON, bản WEB, không có trang PDF. Nguồn quyết định không gây nôn, không cho ăn uống và giữ bao bì.

### FA18. Động vật cắn và côn trùng đốt

**Nhận xét nguồn:** Tách chó cắn, rắn cắn, ong đốt. Không bắt người dùng định loài rắn để tự chọn băng ép. Không suy thủ thuật kiến ba khoang thành bài ong.

#### Chó cắn

- Mã bài: `1225b40a-08f4-5973-a746-8cc98f48a39b`.
- Biến thể: `shared_dog_bite`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em. Vết cắn gây rách da; cần đánh giá dự phòng dại và uốn ván, không chờ theo dõi con vật mới đi khám.
- Tóm tắt: Ra khỏi vùng nguy hiểm; rửa sớm và đến cơ sở y tế.

**Nhận biết**

- Vết cắn/xước do chó, có thể chảy máu.

**Cần làm ngay**

- Ra khỏi vùng nguy hiểm; rửa sớm và đến cơ sở y tế.

**Các bước**

1. **An toàn.** Tránh bị cắn tiếp; không tự bắt con vật. Nếu máu chảy nhiều, dùng vật sạch cầm máu và gọi trợ giúp.
2. **Rửa vết thương.** Rửa với xà phòng và nước chảy liên tục 15 phút khi tình trạng cho phép.
3. **Đi khám ngay.** Đến cơ sở y tế để đánh giá tiêm phòng dại/uốn ván và xử trí vết thương. Không chờ xuất hiện triệu chứng.

**Điều tránh**

- Không nặn vết thương, đắp lá/chất lạ hoặc băng kín.
- Không tự quyết định bỏ tiêm dự phòng vì chó nhà.

**Khi cần trợ giúp**

- Vết sâu, vùng mặt/cổ hoặc chảy máu nặng: trợ giúp khẩn; mọi vết cắn rách da cần đánh giá y tế.

**Nguồn nội bộ**

- PNT2024, trang PDF 25–26. Rửa 15 phút và đánh giá dự phòng; bỏ đoạn số liệu không cần cho thao tác.
- NHI2022, trang PDF 92–93. Chăm sóc vết cắn ở trẻ; dự phòng dại đối chiếu WHO, không đồng nhất huyết thanh kháng dại với uốn ván.
- WHO_RABIES, bản WEB, không có trang PDF. Dự phòng sau phơi nhiễm cho mọi lứa tuổi; rửa xà phòng/nước ít nhất 15 phút và đi khám ngay.

#### Nghi rắn cắn

- Mã bài: `c6a48804-f4ab-5349-918b-d89dd420a1dd`.
- Biến thể: `shared_snake_bite`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em. Mọi nghi ngờ rắn cắn cần đánh giá khẩn; không yêu cầu người dùng xác định họ rắn.
- Tóm tắt: Ra xa rắn, gọi 115 và hạn chế vận động.

**Nhận biết**

- Bị rắn cắn, có thể đau/sưng hoặc chưa có dấu hiệu rõ.

**Cần làm ngay**

- Ra xa rắn, gọi 115 và hạn chế vận động.

**Các bước**

1. **Giữ yên.** Trấn an; giữ chi bị cắn yên, tháo trang sức/quần áo chật trước khi sưng.
2. **Không làm thủ thuật.** Không rạch, hút nọc, garô, nặn hoặc bôi thuốc. Không tự băng ép theo họ rắn khi chưa nhận diện và chưa được đào tạo.
3. **Chuyển viện.** Nhờ trợ giúp vận chuyển, hạn chế tự đi bộ. Không bắt rắn hoặc trì hoãn để chụp/nhận dạng.

**Điều tránh**

- Không kết luận rắn lành chỉ dựa vào vết răng hoặc chưa sưng.
- Không làm theo mẹo hút nọc/đắp thuốc.

**Khi cần trợ giúp**

- Tất cả trường hợp nghi rắn cắn cần đến cơ sở y tế sớm; khó thở, yếu hoặc chảy máu bất thường cần 115.

**Nguồn nội bộ**

- PNT2024, trang PDF 27–28. Giới hạn biện pháp theo họ rắn; không tự lựa chọn băng ép.
- NHI2022, trang PDF 94–95. Theo dõi mọi vết cắn; không garô, rạch, hút.

#### Ong đốt

- Mã bài: `a52772d7-0b94-54ca-9795-8e0142138e0d`.
- Biến thể: `shared_bee_sting`.
- Đối tượng: Người lớn và trẻ em.
- Phạm vi: Người lớn và trẻ em bị ong đốt; dấu toàn thân hoặc phù vùng miệng/cổ cần cấp cứu.
- Tóm tắt: Đưa người bị đốt xa khu vực có ong, theo dõi khó thở.

**Nhận biết**

- Đau, ngứa, sưng tại chỗ; dấu nặng gồm khó thở, choáng, nổi mề đay toàn thân.

**Cần làm ngay**

- Đưa người bị đốt xa khu vực có ong, theo dõi khó thở.

**Các bước**

1. **Tránh bị đốt tiếp.** Đưa tới nơi an toàn; không chọc phá tổ hoặc đuổi bắt ong.
2. **Chăm sóc tại chỗ.** Nếu ngòi còn thấy rõ, khều nhẹ để lấy ra, không bóp túi nọc. Rửa bằng nước và xà phòng, chườm lạnh qua vải.
3. **Theo dõi.** Khó thở, mệt/lạnh tay chân, mề đay lan rộng hoặc nhiều vết đốt: tìm trợ giúp ngay. Tiểu ít/đỏ cũng cần khám.

**Điều tránh**

- Không bóp/nặn, gãi hoặc đắp chất lạ.
- Không tự bôi thuốc để trì hoãn đánh giá khi có dấu hiệu nặng.

**Khi cần trợ giúp**

- Khó thở, phù vùng đầu mặt cổ hoặc choáng: gọi 115 ngay.

**Nguồn nội bộ**

- NHI2022, trang PDF 93–94. Côn trùng đốt và dấu hiệu cần trợ giúp.
- PNT2024, trang PDF 29–30. Theo dõi nhiều vết đốt/dấu toàn thân; loại phần tự dùng thuốc.

## 6. Loại trừ và kiểm duyệt

- Không đưa câu hỏi lượng giá hoặc đáp án sai vào corpus/bài. NHI2022 có lượng giá ở nhiều chương, không chỉ trang 89.
- Không dùng ngửa đầu khi chảy máu cam trong NHI2022 trang 52. Bài dùng cúi về trước, có nguồn đối chiếu riêng.
- Không đưa gây nôn, tự uống than hoạt hoặc thuốc/liều ở NHI2022 trang 77, 79, 80 vào hướng dẫn cộng đồng.
- Không yêu cầu bắt mạch, thử tiếng lạo xạo, thử dấu lò xo, tự nắn khớp hoặc tự buộc nẹp cổ.
- Không chọn băng ép rắn cắn bằng suy đoán loài. Không dùng mẹo rạch, hút, garô hoặc đắp thuốc.
- Không công bố bài chỉ vì đủ trường JSON. Nhóm cần rà soát y khoa, đối tượng và khả năng thao tác trước publish.
- Luồng hỏi đáp minh họa không tự trở thành luồng triage y khoa chỉ vì thư viện có bài. Câu hỏi/nhánh cần được kiểm riêng.

### Kiểm tra đồng bộ

Chạy `python tools/generate_data_reference.py --check` để kiểm tra tài liệu khớp bộ dữ liệu.
Khi nội dung thay đổi, sinh lại bằng `python tools/generate_data_reference.py`. Không chỉnh bản sinh độc lập với JSON.
Dấu kiểm dữ liệu SHA-256: `082fd9cdeff61889f406c91aa70f1e2ce65bfbea9a95f742e08d492678ffdb01`.

### Thuật ngữ

- CPR: Hồi sức tim phổi. AED: Máy khử rung tự động ngoài lồng ngực.
- PBLS: Hỗ trợ sự sống cơ bản nhi khoa. Bài phải nêu mức đào tạo của người sơ cứu khi liên quan.
- DRAFT: Nội dung chưa phát hành. MENTION_ONLY: Chỉ nhắc đến, không đủ làm hướng dẫn độc lập.
