import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/app_services.dart';
import '../../../core/storage/snapshot_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../first_aid/presentation/quick_aid_pages.dart';
import '../../first_aid/data/reference_content_repository.dart';
import '../../knowledge/presentation/knowledge_page.dart';
import '../../assistant/presentation/assistant_page.dart';
import '../../facilities/presentation/facilities_page.dart';
import '../../settings/data/content_update_cubit.dart';
import '../../settings/presentation/settings_page.dart';

class MobileShell extends StatefulWidget {
  const MobileShell({this.api, this.store, super.key});
  final PublicApi? api;
  final SnapshotStore? store;
  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  late final api = widget.api ?? PublicApi();
  late final store = widget.store ?? SqliteSnapshotStore.instance;
  late final content = ContentUpdateCubit(api: api, store: store)..load();
  final pages = <int, Widget>{};
  int index = 0;
  Future<ReferenceLibrary> loadLibrary() async {
    if (content.state.status == UpdateStatus.loading) {
      await content.stream.firstWhere((s) => s.status != UpdateStatus.loading);
    }
    final library = content.state.library;
    if (library == null) throw const FormatException('Content unavailable');
    return library;
  }

  @override
  void dispose() {
    content.close();
    super.dispose();
  }

  void select(int value) {
    FocusScope.of(context).unfocus();
    setState(() => index = value);
  }

  void settings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          BlocProvider.value(value: content, child: const SettingsPage()),
    ),
  );
  Widget page(int value) => pages.putIfAbsent(
    value,
    () => switch (value) {
      0 => QuickAidHome(
        onKnowledge: () => select(1),
        onSettings: settings,
        libraryLoader: loadLibrary,
      ),
      1 => KnowledgePage(onSettings: settings),
      2 => AssistantPage(
        api: api,
        onKnowledge: () => select(1),
        onSettings: settings,
      ),
      _ => FacilitiesPage(api: api, store: store, onSettings: settings),
    },
  );
  @override
  Widget build(BuildContext context) {
    page(index);
    return BlocProvider.value(
      value: content,
      child: PopScope(
        canPop: index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && index != 0) select(0);
        },
        child: Scaffold(
          body: IndexedStack(
            index: index,
            children: [
              for (var i = 0; i < 4; i++)
                TickerMode(
                  enabled: index == i,
                  child: ExcludeFocus(
                    excluding: index != i,
                    child: PrimaryScrollController.none(
                      child: pages[i] ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: AppBottomNavigation(
            index: index,
            onSelect: select,
          ),
        ),
      ),
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.index,
    required this.onSelect,
    super.key,
  });
  final int index;
  final ValueChanged<int> onSelect;
  static const destinations = [
    ('Trang chủ', Icons.home_outlined, Icons.home_rounded),
    ('Kiến thức', Icons.menu_book_outlined, Icons.menu_book_rounded),
    ('Hỏi đáp', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
    ('Cơ sở y tế', Icons.local_hospital_outlined, Icons.local_hospital_rounded),
  ];
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.primaryDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      top: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, item) in destinations.indexed)
            Expanded(
              child: Semantics(
                selected: index == i,
                button: true,
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 76),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: index == i ? AppColors.primaryRaised : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          index == i ? item.$3 : item.$2,
                          color: index == i
                              ? AppColors.onPrimary
                              : AppColors.onPrimaryMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: index == i
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: index == i
                                ? AppColors.onPrimary
                                : AppColors.onPrimaryMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
