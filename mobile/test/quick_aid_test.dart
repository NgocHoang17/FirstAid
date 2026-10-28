import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app.dart';
import 'package:mobile/features/first_aid/presentation/quick_aid_pages.dart';

void main() {
  setUp(() => rootBundle.clear());
  test('Vietnamese search ignores accents', () {
    expect(searchKey('BỎNG'), 'bong');
    expect(searchKey('Điện giật'), 'dien giat');
  });
  testWidgets(
    'Quick journey reads sourced shared article and preserves step after source',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.tap(find.text('Cần sơ cứu ngay?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'bong');
      await tester.pumpAndSettle();
      await tester.tap(find.text('11   Bỏng'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Bỏng nhiệt nhẹ'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏng nhiệt nhẹ'));
      await tester.pumpAndSettle();
      expect(find.text('Bản tham khảo đang rà soát'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('BƯỚC 1 / 4'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.text('Bước tiếp theo'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Bước tiếp theo'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('BƯỚC 2 / 4'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Làm mát 20 phút'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Nguồn tham chiếu  ↗'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Nguồn tham chiếu  ↗'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Hướng dẫn sơ cấp cứu ban đầu tai nạn thương tích thường gặp ở trẻ em, học sinh',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Năm xuất bản: 2022'), findsOneWidget);
      expect(
        find.textContaining('Biên soạn: Bệnh viện Nhi Trung ương'),
        findsOneWidget,
      );
      expect(find.textContaining('Trang PDF:'), findsNothing);
      expect(find.textContaining('Số trang là thứ tự trang'), findsNothing);
      expect(find.textContaining('Phần II Bỏng'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Về bài hướng dẫn'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Về bài hướng dẫn'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('BƯỚC 2 / 4'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('BƯỚC 2 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Shared dog bite care covers both audiences without an unsupported choice',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AudiencePage(category: 'Động vật cắn / côn trùng đốt'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chó cắn'), findsOneWidget);
      expect(find.textContaining('Người lớn và trẻ em'), findsWidgets);
      expect(find.textContaining('chưa có bài phù hợp'), findsNothing);
      expect(find.text('Luồng lựa chọn minh họa'), findsNothing);
      await tester.tap(find.text('Chó cắn'));
      await tester.pumpAndSettle();
      expect(find.text('Chó cắn'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Age-specific care has direct article choices and no demo flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AudiencePage(category: 'Ngừng tim • CPR / AED')),
    );
    await tester.pumpAndSettle();
    expect(find.text('CPR và AED ở người lớn'), findsOneWidget);
    expect(find.text('CPR trẻ em cho người sơ cứu'), findsOneWidget);
    expect(find.text('Luồng lựa chọn minh họa'), findsNothing);
  });
}
