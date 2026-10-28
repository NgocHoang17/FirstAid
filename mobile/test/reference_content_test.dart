import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/first_aid/data/reference_content_repository.dart';

void main() {
  String fixture() =>
      File('assets/content/reference_library.json').readAsStringSync();
  test(
    'Four editorial articles have valid offline source pages and distinct audiences',
    () {
      final lib = ReferenceLibrary.parse(fixture(), includeDrafts: true);
      expect(lib.articles.length, 4);
      expect(lib.sources.length, 2);
      expect(lib.forCategory('FA05').map((a) => a.ageGroup).toSet(), {
        'ADULT',
        'CHILD',
      });
      expect(lib.forCategory('FA11').single.ageGroup, 'CHILD');
      expect(lib.forCategory('FA01'), isEmpty);
      expect(lib.articles.every((a) => !a.isPublic), true);
      for (final a in lib.articles) {
        expect(a.steps.length, greaterThanOrEqualTo(3));
        expect(a.references, isNotEmpty);
        for (final r in a.references) {
          expect(
            r.lastPage,
            lessThanOrEqualTo(lib.sources[r.sourceId]!.pageCount),
          );
        }
      }
    },
  );
  test('Release/public reads do not publish editorial drafts', () {
    expect(ReferenceLibrary.parse(fixture()).articles, isEmpty);
  });
  test(
    'Unknown source, invalid pages, duplicate variants and broken steps are rejected',
    () {
      for (final kind in ['source', 'page', 'variant', 'step', 'age']) {
        final data = jsonDecode(fixture()) as Map<String, dynamic>;
        switch (kind) {
          case 'age':
            data['articles'][0]['age_group'] = 'INFANT';
          case 'source':
            data['articles'][0]['references'][0]['source_id'] = 'missing';
          case 'page':
            data['articles'][0]['references'][0]['page_end'] = 999;
          case 'variant':
            data['articles'].add(data['articles'][0]);
          case 'step':
            data['articles'][0]['steps'][0]['position'] = 2;
        }
        expect(
          () => ReferenceLibrary.parse(jsonEncode(data), includeDrafts: true),
          throwsFormatException,
          reason: kind,
        );
      }
    },
  );
}
