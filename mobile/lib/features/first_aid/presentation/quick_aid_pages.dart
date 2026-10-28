import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../data/reference_content_repository.dart';
import 'reference_article_view.dart';

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
          'Nội dung tham khảo trên thiết bị',
          'Một số bài có nguồn đang được rà soát trên bản phát triển. Chọn bài để xem phạm vi và tài liệu tham chiếu.',
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

class AudiencePage extends StatefulWidget {
  const AudiencePage({required this.category, super.key});
  final String category;
  @override
  State<AudiencePage> createState() => _AudiencePageState();
}

class _AudiencePageState extends State<AudiencePage> {
  late final Future<ReferenceLibrary> _library =
      ReferenceContentRepository.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<ReferenceLibrary>(
    future: _library,
    builder: (context, snapshot) {
      final library = snapshot.data;
      final index = situations.indexOf(widget.category);
      final code = 'FA${(index + 1).toString().padLeft(2, '0')}';
      final articles = library?.forCategory(code) ?? <ReferenceArticle>[];
      return AidScaffold(
        title: 'Chọn hướng dẫn',
        call: true,
        children: [
          Text(
            widget.category,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Bài dùng chung áp dụng cho người lớn và trẻ em. Nếu có bài riêng, hãy chọn đúng độ tuổi và phạm vi.',
          ),
          if (snapshot.connectionState != ConnectionState.done)
            const Center(child: CircularProgressIndicator())
          else if (snapshot.hasError)
            const AidCard(
              'Không tải được nội dung',
              'Quay lại và thử mở danh mục lần nữa. Nút gọi hỗ trợ vẫn sử dụng được.',
            )
          else ...[
            if (articles.isEmpty)
              const AidCard(
                'Chưa có bài phù hợp',
                'Nhóm này chưa có nội dung để hiển thị trên bản ứng dụng này.',
              ),
            for (final article in articles)
              AidCard(
                article.title,
                '${article.ageLabel} • ${article.isPublic ? 'Nội dung có nguồn' : 'Bản tham khảo đang rà soát'}\n${article.scope}',
                onTap: () => openPage(
                  context,
                  ReferenceArticleView(article: article, library: library!),
                ),
              ),
            for (final age in ['Người lớn', 'Trẻ em'])
              if (!articles.any(
                (a) => a.ageLabel == age || a.ageGroup == 'ALL',
              ))
                OutlinedButton(
                  onPressed: () => openPage(
                    context,
                    UnsupportedAudience(category: '${widget.category} — $age'),
                  ),
                  child: Text('$age — chưa có bài phù hợp'),
                ),
          ],
        ],
      );
    },
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
