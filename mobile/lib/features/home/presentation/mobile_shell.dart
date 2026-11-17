import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/app_services.dart';
import '../../../core/storage/snapshot_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../first_aid/presentation/quick_aid_pages.dart';
import '../../first_aid/data/reference_content_repository.dart';
import '../../knowledge/presentation/knowledge_page.dart';
import '../../assistant/presentation/assistant_page.dart';
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
      _ => throw RangeError.index(value, [0, 1, 2]),
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
              for (var i = 0; i < 3; i++)
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
  ];
  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;
    return Material(
      color: AppColors.primaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => Wrap(
            children: [
              for (final (i, item) in destinations.indexed)
                SizedBox(
                  width: constraints.maxWidth / (largeText ? 2 : 3),
                  child: _NavigationItem(
                    label: item.$1,
                    icon: index == i ? item.$3 : item.$2,
                    selected: index == i,
                    largeText: largeText,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.largeText,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected, largeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final symbol = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 22,
        color: selected ? AppColors.primaryDark : AppColors.onPrimaryMuted,
      ),
    );
    final text = Text(
      label,
      textAlign: largeText ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? AppColors.onPrimary : AppColors.onPrimaryMuted,
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryRaised.withValues(alpha: .6)
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: largeText
              ? Row(
                  children: [
                    symbol,
                    const SizedBox(width: 8),
                    Expanded(child: text),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [symbol, const SizedBox(height: 4), text],
                ),
        ),
      ),
    );
  }
}
