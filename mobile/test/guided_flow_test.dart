import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/features/first_aid/domain/guided_flow.dart';
import 'package:mobile/features/first_aid/presentation/guided_flow_page.dart';

void main() {
  String fixture(String code) =>
      File('assets/flows/${code}_demo.json').readAsStringSync();
  test('All bundled flow branches and back/restart are valid', () {
    for (final code in ['fa01', 'fa02', 'fa03']) {
      final flow = GuidedFlow.parse(fixture(code));
      final controller = GuidedFlowController(flow);
      controller.choose('unknown');
      expect(controller.current.type, GuidedNodeType.unsupported);
      controller.back();
      controller.choose('child');
      expect(controller.current.type, GuidedNodeType.unsupported);
      controller.restart();
      controller.choose('adult');
      controller.choose('option_a');
      expect(controller.current.type, GuidedNodeType.openArticle);
      expect(controller.current.ageGroup, 'ADULT');
      expect(controller.current.categoryCode, code.toUpperCase());
      controller.back();
      controller.choose('option_b');
      expect(controller.current.type, GuidedNodeType.unsupported);
      controller.back();
      controller.choose('unknown');
      expect(controller.current.type, GuidedNodeType.unsupported);
      controller.restart();
      expect(controller.canGoBack, false);
    }
  });
  test('Invalid config rejects dangling links, duplicate IDs and cycles', () {
    final base = jsonDecode(fixture('fa01')) as Map<String, dynamic>;
    final nodes = base['nodes'] as List<dynamic>;
    final original = jsonEncode(base);
    nodes.add(nodes.first);
    expect(() => GuidedFlow.parse(jsonEncode(base)), throwsFormatException);
    final broken = jsonDecode(original) as Map<String, dynamic>;
    broken['nodes'][0]['options'][0]['next_node'] = 'absent';
    expect(() => GuidedFlow.parse(jsonEncode(broken)), throwsFormatException);
    broken['nodes'][0]['options'][0]['next_node'] = 'audience';
    expect(() => GuidedFlow.parse(jsonEncode(broken)), throwsFormatException);
  });
  testWidgets('Journey 01 opens guided flow and preserves previous answers', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Cần sơ cứu ngay?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('01   Bất tỉnh / không đáp ứng'));
    await tester.pumpAndSettle();
    expect(find.byType(GuidedFlowPage), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Người lớn'), 150);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Người lớn'));
    await tester.pumpAndSettle();
    expect(find.text('[Câu hỏi theo kịch bản đã duyệt]'), findsOneWidget);
    await tester.tap(find.text('Lựa chọn A'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có hướng dẫn phù hợp'), findsOneWidget);
    expect(find.text('Bỏng'), findsNothing);
    await tester.ensureVisible(find.text('Câu trước'));
    await tester.tap(find.text('Câu trước'));
    await tester.pumpAndSettle();
    expect(find.text('Lựa chọn A'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Không rõ / không xác định'),
      150,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Không rõ / không xác định'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Không suy ra tình huống an toàn'),
      findsOneWidget,
    );
    expect(find.text('Gọi trợ giúp'), findsOneWidget);
  });
  testWidgets('Unknown flow offers retry and keeps call action', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GuidedFlowPage(categoryCode: 'BAD', categoryName: 'Demo'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tải được luồng lựa chọn'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Gọi trợ giúp'), findsOneWidget);
  });
}
