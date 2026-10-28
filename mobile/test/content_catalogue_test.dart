import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/first_aid/data/reference_content_repository.dart';
import 'package:mobile/features/first_aid/presentation/reference_article_view.dart';

void main() {
  setUp(() => rootBundle.clear());
  testWidgets('Supplemental category opens sourced article, not a demo flow', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Cần sơ cứu ngay?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'soc nhiet');
    await tester.pumpAndSettle();
    await tester.tap(find.text('13   Say nóng / sốc nhiệt'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Say nóng và nghi sốc nhiệt'),
      200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Say nóng và nghi sốc nhiệt'));
    await tester.pumpAndSettle();
    expect(find.byType(ReferenceArticleView), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Nguồn tham chiếu  ↗'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nguồn tham chiếu  ↗'));
    await tester.pumpAndSettle();
    expect(find.text('Heat exhaustion and heatstroke'), findsOneWidget);
    expect(find.textContaining('Biên soạn: NHS'), findsOneWidget);
    expect(find.textContaining('Năm xuất bản: Không nêu'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);
    expect(find.textContaining('Trang PDF:'), findsNothing);
  });
  testWidgets('Every article reads in quick and learn modes without overflow', (
    tester,
  ) async {
    final lib = ReferenceLibrary.parse(
      File('assets/content/reference_library.json').readAsStringSync(),
      includeDrafts: true,
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final a in lib.articles) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ReferenceArticleView(article: a, library: lib),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Đọc đầy đủ'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đọc đầy đủ'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Nguồn tham chiếu  ↗'), 350);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: a.variantKey);
    }
  });
}
