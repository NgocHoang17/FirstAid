import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/assistant/data/assistant_cubit.dart';
import 'package:mobile/features/assistant/presentation/assistant_page.dart';
import 'package:mobile/features/facilities/data/facility.dart';
import 'package:mobile/features/facilities/presentation/facilities_page.dart';
import 'package:mobile/features/first_aid/presentation/reference_article_view.dart';
import 'package:mobile/features/home/presentation/mobile_shell.dart';
import 'package:mobile/features/settings/data/content_update_cubit.dart';
import 'support/mobile_fakes.dart';

void main() {
  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNavigation),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  void narrow(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  testWidgets(
    'Knowledge searches and opens learn mode; navigation preserves the search',
    (tester) async {
      final store = MemoryStore()..snapshot = jsonEncode(testSnapshot());
      await tester.pumpWidget(MyApp(api: FakeApi(), store: store));
      await tester.pumpAndSettle();
      await tab(tester, 'Kiến thức');
      await tester.enterText(find.byType(TextField), 'cho can');
      await tester.pumpAndSettle();
      expect(find.text('Chó cắn'), findsOneWidget);
      await tab(tester, 'Hỏi đáp');
      await tab(tester, 'Kiến thức');
      expect(find.text('cho can'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Chó cắn'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Chó cắn'));
      await tester.pumpAndSettle();
      expect(find.byType(ReferenceArticleView), findsOneWidget);
      expect(find.text('Bài kiến thức'), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Đọc đầy đủ'),
      );
      expect(chip.selected, true);
      await tester.tap(find.text('Mở hướng dẫn nhanh'));
      await tester.pumpAndSettle();
      expect(find.text('Gọi trợ giúp'), findsOneWidget);
    },
  );
  testWidgets(
    'All tabs and settings fit 320px at 200% text; failed update keeps local knowledge',
    (tester) async {
      narrow(tester);
      final store = MemoryStore()..snapshot = jsonEncode(testSnapshot());
      await tester.pumpWidget(MyApp(api: FakeApi(), store: store));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final label in ['Kiến thức', 'Hỏi đáp', 'Cơ sở y tế']) {
        await tab(tester, label);
        expect(tester.takeException(), isNull, reason: label);
      }
      await tester.tap(find.byTooltip('Cài đặt và dữ liệu'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Kiểm tra cập nhật'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Kiểm tra cập nhật'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Cập nhật chưa thành công'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Cập nhật chưa thành công'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(jsonDecode(store.snapshot!)['data_version'], 'test-v1');
    },
  );
  for (final status in ChatStatus.values) {
    testWidgets(
      'Chat ${status.name} is readable at large text and only emergency displays a call',
      (tester) async {
        narrow(tester);
        final store = MemoryStore()..snapshot = jsonEncode(testSnapshot());
        final cubit = ContentUpdateCubit(api: FakeApi(), store: store);
        await cubit.load();
        addTearDown(cubit.close);
        final reply = ChatReply(
          status: status,
          blocks: status == ChatStatus.answered
              ? ['Thông tin dùng cho kiểm thử giao diện.']
              : [],
          question: 'Bạn muốn tìm hiểu tình huống nào?',
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: BlocProvider.value(
              value: cubit,
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ChatReplyView(
                    turn: ChatTurn('Câu hỏi kiểm thử', null, reply: reply),
                    api: FakeApi(),
                    onKnowledge: () {},
                    onRetry: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Gọi trợ giúp'),
          status == ChatStatus.emergencyRedirect
              ? findsOneWidget
              : findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Failed facility dialer and map show usable phone and address fallbacks',
    (tester) async {
      narrow(tester);
      final actions = FailedActions();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: FacilityDetailPage(
            facility: Facility.parseList([testFacility()]).single,
            actions: actions,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Gọi cơ sở'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Gọi cơ sở'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Không mở được ứng dụng gọi.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Mở bản đồ'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Mở bản đồ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Không mở được bản đồ.'), findsOneWidget);
      expect(actions.opened.last.host, 'www.google.com');
      expect(tester.takeException(), isNull);
    },
  );
}
