import '../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../first_aid/data/reference_content_repository.dart';
import '../../first_aid/presentation/quick_aid_pages.dart';
import '../../first_aid/presentation/reference_article_view.dart';
import '../../settings/data/content_update_cubit.dart';
import '../../../core/widgets/feature_widgets.dart';

const knowledgeGroups = {
  'CIRCULATION': 'Tuần hoàn & hô hấp',
  'TRAUMA': 'Chấn thương',
  'ENVIRONMENT': 'Môi trường',
  'OTHER': 'Tình huống khác',
};

List<ReferenceArticle> searchArticles(
  ReferenceLibrary library,
  String query, {
  String? age,
  String? group,
}) {
  final words = searchKey(
    query.trim(),
  ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final matches = library.articles
      .where((a) {
        final category = library.categories[a.categoryCode]!;
        if (age != null && a.ageGroup != age && a.ageGroup != 'ALL') {
          return false;
        }
        if (group != null && category.json['group_code'] != group) return false;
        final haystack = searchKey(
          '${a.title} ${a.summary} ${category.name} ${(category.json['keywords'] as List).join(' ')}',
        );
        return words.every(haystack.contains);
      })
      .toList(growable: false);
  final order = {
    for (final (index, article) in library.articles.indexed) article.id: index,
  };
  matches.sort((a, b) {
    final category = a.categoryCode.compareTo(b.categoryCode);
    return category != 0 ? category : order[a.id]!.compareTo(order[b.id]!);
  });
  return matches;
}

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({this.onSettings, super.key});
  final VoidCallback? onSettings;
  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  final search = TextEditingController();
  String? age, group;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar('Kiến thức', onSettings: widget.onSettings),
    body: BlocBuilder<ContentUpdateCubit, ContentState>(
      builder: (context, state) {
        final library = state.library;
        final articles = library == null
            ? <ReferenceArticle>[]
            : searchArticles(library, search.text, age: age, group: group);
        return ListView(
          padding: pagePadding,
          key: const PageStorageKey('knowledge'),
          children: [
            const FeatureHeader(
              'Kiến thức sơ cứu',
              icon: Icons.menu_book_outlined,
            ),
            sectionGap,
            TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm bài sơ cứu…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () => setState(search.clear),
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            sectionGap,
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final filter in [
                  (null, 'Tất cả'),
                  ('ADULT', 'Người lớn'),
                  ('CHILD', 'Trẻ em'),
                ])
                  ChoiceChip(
                    label: Text(filter.$2),
                    selected: age == filter.$1,
                    onSelected: (_) => setState(() => age = filter.$1),
                  ),
              ],
            ),
            sectionGap,
            if (library == null)
              StatusCard(
                state.status == UpdateStatus.loading
                    ? 'Đang tải kiến thức…'
                    : 'Không tải được kiến thức',
                'Các bài trên thiết bị sẽ hiển thị tại đây.',
                loading: state.status == UpdateStatus.loading,
                action: state.status == UpdateStatus.failed ? 'Thử lại' : null,
                onAction: () => context.read<ContentUpdateCubit>().load(),
              )
            else ...[
              if (group == null && search.text.isEmpty)
                for (final entry in knowledgeGroups.entries) ...[
                  AidCard(
                    entry.value,
                    'Khám phá các bài liên quan',
                    icon: switch (entry.key) {
                      'CIRCULATION' => Icons.favorite_outline_rounded,
                      'TRAUMA' => Icons.healing_rounded,
                      'ENVIRONMENT' => Icons.eco_outlined,
                      _ => Icons.health_and_safety_outlined,
                    },
                    color: AppColors.tint,
                    onTap: () => setState(() => group = entry.key),
                  ),
                  sectionGap,
                ],
              if (group != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: Text(knowledgeGroups[group]!),
                    onDeleted: () => setState(() => group = null),
                  ),
                ),
                sectionGap,
              ],
              Text(
                '${articles.length} bài hướng dẫn',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              sectionGap,
              if (articles.isEmpty)
                StatusCard(
                  'Không tìm thấy kết quả',
                  'Thử từ khóa khác hoặc bỏ bộ lọc để xem toàn bộ bài.',
                  action: 'Xem tất cả',
                  onAction: () => setState(() {
                    search.clear();
                    age = null;
                    group = null;
                  }),
                ),
              for (final article in articles) ...[
                AidCard(
                  article.title,
                  '${article.ageLabel}\n${article.summary}',
                  onTap: () => openPage(
                    context,
                    ReferenceArticleView(
                      article: article,
                      library: library,
                      initialLearn: true,
                    ),
                  ),
                ),
                sectionGap,
              ],
            ],
          ],
        );
      },
    ),
  );
}
