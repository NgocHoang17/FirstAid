import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

const situations = [
  'Bất tỉnh / không đáp ứng',
  'Ngừng tim • CPR / AED',
  'Hóc dị vật',
  'Đuối nước',
  'Chảy máu ngoài',
  'Vết thương nhỏ / trầy xước',
  'Chảy máu cam',
  'Nghi gãy xương',
  'Bong gân / trật khớp',
  'Chấn thương đầu, cổ, cột sống',
  'Bỏng',
  'Điện giật',
  'Say nóng / sốc nhiệt',
  'Nghi đột quỵ',
  'Co giật',
  'Dị ứng nặng / phản vệ',
  'Nghi ngộ độc',
  'Động vật cắn / côn trùng đốt',
];

void openPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

class AidCard extends StatelessWidget {
  const AidCard(
    this.title,
    this.subtitle, {
    this.onTap,
    this.color = Colors.white,
    super.key,
  });
  final String title, subtitle;
  final VoidCallback? onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class AidButton extends StatelessWidget {
  const AidButton(
    this.label,
    this.onPressed, {
    this.emergency = false,
    super.key,
  });
  final String label;
  final VoidCallback onPressed;
  final bool emergency;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.all(16),
        backgroundColor: emergency ? AppColors.emergency : AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}

class CallHelp extends StatelessWidget {
  const CallHelp({super.key});
  @override
  Widget build(BuildContext context) => AidButton('Gọi trợ giúp', () async {
    bool opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: '115'));
    } catch (_) {
      /* Show fallback below. */
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SelectableText('Không mở được ứng dụng gọi. Số hỗ trợ: 115'),
        ),
      );
    }
  }, emergency: true);
}

class AidScaffold extends StatelessWidget {
  const AidScaffold({
    required this.title,
    required this.children,
    this.call = false,
    super.key,
  });
  final String title;
  final List<Widget> children;
  final bool call;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (final child in children) ...[child, const SizedBox(height: 16)],
      ],
    ),
    bottomNavigationBar: call
        ? const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CallHelp(),
            ),
          )
        : null,
  );
}

class QuickAidHome extends StatelessWidget {
  const QuickAidHome({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          Text('✚', style: TextStyle(color: AppColors.primary)),
          SizedBox(width: 12),
          Text('FirstAid', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: const Color(0xFFF0FDFA),
        selectedIndex: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          if (index == 0) return;
          const labels = ['Trang chủ', 'Kiến thức', 'Hỏi đáp', 'Cơ sở y tế'];
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('${labels[index]} chưa có trong bản demo này.'),
              ),
            );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Kiến thức',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Hỏi đáp',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            label: 'Cơ sở y tế',
          ),
        ],
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Bình tĩnh.\nTừng bước, đúng cách.',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('Tra cứu kiến thức và hướng dẫn sơ cứu cơ bản.'),
        const SizedBox(height: 16),
        Material(
          color: AppColors.emergency,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openPage(context, const QuickAidList()),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cần sơ cứu ngay?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Mở hướng dẫn nhanh\nCó thể dùng ngoại tuyến',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const CallHelp(),
        const SizedBox(height: 16),
        const AidCard(
          'Bản thiết kế minh họa',
          'Dữ liệu demo có sẵn ngoại tuyến. Chưa phải nội dung hướng dẫn sơ cứu đã kiểm duyệt.',
          color: Color(0xFFF0FDFA),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => openPage(context, const QuickAidList()),
          child: const Text('Tìm tình huống sơ cứu…'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Khám phá theo nhóm',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        for (final group in [
          (0, 4, 'Tuần hoàn & hô hấp'),
          (4, 10, 'Chấn thương'),
          (10, 18, 'Môi trường & tình huống khác'),
        ]) ...[
          AidCard(
            group.$3,
            'FA${(group.$1 + 1).toString().padLeft(2, '0')} – FA${group.$2.toString().padLeft(2, '0')}',
            onTap: () =>
                openPage(context, QuickAidList(start: group.$1, end: group.$2)),
          ),
          const SizedBox(height: 16),
        ],
      ],
    ),
  );
}

String searchKey(String value) {
  const groups = [
    'àáạảãâầấậẩẫăằắặẳẵ',
    'èéẹẻẽêềếệểễ',
    'ìíịỉĩ',
    'òóọỏõôồốộổỗơờớợởỡ',
    'ùúụủũưừứựửữ',
    'ỳýỵỷỹ',
    'đ',
  ];
  var result = value.toLowerCase();
  for (var i = 0; i < groups.length; i++) {
    for (final rune in groups[i].runes) {
      result = result.replaceAll(String.fromCharCode(rune), 'aeiouyd'[i]);
    }
  }
  return result;
}

class QuickAidList extends StatefulWidget {
  const QuickAidList({this.start = 0, this.end = 18, super.key});
  final int start, end;
  @override
  State<QuickAidList> createState() => _QuickAidListState();
}

class _QuickAidListState extends State<QuickAidList> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final matches = [
      for (var i = widget.start; i < widget.end; i++)
        if (searchKey(situations[i]).contains(searchKey(query.trim()))) i,
    ];
    return AidScaffold(
      title: 'Sơ cứu nhanh',
      call: true,
      children: [
        const Text(
          'Bạn đang gặp tình huống nào?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: InputDecoration(
            hintText: 'Tìm tình huống sơ cứu…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        Text('${matches.length} nhóm tình huống'),
        if (matches.isEmpty)
          const AidCard(
            'Không tìm thấy kết quả',
            'Thử từ khóa khác hoặc kiểm tra chính tả.',
            color: Color(0xFFEFF6FF),
          ),
        for (final i in matches)
          AidCard(
            '${(i + 1).toString().padLeft(2, '0')}   ${situations[i]}',
            'Chọn để xem hướng dẫn  ›',
            onTap: () =>
                openPage(context, AudiencePage(category: situations[i])),
          ),
      ],
    );
  }
}

class AudiencePage extends StatelessWidget {
  const AudiencePage({required this.category, super.key});
  final String category;
  @override
  Widget build(BuildContext context) => AidScaffold(
    title: 'Chọn đối tượng',
    call: true,
    children: [
      Text(
        category,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Chọn đúng đối tượng',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Text('Hướng dẫn được hiển thị theo phạm vi áp dụng của bài.'),
      const AidCard(
        'Bản thiết kế minh họa',
        'Chỉ bài Bỏng • Người lớn có mẫu giao diện; không dùng mẫu để sơ cứu.',
        color: Color(0xFFEFF6FF),
      ),
      for (final age in ['Người lớn', 'Trẻ em', 'Trẻ nhũ nhi'])
        AidButton(
          age,
          () => openPage(
            context,
            category == 'Bỏng' && age == 'Người lớn'
                ? const QuickArticlePage()
                : UnsupportedAudience(category: category),
          ),
        ),
      const AidCard(
        'Không chắc độ tuổi?',
        'Xem phạm vi áp dụng trước khi tiếp tục.',
        color: Color(0xFFEFF6FF),
      ),
    ],
  );
}

class UnsupportedAudience extends StatelessWidget {
  const UnsupportedAudience({required this.category, super.key});
  final String category;
  @override
  Widget build(BuildContext context) => AidScaffold(
    title: 'Chưa có hướng dẫn phù hợp',
    call: true,
    children: [
      Text(
        category,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const AidCard(
        'Không tự thay bằng hướng dẫn người lớn',
        'Chọn lại đối tượng hoặc tìm tình huống liên quan.',
        color: Color(0xFFEFF6FF),
      ),
      AidButton('Chọn lại đối tượng', () => Navigator.pop(context)),
    ],
  );
}

class QuickArticlePage extends StatefulWidget {
  const QuickArticlePage({super.key});
  @override
  State<QuickArticlePage> createState() => _QuickArticlePageState();
}

class _QuickArticlePageState extends State<QuickArticlePage> {
  int step = 0;
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(step == 2 ? 'Đã đọc hết hướng dẫn' : 'Hướng dẫn nhanh'),
    ),
    bottomNavigationBar: const SafeArea(
      top: false,
      child: Padding(padding: EdgeInsets.all(16), child: CallHelp()),
    ),
    body: ListView(
      controller: scroll,
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Bỏng',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const AidCard(
          'Đối tượng: Người lớn',
          'Phạm vi áp dụng: nội dung demo, chưa có chỉ dẫn y khoa.',
          color: Color(0xFFF0FDFA),
        ),
        const SizedBox(height: 16),
        const AidCard(
          'Bản thiết kế minh họa',
          'Các bước chuyên môn sẽ lấy từ nội dung đã được kiểm duyệt.',
          color: Color(0xFFEFF6FF),
        ),
        const SizedBox(height: 16),
        const AidCard(
          'Phạm vi • Nhận biết • Cần làm ngay',
          '[applies_to]\n[recognition] • [quick_actions]',
          color: Color(0xFFF0FDFA),
        ),
        const SizedBox(height: 24),
        Text(
          'BƯỚC ${step + 1} / 3',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AidCard(
          'Minh họa bước ${step + 1}',
          'Bản hướng dẫn bằng chữ vẫn luôn hiển thị.',
          color: const Color(0xFFF0FDFA),
        ),
        const SizedBox(height: 16),
        const Text(
          '[Nội dung bước đã kiểm duyệt]',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vị trí dành cho hướng dẫn rõ ràng, ngắn gọn từ bài sơ cứu đã công bố.',
        ),
        const SizedBox(height: 16),
        const AidCard(
          'Lưu ý & khi cần trợ giúp',
          'Hiển thị cảnh báo và dấu hiệu cần trợ giúp theo nguồn đã duyệt.',
          color: Color(0xFFFFFBEB),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => openPage(context, const SourcePage()),
          child: const Text('Nguồn tham chiếu  ↗'),
        ),
        const SizedBox(height: 16),
        AidButton(step == 2 ? 'Quay về danh sách' : 'Bước tiếp theo', () {
          if (step == 2) {
            Navigator.popUntil(context, (route) => route.isFirst);
            openPage(context, const QuickAidList());
          } else {
            setState(() => step++);
            scroll.jumpTo(0);
          }
        }),
        if (step > 0)
          TextButton(
            onPressed: () {
              setState(() => step--);
              scroll.jumpTo(0);
            },
            child: const Text('Bước trước'),
          ),
      ],
    ),
  );
}

class SourcePage extends StatelessWidget {
  const SourcePage({super.key});
  @override
  Widget build(BuildContext context) => AidScaffold(
    title: 'Nguồn tài liệu',
    children: [
      const Text(
        'Nguồn tài liệu',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const AidCard(
        'Tài liệu tham chiếu minh họa',
        'Đơn vị phát hành: [đơn vị]\nNăm xuất bản: [năm]\nTrang: [trang trích dẫn]',
      ),
      const Text(
        'Thông tin nguồn được lưu cùng bài và có thể đọc ngoại tuyến.',
      ),
      const Text('Đường dẫn gốc chỉ xuất hiện khi nguồn có URL hợp lệ.'),
      AidButton('Về bài hướng dẫn', () => Navigator.pop(context)),
    ],
  );
}
