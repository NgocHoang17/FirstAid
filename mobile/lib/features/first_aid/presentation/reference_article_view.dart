import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feature_widgets.dart';
import 'package:flutter/material.dart';
import '../data/reference_content_repository.dart';
import 'quick_aid_pages.dart';
import 'step_illustration.dart';
import 'step_gallery.dart';

class ReferenceArticleView extends StatefulWidget {
  const ReferenceArticleView({
    required this.article,
    required this.library,
    this.initialLearn = false,
    super.key,
  });
  final ReferenceArticle article;
  final ReferenceLibrary library;
  final bool initialLearn;
  @override
  State<ReferenceArticleView> createState() => _ReferenceArticleViewState();
}

class _ReferenceArticleViewState extends State<ReferenceArticleView> {
  int step = 0;
  late bool learn = widget.initialLearn;
  final scroll = ScrollController();
  final currentStep = GlobalKey();

  void moveStep(int direction) {
    setState(() => step += direction);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = currentStep.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: MediaQuery.disableAnimationsOf(target)
              ? Duration.zero
              : const Duration(milliseconds: 240),
        );
      }
    });
  }

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
      appBar: AppBar(
        title: Text(learn ? 'Bài kiến thức' : 'Hướng dẫn tham khảo'),
      ),
      bottomNavigationBar: learn
          ? null
          : const SafeArea(
              top: false,
              child: Padding(padding: EdgeInsets.all(16), child: CallHelp()),
            ),
      body: SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeatureHeader(
              article.title,
              subtitle: 'Bài học sơ cứu · ${article.ageLabel}',
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 16),
            if (learn) ...[
              AidButton(
                'Mở hướng dẫn nhanh',
                () => setState(() => learn = false),
              ),
              const SizedBox(height: 16),
            ],
            AidCard(
              'Đối tượng: ${article.ageLabel}',
              article.scope,
              color: AppColors.tint,
            ),
            const SizedBox(height: 16),
            if (!article.isPublic) ...[
              AidCard(
                'Bản tham khảo đang rà soát',
                widget.library.reviewNotice,
                color: AppColors.warning,
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
              color: AppColors.tint,
            ),
            const SizedBox(height: 24),
            if (learn)
              for (final item in article.steps) ...[
                _ReferenceStepBlock(
                  step: item,
                  title: 'Bước ${item.position}. ${item.title}',
                  key: ValueKey('learn-${item.json['id']}'),
                ),
                const SizedBox(height: 24),
              ]
            else ...[
              Text(
                'BƯỚC ${step + 1} / ${article.steps.length}',
                key: currentStep,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (step + 1) / article.steps.length,
                  minHeight: 5,
                  color: AppColors.accentInk,
                  backgroundColor: AppColors.tint,
                  semanticsLabel: 'Tiến trình hướng dẫn',
                ),
              ),
              const SizedBox(height: 16),
              _ReferenceStepBlock(
                step: current,
                title: current.title,
                key: ValueKey(current.json['id']),
              ),
              const SizedBox(height: 24),
            ],
            AidCard(
              'Không nên làm',
              article.texts('warnings').map((s) => '• $s').join('\n\n'),
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            AidCard(
              'Khi cần hỗ trợ',
              article.texts('seek_help').map((s) => '• $s').join('\n\n'),
              color: AppColors.info,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => openPage(
                context,
                ReferenceSourcesView(article: article, library: widget.library),
              ),
              child: const Text('Nguồn tham chiếu  ↗'),
            ),
            if (article.isPublic && widget.library.reviewNotice.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.library.reviewNotice,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (!learn) ...[
              if (step < article.steps.length - 1)
                AidButton('Bước tiếp theo', () {
                  moveStep(1);
                })
              else
                AidButton('Về chọn bài', () => Navigator.pop(context)),
              if (step > 0)
                TextButton(
                  onPressed: () {
                    moveStep(-1);
                  },
                  child: const Text('Bước trước'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReferenceStepBlock extends StatelessWidget {
  const _ReferenceStepBlock({
    required this.step,
    required this.title,
    super.key,
  });
  final ReferenceStep step;
  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            step.instruction,
            style: const TextStyle(fontSize: 18, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (step.images.isEmpty) StepIllustration(step: step),
          StepGallery(step: step),
        ],
      ),
    ),
  );
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
          'Biên soạn: ${library.sources[sourceId]!.publisher}\nNăm xuất bản: ${library.sources[sourceId]!.year ?? 'Không nêu'}',
        ),
      AidButton('Về bài hướng dẫn', () => Navigator.pop(context)),
    ],
  );
}
