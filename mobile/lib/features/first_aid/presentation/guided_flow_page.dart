import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/guided_flow_repository.dart';
import '../domain/guided_flow.dart';
import 'quick_aid_pages.dart';

class GuidedFlowPage extends StatefulWidget {
  const GuidedFlowPage({
    required this.categoryCode,
    required this.categoryName,
    super.key,
  });
  final String categoryCode, categoryName;
  @override
  State<GuidedFlowPage> createState() => _GuidedFlowPageState();
}

class _GuidedFlowPageState extends State<GuidedFlowPage> {
  late Future<GuidedFlowController> _loading;
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _loading = GuidedFlowRepository()
        .load(widget.categoryCode)
        .then(GuidedFlowController.new);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _update(VoidCallback action) {
    setState(action);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<GuidedFlowController>(
    future: _loading,
    builder: (context, snapshot) {
      final controller = snapshot.data;
      final node = controller?.current;
      return PopScope(
        canPop: !(controller?.canGoBack ?? false),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && controller != null) _update(controller.back);
        },
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              onPressed: () {
                if (controller?.canGoBack ?? false) {
                  _update(controller!.back);
                } else {
                  Navigator.maybePop(context);
                }
              },
            ),
            title: const Text(
              'Xác định tình huống',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.background,
          ),
          bottomNavigationBar: const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CallHelp(),
            ),
          ),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      widget.categoryName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const AidCard(
                      'Luồng minh họa — không dùng để sơ cứu',
                      'Câu hỏi và nhánh chuyên môn cần được chuẩn bị từ nguồn. Luồng không dùng AI để quyết định xử trí.',
                      color: Color(0xFFEFF6FF),
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.hasError || node == null) ...[
                      const AidCard(
                        'Không tải được luồng lựa chọn',
                        'Bạn vẫn có thể gọi hỗ trợ hoặc quay lại danh sách.',
                      ),
                      const SizedBox(height: 16),
                      AidButton('Thử lại', () => setState(_load)),
                    ] else if (node.type == GuidedNodeType.question) ...[
                      const Text(
                        '1 câu hỏi mỗi màn hình',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: AidCard(
                          node.prompt!,
                          '',
                          color: const Color(0xFFEFF6FF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final (index, option) in node.options.indexed) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 52),
                              padding: const EdgeInsets.all(16),
                              backgroundColor: index == 0
                                  ? AppColors.primary
                                  : AppColors.surface,
                              foregroundColor: index == 0
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () =>
                                _update(() => controller!.choose(option.code)),
                            child: Text(
                              option.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ] else ...[
                      Semantics(
                        liveRegion: true,
                        child: AidCard(
                          'Chưa có hướng dẫn phù hợp',
                          node.type == GuidedNodeType.openArticle
                              ? 'Chưa có bài local đã công bố khớp nhóm và đối tượng đã chọn. Không mở thay bằng bài khác.'
                              : 'Không đủ thông tin hoặc chưa có nội dung phù hợp. Không suy ra tình huống an toàn và không tự chọn hướng dẫn người lớn.',
                          color: const Color(0xFFEFF6FF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AidButton(
                        'Chọn lại từ đầu',
                        () => _update(controller!.restart),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Về danh sách'),
                      ),
                    ],
                    if (controller?.canGoBack ?? false)
                      TextButton(
                        onPressed: () => _update(controller!.back),
                        child: const Text('Câu trước'),
                      ),
                  ],
                ),
        ),
      );
    },
  );
}
