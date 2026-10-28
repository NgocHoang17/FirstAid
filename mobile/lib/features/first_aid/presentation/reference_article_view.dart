import 'package:flutter/material.dart';
import '../data/reference_content_repository.dart';
import 'quick_aid_pages.dart';

class ReferenceArticleView extends StatefulWidget {
  const ReferenceArticleView({
    required this.article,
    required this.library,
    super.key,
  });
  final ReferenceArticle article;
  final ReferenceLibrary library;
  @override
  State<ReferenceArticleView> createState() => _ReferenceArticleViewState();
}

class _ReferenceArticleViewState extends State<ReferenceArticleView> {
  int step = 0;
  bool learn = false;
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final current = article.steps[step];
    return Scaffold(
      appBar: AppBar(title: const Text('Hướng dẫn tham khảo')),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: Padding(padding: EdgeInsets.all(16), child: CallHelp()),
      ),
      body: ListView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            article.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AidCard(
            'Đối tượng: ${article.ageLabel}',
            article.scope,
            color: const Color(0xFFF0FDFA),
          ),
          const SizedBox(height: 16),
          if (!article.isPublic) ...[
            AidCard(
              'Bản tham khảo đang rà soát',
              widget.library.reviewNotice,
              color: const Color(0xFFFFFBEB),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Xem nhanh'),
                selected: !learn,
                onSelected: (_) => setState(() => learn = false),
              ),
              ChoiceChip(
                label: const Text('Đọc đầy đủ'),
                selected: learn,
                onSelected: (_) => setState(() => learn = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (learn) ...[
            AidCard('Tóm tắt', article.summary),
            const SizedBox(height: 16),
            AidCard(
              'Nhận biết',
              article.texts('recognition').map((s) => '• $s').join('\n\n'),
            ),
            const SizedBox(height: 16),
          ],
          AidCard(
            'Cần làm ngay',
            article.texts('quick_actions').map((s) => '• $s').join('\n\n'),
            color: const Color(0xFFF0FDFA),
          ),
          const SizedBox(height: 24),
          if (learn)
            for (final item in article.steps) ...[
              Text(
                'Bước ${item.position}. ${item.title}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.instruction,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
              const SizedBox(height: 24),
            ]
          else ...[
            Text(
              'BƯỚC ${step + 1} / ${article.steps.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              current.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              current.instruction,
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
            const SizedBox(height: 24),
          ],
          AidCard(
            'Không nên làm',
            article.texts('warnings').map((s) => '• $s').join('\n\n'),
            color: const Color(0xFFFFFBEB),
          ),
          const SizedBox(height: 16),
          AidCard(
            'Khi cần hỗ trợ',
            article.texts('seek_help').map((s) => '• $s').join('\n\n'),
            color: const Color(0xFFEFF6FF),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => openPage(
              context,
              ReferenceSourcesView(article: article, library: widget.library),
            ),
            child: const Text('Nguồn tham chiếu  ↗'),
          ),
          const SizedBox(height: 16),
          if (!learn) ...[
            if (step < article.steps.length - 1)
              AidButton('Bước tiếp theo', () {
                setState(() => step++);
                scroll.jumpTo(0);
              })
            else
              AidButton('Về chọn bài', () => Navigator.pop(context)),
            if (step > 0)
              TextButton(
                onPressed: () {
                  setState(() => step--);
                  scroll.jumpTo(0);
                },
                child: const Text('Bước trước'),
              ),
          ],
        ],
      ),
    );
  }
}

class ReferenceSourcesView extends StatelessWidget {
  const ReferenceSourcesView({
    required this.article,
    required this.library,
    super.key,
  });
  final ReferenceArticle article;
  final ReferenceLibrary library;
  @override
  Widget build(BuildContext context) => AidScaffold(
    title: 'Nguồn tài liệu',
    children: [
      Text(
        article.title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      for (final sourceId
          in article.references.map((ref) => ref.sourceId).toSet())
        AidCard(
          library.sources[sourceId]!.title,
          'Biên soạn: ${library.sources[sourceId]!.publisher}\nNăm xuất bản: ${library.sources[sourceId]!.year}',
        ),
      AidButton('Về bài hướng dẫn', () => Navigator.pop(context)),
    ],
  );
}
