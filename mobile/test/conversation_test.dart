import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/assistant/data/assistant_cubit.dart';
import 'package:mobile/features/assistant/presentation/assistant_page.dart';
import 'support/mobile_fakes.dart';

Map<String, dynamic> answer(Map<String, dynamic> request) => {
  'request_id': request['client_request_id'],
  'status': 'answered',
  'answer_blocks': [
    {
      'text': 'Kiến thức kiểm thử',
      'citation_ids': ['c1'],
    },
    {
      'text': 'Lưu ý: Nội dung có nguồn dùng để kiểm giao diện.',
      'citation_ids': ['c1'],
    },
  ],
  'citations': [
    {
      'id': 'c1',
      'source_id': 'source',
      'source_revision': 1,
      'evidence_id': 'e1',
    },
  ],
};
void main() {
  testWidgets(
    'Android send clears composing text and late replies preserve a new draft',
    (tester) async {
      final api = FakeApi();
      var pending = Completer<Map<String, dynamic>>();
      api.onAsk = (_) => pending.future;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AssistantPage(api: api, onKnowledge: () {}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Tìm hiểu về bỏng');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      final controller = tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
      expect(controller.text, isEmpty);
      // Simulate a stale input-method commit while the field is unfocused.
      controller.value = const TextEditingValue(text: 'Tìm hiểu về bỏng');
      pending.complete(answer(api.requests.last));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      pending = Completer<Map<String, dynamic>>();
      await tester.enterText(find.byType(TextField), 'Cần tránh gì?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.enterText(
        find.byType(TextField),
        'Câu hỏi tiếp theo đang soạn',
      );
      pending.complete(answer(api.requests.last));
      await tester.pumpAndSettle();
      expect(controller.text, 'Câu hỏi tiếp theo đang soạn');
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'Conversation carries bounded user context, updates age and clears without persisting history',
    () async {
      final api = FakeApi()..onAsk = (request) async => answer(request);
      final cubit = AssistantCubit(api);
      addTearDown(cubit.close);
      await cubit.send('Kiến thức CPR người lớn', null);
      await cubit.send('Còn trẻ em thì sao?', null);
      expect(api.requests.last['age_group'], 'CHILD');
      expect(api.requests.last['context_messages'], [
        'Kiến thức CPR người lớn',
      ]);
      for (var i = 0; i < 6; i++) {
        await cubit.send('Cần tránh gì $i?', null);
      }
      expect((api.requests.last['context_messages'] as List).length, 4);
      cubit.clearConversation();
      expect(cubit.state.turns, isEmpty);
      await cubit.send('Tìm hiểu bỏng', null);
      expect(api.requests.last.containsKey('context_messages'), false);
      expect(api.requests.last['age_group'], isNull);
    },
  );
  testWidgets(
    'Chat composer stays available, clears sent text, supports follow-up and hides reference buttons',
    (tester) async {
      final api = FakeApi()..onAsk = (request) async => answer(request);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AssistantPage(api: api, onKnowledge: () {}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Tìm hiểu về bỏng');
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi câu hỏi'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.textContaining('Nguồn tham chiếu'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Cần tránh gì?');
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi câu hỏi'));
      await tester.pumpAndSettle();
      expect(api.requests.last['context_messages'], ['Tìm hiểu về bỏng']);
      await tester.tap(find.byTooltip('Cuộc trò chuyện mới'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn muốn tìm hiểu điều gì?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
