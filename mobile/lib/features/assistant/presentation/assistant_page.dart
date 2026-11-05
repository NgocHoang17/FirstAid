import '../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/assistant_cubit.dart';
import '../../../core/network/app_services.dart';
import '../../../core/widgets/feature_widgets.dart';
import '../../first_aid/data/reference_content_repository.dart';
import '../../first_aid/presentation/quick_aid_pages.dart';
import '../../first_aid/presentation/reference_article_view.dart';
import '../../settings/data/content_update_cubit.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({
    required this.api,
    required this.onKnowledge,
    this.onSettings,
    super.key,
  });
  final PublicApi api;
  final VoidCallback onKnowledge;
  final VoidCallback? onSettings;
  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  late final cubit = AssistantCubit(widget.api)..checkConnection();
  final input = TextEditingController();
  final scroll = ScrollController(keepScrollOffset: false);
  String? age;
  @override
  void dispose() {
    cubit.close();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void submit() {
    FocusScope.of(context).unfocus();
    cubit.send(input.text, age);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar('Hỏi đáp', onSettings: widget.onSettings),
    body: BlocBuilder<AssistantCubit, AssistantState>(
      bloc: cubit,
      builder: (context, state) => ListView(
        controller: scroll,
        padding: pagePadding,
        children: [
          const FeatureHeader(
            'Hỏi đáp từ tài liệu',
            subtitle:
                'Mỗi câu hỏi được xử lý độc lập. Không dùng để chẩn đoán. Không nhập thông tin cá nhân.',
          ),
          sectionGap,
          if (state.offline) ...[
            StatusCard(
              'Bạn đang ngoại tuyến',
              'Hỏi đáp cần kết nối mạng. Kiến thức đã tải vẫn sử dụng được.',
              action: 'Kiểm tra kết nối',
              onAction: cubit.checkConnection,
            ),
            sectionGap,
            AidButton('Mở kiến thức ngoại tuyến', widget.onKnowledge),
            sectionGap,
          ],
          if (state.turns.isEmpty) ...[
            const AidCard(
              'Bạn muốn tìm hiểu điều gì?',
              'Nhập câu hỏi về kiến thức sơ cứu cơ bản.',
              color: AppColors.tint,
            ),
            sectionGap,
            for (final suggestion in [
              'Tìm hiểu về bỏng',
              'Những lưu ý khi sơ cứu',
            ]) ...[
              OutlinedButton(
                onPressed: () {
                  input.text = suggestion;
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(suggestion),
                ),
              ),
              sectionGap,
            ],
          ],
          for (final (index, turn) in state.turns.indexed) ...[
            AidCard(turn.message, 'Câu hỏi của bạn', color: AppColors.info),
            sectionGap,
            if (turn.reply != null) ...[
              ChatReplyView(
                turn: turn,
                api: widget.api,
                onKnowledge: widget.onKnowledge,
                onRetry: index == state.turns.length - 1 && !state.sending
                    ? () => cubit.send(turn.message, turn.age, retry: true)
                    : null,
              ),
              sectionGap,
            ],
          ],
          if (state.sending) ...[
            const StatusCard(
              'Đang tra cứu tài liệu…',
              'Vui lòng chờ phản hồi.',
              loading: true,
            ),
            sectionGap,
          ],
          const Text(
            'Đối tượng trong câu hỏi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final filter in [
                (null, 'Không chỉ định'),
                ('ADULT', 'Người lớn'),
                ('CHILD', 'Trẻ em'),
              ])
                ChoiceChip(
                  label: Text(filter.$2),
                  selected: age == filter.$1,
                  onSelected: state.sending
                      ? null
                      : (_) => setState(() => age = filter.$1),
                ),
            ],
          ),
          sectionGap,
          TextField(
            controller: input,
            enabled: !state.sending,
            minLines: 2,
            maxLines: 5,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Câu hỏi',
              hintText: 'Nhập câu hỏi sơ cứu…',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          sectionGap,
          FilledButton(
            onPressed: state.sending || input.text.trim().isEmpty
                ? null
                : submit,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(state.sending ? 'Đang tra cứu…' : 'Gửi câu hỏi'),
            ),
          ),
          sectionGap,
        ],
      ),
    ),
  );
}

class ChatReplyView extends StatelessWidget {
  const ChatReplyView({
    required this.turn,
    required this.api,
    required this.onKnowledge,
    this.onRetry,
    super.key,
  });
  final ChatTurn turn;
  final PublicApi api;
  final VoidCallback onKnowledge;
  final VoidCallback? onRetry;

  void _openRelated(BuildContext context) {
    final reply = turn.reply!;
    final library = context.read<ContentUpdateCubit>().state.library;
    if (library != null) {
      final matches = library.articles.where(
        (a) =>
            a.id == reply.articleId &&
            a.isPublic &&
            (turn.age == null || a.ageGroup == turn.age || a.ageGroup == 'ALL'),
      );
      if (matches.length == 1) {
        openPage(
          context,
          ReferenceArticleView(article: matches.single, library: library),
        );
        return;
      }
    }
    final index = int.tryParse(
      (reply.categoryCode ?? '').replaceFirst('FA', ''),
    );
    if (index != null &&
        index >= 1 &&
        index <= 18 &&
        reply.categoryCode == 'FA${index.toString().padLeft(2, '0')}') {
      openPage(
        context,
        AudiencePage(
          category: situations[index - 1],
          libraryLoader: library == null ? null : () async => library,
        ),
      );
    } else {
      openPage(
        context,
        QuickAidList(
          libraryLoader: library == null ? null : () async => library,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reply = turn.reply!;
    final (title, message) = switch (reply.status) {
      ChatStatus.answered => (
        'Thông tin từ tài liệu',
        reply.blocks.join('\n\n'),
      ),
      ChatStatus.clarificationNeeded => (
        'Cần thêm thông tin',
        '${reply.question}\n\nHãy gửi lại câu hỏi đầy đủ kèm thông tin bổ sung.',
      ),
      ChatStatus.emergencyRedirect => (
        'Ưu tiên trợ giúp trực tiếp',
        'Hệ thống chuyển đến hướng dẫn trên thiết bị. Không chờ câu trả lời AI.',
      ),
      ChatStatus.insufficientEvidence => (
        'Chưa đủ bằng chứng',
        'Chưa tìm thấy tài liệu phù hợp để trả lời. Bạn có thể xem các bài đã lưu hoặc hỏi nhân viên y tế.',
      ),
      ChatStatus.outOfScope => (
        'Ngoài phạm vi sơ cứu',
        'Hệ thống hỗ trợ kiến thức sơ cứu cơ bản cho người lớn và trẻ em.',
      ),
      ChatStatus.unavailable => (
        'Chưa thể trả lời lúc này',
        turn.offline
            ? 'Hỏi đáp cần kết nối mạng. Câu hỏi của bạn vẫn được giữ.'
            : 'Dịch vụ tạm gián đoạn. Bạn vẫn có thể dùng bài đã tải.',
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AidCard(
          title,
          message,
          color: reply.status == ChatStatus.answered
              ? AppColors.tint
              : AppColors.warning,
        ),
        sectionGap,
        if (reply.status == ChatStatus.answered) ...[
          for (final (index, citation) in reply.citations.indexed) ...[
            OutlinedButton(
              onPressed: () => openPage(
                context,
                CitationSourcePage(
                  citation: citation,
                  api: api,
                  library: context.read<ContentUpdateCubit>().state.library,
                ),
              ),
              child: Text('Nguồn tham chiếu ${index + 1} ↗'),
            ),
            const SizedBox(height: 8),
          ],
          if (reply.articleId != null || reply.categoryCode != null)
            OutlinedButton(
              onPressed: () => _openRelated(context),
              child: const Text('Xem bài liên quan'),
            ),
        ],
        if (reply.status == ChatStatus.emergencyRedirect) ...[
          AidButton('Mở sơ cứu nhanh', () => _openRelated(context)),
          sectionGap,
          const CallHelp(),
        ] else if (reply.status != ChatStatus.answered) ...[
          if (reply.status == ChatStatus.unavailable && onRetry != null) ...[
            AidButton('Thử lại câu hỏi', onRetry!),
            sectionGap,
          ],
          OutlinedButton(
            onPressed: onKnowledge,
            child: const Text('Xem kiến thức đã lưu'),
          ),
        ],
      ],
    );
  }
}

class CitationSourcePage extends StatefulWidget {
  const CitationSourcePage({
    required this.citation,
    required this.api,
    this.library,
    super.key,
  });
  final ChatCitation citation;
  final PublicApi api;
  final ReferenceLibrary? library;
  @override
  State<CitationSourcePage> createState() => _CitationSourcePageState();
}

class _CitationSourcePageState extends State<CitationSourcePage> {
  late Future<ReferenceSource> source = load();
  Future<ReferenceSource> load() async {
    final local = widget.library?.sources[widget.citation.sourceId];
    if (local != null && local.json['revision'] == widget.citation.revision) {
      return local;
    }
    final response = await widget.api.get(
      '/sources/${Uri.encodeComponent(widget.citation.sourceId)}',
    );
    final row = Map<String, dynamic>.from(
      (response.data as Map)['data'] as Map,
    );
    final source = ReferenceSource(row);
    if (source.id != widget.citation.sourceId ||
        row['revision'] != widget.citation.revision ||
        source.title.isEmpty ||
        source.publisher.isEmpty ||
        row['is_active'] != true) {
      throw const FormatException('Source revision mismatch');
    }
    return source;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const FeatureAppBar('Nguồn tham chiếu'),
    body: FutureBuilder<ReferenceSource>(
      future: source,
      builder: (context, snapshot) => ListView(
        padding: pagePadding,
        children: [
          if (snapshot.data case final ReferenceSource value)
            AidCard(
              value.title,
              'Biên soạn: ${value.publisher}\nNăm xuất bản: ${value.year ?? 'Không nêu'}',
            )
          else
            StatusCard(
              snapshot.hasError ? 'Không tải được nguồn' : 'Đang tải nguồn…',
              snapshot.hasError
                  ? 'Chưa có thông tin nguồn phù hợp trên thiết bị. Hãy thử lại khi có mạng.'
                  : 'Đang mở thông tin tài liệu.',
              loading: !snapshot.hasError,
              action: snapshot.hasError ? 'Thử lại' : null,
              onAction: () => setState(() => source = load()),
            ),
        ],
      ),
    ),
  );
}
