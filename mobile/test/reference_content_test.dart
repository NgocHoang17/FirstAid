import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/first_aid/data/reference_content_repository.dart';

void main() {
  String fixture() =>
      File('assets/content/reference_library.json').readAsStringSync();
  test(
    'All 18 categories have sourced, audience-appropriate editorial articles',
    () {
      final lib = ReferenceLibrary.parse(fixture(), includeDrafts: true);
      expect(lib.categories.length, 18);
      expect(lib.articles.length, 24);
      expect(lib.sources.length, 14);
      for (var i = 1; i <= 18; i++) {
        final code = 'FA${i.toString().padLeft(2, '0')}';
        expect(lib.forCategory(code), isNotEmpty, reason: code);
      }
      for (final category in lib.categories.keys) {
        final ages = lib.forCategory(category).map((a) => a.ageGroup).toSet();
        expect(
          ages,
          ['FA02', 'FA03', 'FA04'].contains(category)
              ? {'ADULT', 'CHILD'}
              : {'ALL'},
          reason: category,
        );
      }
      expect(lib.forCategory('FA09').length, 2);
      expect(lib.forCategory('FA18').length, 3);
      expect(lib.articles.every((a) => !a.isPublic), true);
      for (final article in lib.articles) {
        expect(article.steps.length, greaterThanOrEqualTo(3));
        expect(article.references, isNotEmpty);
        for (final r in article.references) {
          final source = lib.sources[r.sourceId]!;
          if (source.isPdf) {
            expect(r.firstPage, greaterThan(0));
            expect(r.lastPage, lessThanOrEqualTo(source.pageCount!));
          } else {
            expect(r.firstPage, isNull);
            expect(r.lastPage, isNull);
            expect(source.json['original_url'], startsWith('https://'));
          }
        }
      }
    },
  );
  test('Coverage distinguishes missing guides from passing mentions', () {
    final lib = ReferenceLibrary.parse(fixture(), includeDrafts: true);
    final heat = lib.categories['FA13']!.json['pdf_evidence'] as Map;
    final seizure = lib.categories['FA15']!.json['pdf_evidence'] as Map;
    for (final code in ['PNT2024', 'NHI2022']) {
      expect(heat[code]['status'], 'NOT_FOUND');
      expect(seizure[code]['status'], 'MENTION_ONLY');
    }
    for (final code in ['FA13', 'FA15']) {
      expect(
        lib
            .forCategory(code)
            .single
            .references
            .every((r) => !lib.sources[r.sourceId]!.isPdf),
        true,
      );
    }
    expect(
      lib.forCategory('FA03').firstWhere((a) => a.ageGroup == 'CHILD').scope,
      contains('trên 5 tuổi'),
    );
  });
  test('Release/public reads never publish editorial drafts', () {
    expect(ReferenceLibrary.parse(fixture()).articles, isEmpty);
  });
  test(
    'Broken evidence, identity, audience, source types and category links are rejected',
    () {
      for (final kind in [
        'source',
        'page',
        'variant',
        'step',
        'age',
        'web_page',
        'category',
        'links',
      ]) {
        final data = jsonDecode(fixture()) as Map<String, dynamic>;
        switch (kind) {
          case 'source':
            data['articles'][0]['references'][0]['source_id'] = 'missing';
          case 'page':
            data['articles'][0]['references'][0]['page_end'] = 999;
          case 'variant':
            data['articles'].add(data['articles'][0]);
          case 'step':
            data['articles'][0]['steps'][0]['position'] = 2;
          case 'age':
            data['articles'][0]['age_group'] = 'INFANT';
          case 'web_page':
            final ref = (data['articles'] as List).firstWhere(
              (a) => a['category_code'] == 'FA13',
            )['references'][0];
            ref['page_start'] = 1;
            ref['page_end'] = 1;
          case 'category':
            data['categories'].removeLast();
          case 'links':
            data['categories'][0]['article_ids'].add('missing');
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
