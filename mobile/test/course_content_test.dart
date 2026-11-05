import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/features/first_aid/data/reference_content_repository.dart';
import 'package:mobile/features/first_aid/presentation/step_illustration.dart';
import 'package:mobile/features/home/presentation/mobile_shell.dart';
import 'support/mobile_fakes.dart';

void main() {
  setUp(() => rootBundle.clear());
  test(
    'Release selection includes every supported category and excludes unchecked content',
    () {
      final text = File(
        'assets/content/reference_library.json',
      ).readAsStringSync();
      final release = ReferenceLibrary.parse(text, includeDrafts: false);
      expect(release.articles.length, 24);
      for (final category in release.categories.keys) {
        expect(release.forCategory(category), isNotEmpty, reason: category);
      }
      final raw = jsonDecode(text) as Map<String, dynamic>;
      raw['articles'][0]['content_checked'] = false;
      expect(ReferenceLibrary.parse(jsonEncode(raw)).articles.length, 23);
    },
  );
  test(
    'Every step has a shipped original diagram with a text alternative and review evidence',
    () {
      final raw =
          jsonDecode(
                File(
                  'assets/content/reference_library.json',
                ).readAsStringSync(),
              )
              as Map;
      final review =
          jsonDecode(
                File('assets/content/editorial_review.json').readAsStringSync(),
              )
              as Map;
      expect(review['clinical_expert_review'], false);
      expect((review['articles'] as List).length, 24);
      for (final article in raw['articles']) {
        for (final step in article['steps']) {
          final file = File(step['asset_key'] as String);
          expect(file.existsSync(), true, reason: article['variant_key']);
          final diagram = jsonDecode(file.readAsStringSync()) as Map;
          expect(ReminderPainter.kinds, contains(diagram['kind']));
          expect(diagram['caption'], step['alt_text']);
          expect(diagram['clinical_pose'], false);
        }
      }
      final library = ReferenceLibrary.parse(jsonEncode(raw));
      final child = library
          .forCategory('FA03')
          .singleWhere((a) => a.ageGroup == 'CHILD');
      expect(child.scope, contains('từ 1 đến dưới 18 tuổi'));
      expect(child.scope, isNot(contains('trên 5 tuổi')));
      final teenCpr = library
          .forCategory('FA02')
          .singleWhere((a) => a.ageGroup == 'CHILD');
      expect(teenCpr.steps[2].instruction, contains('13–17 tuổi'));
      expect(teenCpr.steps[2].instruction, contains('5–6 cm'));
    },
  );
  testWidgets(
    'Fresh install can search, read and render bundled guidance with no network or downloaded data',
    (tester) async {
      final api = FakeApi();
      (api.network as FakeNetwork).online = false;
      final store = MemoryStore();
      await tester.pumpWidget(MyApp(api: api, store: store));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNavigation),
          matching: find.text('Kiến thức'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'hoc di vat');
      await tester.pumpAndSettle();
      final childTitle = find.text('Hóc dị vật ở trẻ từ 1 tuổi');
      await tester.scrollUntilVisible(
        childTitle,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(childTitle);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byWidgetPredicate(
          (widget) =>
              widget is StepIllustration &&
              widget.step.title == 'Khi ho hiệu quả',
        ),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(StepIllustration), findsWidgets);
      expect(find.text('Bản tham khảo đang rà soát'), findsNothing);
      expect(api.requests, isEmpty);
      expect(store.snapshot, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
