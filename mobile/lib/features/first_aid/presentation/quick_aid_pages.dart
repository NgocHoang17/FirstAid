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
    this.color = AppColors.surface,
    this.icon,
    super.key,
  });
  final String title, subtitle;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
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
  const QuickAidHome({
    this.onKnowledge,
    this.onSettings,
    this.libraryLoader,
    super.key,
  });
  final VoidCallback? onKnowledge, onSettings;
  final Future<ReferenceLibrary> Function()? libraryLoader;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        if (onSettings != null)
          IconButton(
            tooltip: "Cài đặt và dữ liệu",
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
      ],
      title: const Row(
        children: [
          Icon(Icons.health_and_safety_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'FirstAid',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Bình tĩnh.\nTừng bước, đúng cách.',
          style: TextStyle(
            fontSize: 30,
            height: 1.25,
            letterSpacing: -.6,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Tra cứu kiến thức và hướng dẫn sơ cứu cơ bản.'),
        const SizedBox(height: 16),
        Material(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () =>
                openPage(context, QuickAidList(libraryLoader: libraryLoader)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        color: AppColors.onPrimaryMuted,
                        size: 30,
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: AppColors.onPrimaryMuted,
                        size: 24,
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Cần sơ cứu ngay?',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Mở hướng dẫn nhanh\nCó thể dùng ngoại tuyến',
                    style: TextStyle(color: AppColors.onPrimaryMuted),
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
          'Xem phạm vi áp dụng và nguồn của từng bài trước khi thực hiện hướng dẫn.',
          color: AppColors.tint,
          icon: Icons.offline_pin_outlined,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed:
              onKnowledge ??
              () =>
                  openPage(context, QuickAidList(libraryLoader: libraryLoader)),
          icon: const Icon(Icons.search),
          label: const Text("Tìm bài sơ cứu…"),
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
            '${group.$2 - group.$1} nhóm tình huống • Xem hướng dẫn',
            icon: group.$1 == 0
                ? Icons.favorite_outline_rounded
                : group.$1 == 4
                ? Icons.healing_rounded
                : Icons.eco_outlined,
            onTap: () => openPage(
              context,
              QuickAidList(
                start: group.$1,
                end: group.$2,
                libraryLoader: libraryLoader,
              ),
            ),
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
  const QuickAidList({
    this.start = 0,
    this.end = 18,
    this.libraryLoader,
    super.key,
  });
  final int start, end;
  final Future<ReferenceLibrary> Function()? libraryLoader;
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
            color: AppColors.info,
          ),
        for (final i in matches)
          AidCard(
            '${(i + 1).toString().padLeft(2, '0')}   ${situations[i]}',
            'Chọn để xem hướng dẫn  ›',
            onTap: () => openPage(
              context,
              AudiencePage(
                category: situations[i],
                libraryLoader: widget.libraryLoader,
              ),
            ),
          ),
      ],
    );
  }
}

class AudiencePage extends StatefulWidget {
  const AudiencePage({required this.category, this.libraryLoader, super.key});
  final String category;
  final Future<ReferenceLibrary> Function()? libraryLoader;
  @override
  State<AudiencePage> createState() => _AudiencePageState();
}

class _AudiencePageState extends State<AudiencePage> {
  late final Future<ReferenceLibrary> _library =
      (widget.libraryLoader ?? ReferenceContentRepository.load)();
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
        color: AppColors.info,
      ),
      AidButton('Chọn lại đối tượng', () => Navigator.pop(context)),
    ],
  );
}
