import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ReferenceSource {
  ReferenceSource(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'] as String;
  String get title => json['title'] as String;
  String get publisher => json['publisher'] as String;
  int get year => json['publication_year'] as int;
  int get pageCount => json['page_count'] as int;
}

class ArticleReference {
  ArticleReference(this.json);
  final Map<String, dynamic> json;
  String get sourceId => json['source_id'] as String;
  int get firstPage => json['page_start'] as int;
  int get lastPage => json['page_end'] as int;
  String get note => json['note'] as String;
}

class ReferenceStep {
  ReferenceStep(this.json);
  final Map<String, dynamic> json;
  int get position => json['position'] as int;
  String get title => json['title'] as String;
  String get instruction => json['instruction'] as String;
}

class ReferenceArticle {
  ReferenceArticle(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'] as String;
  String get categoryCode => json['category_code'] as String;
  String get variantKey => json['variant_key'] as String;
  String get title => json['title'] as String;
  String get ageGroup => json['age_group'] as String;
  String get scope => json['applies_to'] as String;
  String get summary => json['summary'] as String;
  bool get isPublic =>
      json['status'] == 'PUBLISHED' &&
      json['content_checked'] == true &&
      json['checked_at'] != null;
  String get ageLabel => switch (ageGroup) {
    'ADULT' => 'Người lớn',
    'CHILD' => 'Trẻ em',
    _ => 'Dùng chung',
  };
  List<String> texts(String field) => List<String>.from(json[field] as List);
  List<ReferenceStep> get steps => (json['steps'] as List)
      .map((s) => ReferenceStep(Map<String, dynamic>.from(s as Map)))
      .toList(growable: false);
  List<ArticleReference> get references => (json['references'] as List)
      .map((r) => ArticleReference(Map<String, dynamic>.from(r as Map)))
      .toList(growable: false);
}

class ReferenceLibrary {
  ReferenceLibrary._(this.articles, this.sources, this.reviewNotice);
  final List<ReferenceArticle> articles;
  final Map<String, ReferenceSource> sources;
  final String reviewNotice;
  List<ReferenceArticle> forCategory(String code) =>
      articles.where((a) => a.categoryCode == code).toList(growable: false);

  factory ReferenceLibrary.parse(String text, {bool includeDrafts = false}) {
    final data = jsonDecode(text) as Map<String, dynamic>;
    if (data['schema_version'] != 1 || data['kind'] != 'editorial_preview') {
      throw const FormatException('Unsupported content schema');
    }
    final sources = <String, ReferenceSource>{};
    for (final row in data['sources'] as List) {
      final source = ReferenceSource(Map<String, dynamic>.from(row as Map));
      if (sources.containsKey(source.id) ||
          source.pageCount < 1 ||
          source.title.trim().isEmpty) {
        throw const FormatException('Invalid source');
      }
      sources[source.id] = source;
    }
    final articles = <ReferenceArticle>[];
    final ids = <String>{}, variants = <String>{};
    for (final row in data['articles'] as List) {
      final article = ReferenceArticle(Map<String, dynamic>.from(row as Map));
      if (!ids.add(article.id) ||
          !variants.add('${article.categoryCode}:${article.variantKey}') ||
          !RegExp(r'^FA(0[1-9]|1[0-8])$').hasMatch(article.categoryCode) ||
          !{'ADULT', 'CHILD', 'ALL'}.contains(article.ageGroup) ||
          !{'DRAFT', 'PUBLISHED'}.contains(article.json['status'])) {
        throw const FormatException('Invalid article identity');
      }
      for (final field in ['title', 'applies_to', 'summary']) {
        if ((article.json[field] as String).trim().isEmpty) {
          throw const FormatException('Missing article text');
        }
      }
      for (final field in [
        'recognition',
        'quick_actions',
        'warnings',
        'seek_help',
      ]) {
        if (article.texts(field).isEmpty ||
            article.texts(field).any((text) => text.trim().isEmpty)) {
          throw const FormatException('Missing article section');
        }
      }
      final steps = article.steps;
      if (steps.isEmpty) throw const FormatException('Missing steps');
      for (final (index, step) in steps.indexed) {
        if (step.position != index + 1 ||
            step.title.trim().isEmpty ||
            step.instruction.trim().isEmpty) {
          throw const FormatException('Invalid steps');
        }
      }
      if (article.references.isEmpty) {
        throw const FormatException('Missing evidence');
      }
      for (final reference in article.references) {
        final source = sources[reference.sourceId];
        if (source == null ||
            reference.firstPage < 1 ||
            reference.lastPage < reference.firstPage ||
            reference.lastPage > source.pageCount) {
          throw const FormatException('Invalid evidence pages');
        }
      }
      if (article.isPublic ||
          (includeDrafts && article.json['status'] == 'DRAFT')) {
        articles.add(article);
      }
    }
    return ReferenceLibrary._(
      List.unmodifiable(articles),
      Map.unmodifiable(sources),
      data['review_notice'] as String,
    );
  }
}

class ReferenceContentRepository {
  // Drafts stay local to debug builds. Public/release builds never silently publish them.
  static Future<ReferenceLibrary> load() async => ReferenceLibrary.parse(
    await rootBundle.loadString('assets/content/reference_library.json'),
    includeDrafts: kDebugMode,
  );
}
