import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/first_aid/data/reference_content_repository.dart';
import 'package:mobile/features/first_aid/presentation/step_gallery.dart';

void main() {
  test(
    'Malformed or external gallery images cannot enter the saved library',
    () {
      for (final invalid in [
        'external',
        'duplicate',
        'layout',
        'description',
      ]) {
        final data =
            jsonDecode(
                  File(
                    'assets/content/reference_library.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final step = data['articles'][0]['steps'][0];
        final image = {
          'media_id': '00000000-0000-4000-8000-000000000999',
          'url': '/api/v1/media/00000000-0000-4000-8000-000000000999',
          'alt_text': 'Ảnh kiểm thử',
          'caption': '',
        };
        step['images'] = [image];
        if (invalid == 'external') {
          image['url'] = 'https://example.com/image.png';
        }
        if (invalid == 'duplicate') step['images'] = [image, image];
        if (invalid == 'layout') step['image_layout'] = 'unknown';
        if (invalid == 'description') image['alt_text'] = '';
        expect(
          () => ReferenceLibrary.parse(jsonEncode(data)),
          throwsFormatException,
          reason: invalid,
        );
      }
    },
  );
  for (final layout in ['stacked', 'grid', 'carousel']) {
    testWidgets(
      'Gallery $layout retains captions and fits narrow screens with failed images',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final step = ReferenceStep({
          'id': 'step',
          'image_layout': layout,
          'images': [
            {
              'media_id': 'one',
              'url': '',
              'alt_text': 'Hình một',
              'caption': 'Chú thích một',
            },
            {
              'media_id': 'two',
              'url': '',
              'alt_text': 'Hình hai',
              'caption': 'Chú thích hai',
            },
          ],
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(child: StepGallery(step: step)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Chú thích một'), findsOneWidget);
        if (layout == 'carousel') {
          await tester.drag(find.byType(PageView), const Offset(-300, 0));
          await tester.pumpAndSettle();
          expect(find.text('Chú thích hai'), findsOneWidget);
          expect(find.text('Ảnh 2/2 · Vuốt để xem'), findsOneWidget);
        } else {
          expect(find.text('Chú thích hai'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
