import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/first_aid/data/reference_content_repository.dart';
import 'package:mobile/features/first_aid/presentation/reference_article_view.dart';
import 'package:mobile/features/first_aid/presentation/step_illustration.dart';

void main() {
  setUp(() => rootBundle.clear());

  testWidgets(
    'Full reading keeps each illustration below its own heading and instructions',
    (tester) async {
      tester.view.physicalSize = const Size(430, 8000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final library = ReferenceLibrary.parse(
        File('assets/content/reference_library.json').readAsStringSync(),
      );
      final child = library
          .forCategory('FA02')
          .singleWhere((a) => a.ageGroup == 'CHILD');
      await tester.pumpWidget(
        MaterialApp(
          home: ReferenceArticleView(
            article: child,
            library: library,
            initialLearn: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final compressionHeading = find.text('Bước 3. ${child.steps[2].title}');
      final compressionText = find.text(child.steps[2].instruction);
      final compressionDiagram = find.byWidgetPredicate(
        (w) =>
            w is StepIllustration &&
            w.step.assetKey == 'assets/illustrations/cpr_child.json',
      );
      final continuationHeading = find.text('Bước 4. ${child.steps[3].title}');
      final aedDiagram = find.byWidgetPredicate(
        (w) =>
            w is StepIllustration &&
            w.step.assetKey == 'assets/illustrations/aed.json',
      );
      expect(
        tester.getBottomLeft(compressionHeading).dy,
        lessThan(tester.getTopLeft(compressionText).dy),
      );
      expect(
        tester.getBottomLeft(compressionText).dy,
        lessThan(tester.getTopLeft(compressionDiagram).dy),
      );
      expect(
        tester.getBottomLeft(compressionDiagram).dy,
        lessThan(tester.getTopLeft(continuationHeading).dy),
      );
      expect(
        tester.getBottomLeft(continuationHeading).dy,
        lessThan(tester.getTopLeft(aedDiagram).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Changing or removing an illustration does not retain the preceding image',
    (tester) async {
      ReferenceStep step(String? asset) =>
          ReferenceStep({'asset_key': asset, 'alt_text': null});
      Future<void> show(String? asset) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StepIllustration(step: step(asset))),
          ),
        );
      }

      await show('assets/illustrations/aed.json');
      await tester.pumpAndSettle();
      expect(find.text('AED'), findsOneWidget);
      await show('assets/illustrations/cpr_child.json');
      expect(find.text('AED'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('100–120 lần/phút'), findsOneWidget);
      await show(null);
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is ReminderPainter,
        ),
        findsNothing,
      );
      expect(find.text('100–120 lần/phút'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
