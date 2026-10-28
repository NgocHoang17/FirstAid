"""Generate the human-readable data reference from the bundled content catalogue.

Usage: python tools/generate_data_reference.py [--check]
No PDF copies, network calls or third-party packages are required.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'mobile/assets/content/reference_library.json'
OUTPUT = ROOT / 'docs/DATA_REFERENCE.md'
LABELS = {'DIRECT':'Có hướng dẫn','PARTIAL':'Có một phần','CONFLICT':'Có hướng dẫn cần hiệu chỉnh','MENTION_ONLY':'Chỉ nhắc đến','NOT_FOUND':'Không tìm thấy hướng dẫn'}
AGES = {'ADULT':'Người lớn','CHILD':'Trẻ em','ALL':'Người lớn và trẻ em'}

def pages(values):
    return '; '.join(str(a) if a==b else f'{a}–{b}' for a,b in zip(values[::2],values[1::2])) or 'Không có'

def render(data):
    sources={s['id']:s for s in data['sources']}
    articles={a['id']:a for a in data['articles']}
    out=[]
    def line(value=''): out.append(value)
    line('# Dữ liệu chuẩn tham chiếu sơ cứu FirstAid')
    line()
    line('**Mã tài liệu:** DATA-001  ')
    line('**Phiên bản:** 2.0  ')
    line('**Ngày đối chiếu nguồn:** 28/10/2026  ')
    line('**Tính chất:** Bản biên soạn tham khảo, chưa có xác nhận chuyên môn độc lập.  ')
    line('**Phạm vi:** Người lớn và trẻ em. Không bao gồm nhũ nhi.')
    line()
    line('Tài liệu quy định nội dung và nguồn cho đủ 18 nhóm. Đây không phải báo cáo tiến độ hoặc chứng nhận an toàn y khoa.')
    line('Chỉ dùng hướng dẫn trong phạm vi và đối tượng của từng bài. Không suy có từ khóa là đã có phác đồ phù hợp.')
    line()
    line('## Mục lục')
    line()
    for text,anchor in [('1. Quy tắc dữ liệu','1-quy-tắc-dữ-liệu'),('2. Danh sách nguồn','2-danh-sách-nguồn'),('3. Độ phủ hai PDF','3-độ-phủ-hai-pdf'),('4. Hợp đồng và đối tượng','4-hợp-đồng-và-đối-tượng'),('5. Nội dung theo 18 nhóm','5-nội-dung-theo-18-nhóm'),('6. Loại trừ và kiểm duyệt','6-loại-trừ-và-kiểm-duyệt')]:
        line(f'- [{text}](#{anchor})')
    line()
    line('## 1. Quy tắc dữ liệu')
    line()
    line('- Bộ dữ liệu gốc: [reference_library.json](../mobile/assets/content/reference_library.json). Tài liệu này được sinh từ cùng dữ liệu.')
    line('- Giữ mã nhóm FA01–FA18. Mỗi bài có variant_key và age_group riêng, không nhân bản tùy ý sang nhóm tuổi khác.')
    line('- Hướng dẫn được diễn giải lại bằng tiếng Việt, không sao chép PDF hoặc hình gốc vào app.')
    line('- Quick và learn dùng cùng bài, bước và nguồn. Quick đổi cách trình bày, không cắt điều kiện áp dụng.')
    line('- Nội dung là bản thảo DRAFT, content_checked=false. Chỉ xem trong bản phát triển, không tự phát hành trên release.')
    line('- Không gắn nhãn đã được chuyên gia xác nhận khi chưa có người kiểm duyệt chuyên môn.')
    line('- Số liên hệ khẩn được địa phương hóa thành 115 cho Việt Nam. Không đưa số NHS/Anh vào nút gọi của app.')
    line('- Không chờ đủ thời gian theo dõi nếu có dấu hiệu đe dọa tính mạng.')
    line()
    line('## 2. Danh sách nguồn')
    line()
    line('| Mã | Tên tài liệu | Biên soạn / phát hành | Năm xuất bản | Loại |')
    line('| --- | --- | --- | --- | --- |')
    for s in data['sources']:
        title=f"[{s['title']}]({s['original_url']})" if s.get('original_url') else s['title']
        line(f"| {s['code']} | {title} | {s['publisher']} | {s['publication_year'] or 'Không nêu'} | {s['media_type']} |")
    line()
    line('Hai nguồn gốc người dùng cung cấp: PNT2024, 47 trang PDF; NHI2022, 112 trang PDF. NHI là tài liệu tập huấn, có cả bài học và lượng giá.')
    line('Nguồn WEB là nguồn bổ sung chính thức, không phải nội dung trong hai PDF. Ngày truy cập không được thay cho năm xuất bản.')
    line('Năm 2025 của RCUK là năm công bố ghi trên trang. NHS không nêu năm xuất bản nên để trống, dù có ngày rà soát.')
    line('Giao diện người dùng chỉ hiện tên tài liệu, đơn vị biên soạn và năm. Trang trích dẫn và ghi chú đối chiếu chỉ phục vụ dữ liệu nội bộ.')
    line()
    line('## 3. Độ phủ hai PDF')
    line()
    line('Mức độ: có hướng dẫn; có một phần; cần hiệu chỉnh; chỉ nhắc đến; không tìm thấy hướng dẫn.')
    line('Số trang dưới đây là thứ tự trang PDF, không suy từ số in. Khoảng trang được kiểm trong bản người dùng cung cấp.')
    line()
    line('| Mã | Tình huống | PNT2024 | NHI2022 | Đối tượng có bài | Số biến thể |')
    line('| --- | --- | --- | --- | --- | --- |')
    for c in data['categories']:
        ev=c['pdf_evidence'];texts=[]
        for code in ['PNT2024','NHI2022']:
            record=ev[code];texts.append(LABELS[record['status']]+(' · '+pages(record['pages']) if record['pages'] else ''))
        rows=[articles[i] for i in c['article_ids']]
        ages=', '.join(AGES[a] for a in sorted({a['age_group'] for a in rows}))
        line(f"| {c['code']} | {c['name']} | {texts[0]} | {texts[1]} | {ages} | {len(rows)} |")
    line()
    line('**FA13:** Không tìm thấy mục hướng dẫn say nóng/sốc nhiệt trong hai PDF. Bài dùng NHS_HEAT, nguồn ngoài.')
    line('**FA15:** Có nhắc co giật ở PNT2024 trang 10 và NHI2022 trang 76, 79–81, nhưng không có bài sơ cứu cơn độc lập. Bài dùng NHS_SEIZURE.')
    line('**FA10:** Có nội dung rải trong nguyên tắc và chấn thương. Không coi đây là một phác đồ nẹp/vận chuyển đầy đủ.')
    line('Không tìm thấy có nghĩa chưa xác định được hướng dẫn độc lập sau kiểm mục lục, text và trang liên quan; không đồng nghĩa từ đó tuyệt đối không có trong ảnh.')
    line()
    line('## 4. Hợp đồng và đối tượng')
    line()
    line('| Trường | Quy tắc |')
    line('| --- | --- |')
    line('| schema_version | 2, thư viện editorial_preview local. Không giả làm OfflineSnapshot public đã phát hành. |')
    line('| category_code | FA01–FA18, liên kết category_id ổn định. |')
    line('| age_group | ADULT, CHILD, ALL. CHILD không bao gồm nhũ nhi. ALL chỉ dùng sau xác nhận dùng chung. |')
    line('| applies_to | Giới hạn tuổi, nguyên nhân, độ nặng và ngoại lệ phải đọc trước thao tác. |')
    line('| steps | ID duy nhất, position bắt đầu 1 và liên tiếp; có title và instruction. |')
    line('| references | Chỉ trỏ nguồn tồn tại. PDF có trang hợp lệ; WEB không được bịa số trang. |')
    line('| media_type | PDF hoặc WEB. WEB cần original_url HTTPS, page_count=null và page_start/page_end=null. |')
    line('| publication_year | Năm xuất bản đã xác minh hoặc null. Không dùng ngày truy cập thay năm. |')
    line('| content_checked | Xác nhận kiểm nội dung riêng; đọc nguồn và chạy test không phải thẩm định chuyên môn. |')
    line()
    line('Bài CHILD phải giữ giới hạn cụ thể. Ví dụ bài hóc dị vật ở trẻ trên 5 tuổi không được dùng cho toàn bộ trẻ em.')
    line('Không có biến thể đúng đối tượng thì báo chưa có bài; không tự mở ADULT hoặc ALL làm fallback.')
    line('Nguồn/trang và ghi chú không hiển thị trong hướng dẫn chính. Các điều kiện an toàn vẫn phải xuất hiện trong bài.')
    line()
    line('Dùng bài chung khi thao tác sơ cứu giống nhau và nguồn hỗ trợ cả hai nhóm tuổi. Lưu ý về giám sát, nguy cơ và thời điểm khám nằm trong cùng bài. Chỉ tách khi kỹ thuật xử trí khác nhau; không suy việc nguồn không nêu tuổi thành bằng chứng áp dụng cho mọi tuổi.')
    line()
    line('| Nhóm | Quy tắc đối tượng |')
    line('| --- | --- |')
    for c in data['categories']:
        line(f"| {c['code']} | {c['audience_policy']} |")
    line()
    line('## 5. Nội dung theo 18 nhóm')
    line()
    for c in data['categories']:
        line(f"### {c['code']}. {c['name']}");line()
        line(f"**Nhận xét nguồn:** {c['coverage_note']}");line()
        for aid in c['article_ids']:
            a=articles[aid]
            line(f"#### {a['title']}");line()
            line(f"- Mã bài: `{a['id']}`.")
            line(f"- Biến thể: `{a['variant_key']}`.")
            line(f"- Đối tượng: {AGES[a['age_group']]}.")
            line(f"- Phạm vi: {a['applies_to']}")
            line(f"- Tóm tắt: {a['summary']}");line()
            for field,title in [('recognition','Nhận biết'),('quick_actions','Cần làm ngay')]:
                line(f'**{title}**');line()
                for text in a[field]:line('- '+text)
                line()
            line('**Các bước**');line()
            for step in a['steps']:line(f"{step['position']}. **{step['title']}.** {step['instruction']}")
            line()
            for field,title in [('warnings','Điều tránh'),('seek_help','Khi cần trợ giúp')]:
                line(f'**{title}**');line()
                for text in a[field]:line('- '+text)
                line()
            line('**Nguồn nội bộ**');line()
            for r in a['references']:
                source=sources[r['source_id']]
                location=f"trang PDF {r['page_start']}–{r['page_end']}" if source['media_type']=='PDF' else 'bản WEB, không có trang PDF'
                line(f"- {source['code']}, {location}. {r['note']}")
            line()
    line('## 6. Loại trừ và kiểm duyệt');line()
    line('- Không đưa câu hỏi lượng giá hoặc đáp án sai vào corpus/bài. NHI2022 có lượng giá ở nhiều chương, không chỉ trang 89.')
    line('- Không dùng ngửa đầu khi chảy máu cam trong NHI2022 trang 52. Bài dùng cúi về trước, có nguồn đối chiếu riêng.')
    line('- Không đưa gây nôn, tự uống than hoạt hoặc thuốc/liều ở NHI2022 trang 77, 79, 80 vào hướng dẫn cộng đồng.')
    line('- Không yêu cầu bắt mạch, thử tiếng lạo xạo, thử dấu lò xo, tự nắn khớp hoặc tự buộc nẹp cổ.')
    line('- Không chọn băng ép rắn cắn bằng suy đoán loài. Không dùng mẹo rạch, hút, garô hoặc đắp thuốc.')
    line('- Không công bố bài chỉ vì đủ trường JSON. Nhóm cần rà soát y khoa, đối tượng và khả năng thao tác trước publish.')
    line('- Luồng hỏi đáp minh họa không tự trở thành luồng triage y khoa chỉ vì thư viện có bài. Câu hỏi/nhánh cần được kiểm riêng.')
    line()
    line('### Kiểm tra đồng bộ');line()
    line('Chạy `python tools/generate_data_reference.py --check` để kiểm tra tài liệu khớp bộ dữ liệu.')
    line('Khi nội dung thay đổi, sinh lại bằng `python tools/generate_data_reference.py`. Không chỉnh bản sinh độc lập với JSON.')
    line(f"Dấu kiểm dữ liệu SHA-256: `{hashlib.sha256(DATA.read_bytes()).hexdigest()}`.")
    line()
    line('### Thuật ngữ');line()
    line('- CPR: Hồi sức tim phổi. AED: Máy khử rung tự động ngoài lồng ngực.')
    line('- PBLS: Hỗ trợ sự sống cơ bản nhi khoa. Bài phải nêu mức đào tạo của người sơ cứu khi liên quan.')
    line('- DRAFT: Nội dung chưa phát hành. MENTION_ONLY: Chỉ nhắc đến, không đủ làm hướng dẫn độc lập.')
    return '\n'.join(out).replace('—', ',').rstrip()+'\n'

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
    text=render(json.loads(DATA.read_text(encoding='utf-8-sig')))
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding='utf-8')!=text:raise SystemExit('DATA_REFERENCE.md is not synchronized')
        print('DATA_REFERENCE.md matches the content catalogue')
    else:
        OUTPUT.write_text(text,encoding='utf-8');print('Generated',OUTPUT.relative_to(ROOT))
if __name__=='__main__': main()
