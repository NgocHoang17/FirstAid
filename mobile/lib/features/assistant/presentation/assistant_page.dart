import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/assistant_cubit.dart';
import '../../../core/network/app_services.dart';
import '../../../core/widgets/feature_widgets.dart';
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
  final inputFocus = FocusNode();
  final scroll = ScrollController();
  final latestAnswer = GlobalKey();
  String? age;
  String? lastSubmitted;
  Uint8List? attachment;
  String? mime;
  bool picking = false;

  Future<void> pickPhoto() async {
    if (picking || cubit.state.sending) return;
    setState(() => picking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      if (await file.length() > 5 * 1024 * 1024) {
        throw const FormatException('Ảnh vượt quá 5 MiB.');
      }
      final bytes = await file.readAsBytes();
      final type = bytes.length >= 8 && bytes[0] == 137 && bytes[1] == 80
          ? 'image/png'
          : bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 216
          ? 'image/jpeg'
          : null;
      if (type == null) {
        throw const FormatException('Hãy chọn ảnh JPEG hoặc PNG.');
      }
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        try {
          if (descriptor.width * descriptor.height > 16000000) {
            throw const FormatException('Ảnh vượt quá 16 triệu điểm ảnh.');
          }
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
      if (mounted) {
        setState(() {
          attachment = bytes;
          mime = type;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message
                  : 'Không đọc được ảnh. Hãy chọn ảnh khác.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  @override
  void dispose() {
    cubit.close();
    input.dispose();
    inputFocus.dispose();
    scroll.dispose();
    super.dispose();
  }

  void bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  });
  void submit() {
    if (input.text.trim().isEmpty || cubit.state.sending || picking) return;
    final message = input.text;
    lastSubmitted = message.trim();
    FocusScope.of(context).unfocus();
    input.value = TextEditingValue.empty;
    setState(() {});
    cubit.send(message, age, image: attachment, mime: mime);
    attachment = null;
    mime = null;
    bottom();
    WidgetsBinding.instance.addPostFrameCallback((_) => clearSubmitted());
  }

  void clearSubmitted() {
    if (mounted && input.text.trim() == lastSubmitted && !inputFocus.hasFocus) {
      input.value = TextEditingValue.empty;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Trò chuyện cùng FirstAid',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          tooltip: 'Cuộc trò chuyện mới',
          onPressed: cubit.state.sending
              ? null
              : () {
                  cubit.clearConversation();
                  input.clear();
                  setState(() {
                    age = null;
                    attachment = null;
                    mime = null;
                  });
                },
          icon: const Icon(Icons.add_comment_outlined),
        ),
        if (widget.onSettings != null)
          IconButton(
            tooltip: 'Cài đặt và dữ liệu',
            onPressed: widget.onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
      ],
    ),
    body: BlocConsumer<AssistantCubit, AssistantState>(
      bloc: cubit,
      listener: (_, state) {
        final readingLatest =
            !scroll.hasClients || scroll.position.extentAfter < 96;
        if (!state.sending) {
          clearSubmitted();
          lastSubmitted = null;
        }
        if (state.sending) {
          bottom();
        } else if (readingLatest) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final anchor = latestAnswer.currentContext;
            if (anchor != null) {
              Scrollable.ensureVisible(
                anchor,
                duration: const Duration(milliseconds: 180),
              );
            }
          });
        }
        setState(() {});
      },
      builder: (context, state) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                if (state.turns.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.accentSoft,
                          child: Icon(
                            Icons.forum_outlined,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Bạn muốn tìm hiểu điều gì?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Cùng tìm hiểu sơ cứu. Bạn có thể hỏi tiếp trong cuộc trò chuyện này.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  for (final suggestion in [
                    'Tìm hiểu về bỏng',
                    'Cách xử trí chảy máu cam',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton(
                        onPressed: () {
                          input.text = suggestion;
                          setState(() {});
                        },
                        child: Text(suggestion),
                      ),
                    ),
                ],
                for (final (index, turn) in state.turns.indexed) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 32,
                        bottom: 16,
                        top: 8,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: SelectableText(
                        turn.hasImage
                            ? 'Ảnh học tập\n${turn.message}'
                            : turn.message,
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (turn.reply != null)
                    Container(
                      key: index == state.turns.length - 1
                          ? latestAnswer
                          : null,
                      margin: const EdgeInsets.only(right: 12, bottom: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ChatReplyView(
                        turn: turn,
                        api: widget.api,
                        onKnowledge: widget.onKnowledge,
                        onRetry:
                            index == state.turns.length - 1 &&
                                !state.sending &&
                                !turn.hasImage
                            ? () => cubit.send(
                                turn.message,
                                turn.age,
                                retry: true,
                              )
                            : null,
                      ),
                    ),
                ],
                if (state.sending)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Expanded(child: Text('FirstAid đang tìm câu trả lời…')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (state.offline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: widget.onKnowledge,
                child: const Text('Bạn đang ngoại tuyến · Mở kiến thức đã lưu'),
              ),
            ),
          Material(
            color: AppColors.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: age ?? '',
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(
                                value: '',
                                child: Text('Đối tượng: theo cuộc trò chuyện'),
                              ),
                              DropdownMenuItem(
                                value: 'ADULT',
                                child: Text('Người lớn'),
                              ),
                              DropdownMenuItem(
                                value: 'CHILD',
                                child: Text('Trẻ em'),
                              ),
                            ],
                            onChanged: state.sending
                                ? null
                                : (value) => setState(
                                    () => age = value == '' ? null : value,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (attachment != null)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Image.memory(
                          attachment!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          cacheWidth: 96,
                        ),
                        title: const Text('Gửi ảnh học liệu đến Gemini'),
                        trailing: IconButton(
                          tooltip: 'Bỏ ảnh',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            attachment = null;
                            mime = null;
                          }),
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Chọn ảnh học liệu',
                          onPressed: state.sending || picking
                              ? null
                              : pickPhoto,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                        Expanded(
                          child: TextField(
                            controller: input,
                            focusNode: inputFocus,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => submit(),
                            minLines: 1,
                            maxLines: 4,
                            maxLength: 2000,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Câu hỏi',
                              hintText: 'Nhắn tin hoặc hỏi tiếp…',
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Gửi câu hỏi',
                          onPressed:
                              state.sending ||
                                  picking ||
                                  input.text.trim().isEmpty
                              ? null
                              : submit,
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Hỗ trợ học tập, không thay thế tư vấn hoặc cấp cứu y tế.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
            (a.ageGroup == turn.age || a.ageGroup == 'ALL'),
      );
      final outdated = reply.citations.any(
        (citation) =>
            library.sources[citation.sourceId]?.json['revision'] !=
                citation.revision ||
            (matches.length == 1 &&
                citation.json['article_revision'] != null &&
                citation.json['article_revision'] !=
                    matches.single.json['content_revision']),
      );
      final missing = !library.articles.any(
        (a) => a.id == reply.articleId && a.isPublic,
      );
      if (reply.articleId != null && (outdated || missing)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Bản bài học trên máy khác phiên bản trong câu trả lời.',
            ),
            action: SnackBarAction(
              label: 'Cập nhật',
              onPressed: context.read<ContentUpdateCubit>().update,
            ),
          ),
        );
        return;
      }
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
        'Mình hỏi thêm một chút nhé',
        '${reply.question}',
      ),
      ChatStatus.emergencyRedirect => (
        'Ưu tiên trợ giúp trực tiếp',
        'Hệ thống chuyển đến hướng dẫn trên thiết bị. Không chờ câu trả lời AI.',
      ),
      ChatStatus.insufficientEvidence => (
        'Mình chưa có đủ thông tin để trả lời',
        'Bạn có thể nói rõ hơn điều muốn tìm hiểu, hoặc mở bài học liên quan. Mình sẽ không suy đoán khi tài liệu chưa đủ để giải đáp.',
      ),
      ChatStatus.outOfScope => (
        'Mình có thể giúp bạn tìm hiểu về sơ cứu',
        'Bạn hãy hỏi về kiến thức sơ cứu cơ bản cho người lớn hoặc trẻ em. Mình không hỗ trợ chẩn đoán hay kê đơn.',
      ),
      ChatStatus.unavailable => (
        'Chưa thể trả lời lúc này',
        turn.issue ??
            (turn.offline
                ? 'Hỏi đáp cần kết nối mạng. Câu hỏi của bạn vẫn được giữ.'
                : 'Dịch vụ tạm gián đoạn. Bạn vẫn có thể dùng bài đã tải.'),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reply.status == ChatStatus.answered)
          for (final (index, block) in reply.blocks.indexed) ...[
            if (reply.blockKinds.length > index &&
                {'warning', 'help'}.contains(reply.blockKinds[index]) &&
                (index == 0 ||
                    reply.blockKinds[index - 1] != reply.blockKinds[index]))
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Text(
                  reply.blockKinds[index] == 'warning'
                      ? 'Lưu ý'
                      : 'Khi cần trợ giúp',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    if (index > 1 &&
                        block.indexOf(': ') > 0 &&
                        block.indexOf(': ') < 85) ...[
                      TextSpan(
                        text: '${block.substring(0, block.indexOf(': '))}\n',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: block.substring(block.indexOf(': ') + 2)),
                    ] else
                      TextSpan(text: block),
                  ],
                ),
                style: TextStyle(
                  fontSize:
                      (reply.blockKinds.isEmpty
                          ? index == 0
                          : reply.blockKinds[index] == 'heading')
                      ? 19
                      : 16,
                  height: 1.6,
                  fontWeight:
                      (reply.blockKinds.isEmpty
                          ? index == 0
                          : reply.blockKinds[index] == 'heading')
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ]
        else ...[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 8),
          SelectableText(
            message,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        ],
        sectionGap,
        if (reply.status == ChatStatus.answered) ...[
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
