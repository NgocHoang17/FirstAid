import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/features/first_aid/presentation/quick_aid_pages.dart';

void main() {
  test('Vietnamese search ignores accents', () {
    expect(searchKey('BỎNG'), 'bong');
    expect(searchKey('Điện giật'), 'dien giat');
  });
  testWidgets('Quick journey supports search, audience, steps and source', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Cần sơ cứu ngay?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bong');
    await tester.pumpAndSettle();
    await tester.tap(find.text('11   Bỏng'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Người lớn'));
    await tester.tap(find.text('Người lớn'));
    await tester.pumpAndSettle();
    expect(find.text('BƯỚC 1 / 3'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Bước tiếp theo'), 300);
    await tester.tap(find.text('Bước tiếp theo'));
    await tester.pumpAndSettle();
    expect(find.text('BƯỚC 2 / 3'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Nguồn tham chiếu  ↗'), 300);
    await tester.tap(find.text('Nguồn tham chiếu  ↗'));
    await tester.pumpAndSettle();
    expect(find.text('Tài liệu tham chiếu minh họa'), findsOneWidget);
    await tester.tap(find.text('Về bài hướng dẫn'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('BƯỚC 2 / 3'), -300);
    expect(find.text('BƯỚC 2 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Unavailable audience does not fall back to adult article', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AudiencePage(category: 'Bỏng')),
    );
    await tester.tap(find.text('Trẻ em'));
    await tester.pumpAndSettle();
    expect(find.text('Không tự thay bằng hướng dẫn người lớn'), findsOneWidget);
    expect(find.text('BƯỚC 1 / 3'), findsNothing);
  });
}
