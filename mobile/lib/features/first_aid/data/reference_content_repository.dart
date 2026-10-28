import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ReferenceSource {
  ReferenceSource(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'] as String;
  String get title => json['title'] as String;
  String get publisher => json['publisher'] as String;
  int? get year => json['publication_year'] as int?;
  int? get pageCount => json['page_count'] as int?;
  bool get isPdf => json['media_type'] == 'PDF';
}

class ArticleReference {
  ArticleReference(this.json);
  final Map<String, dynamic> json;
  String get sourceId => json['source_id'] as String;
  int? get firstPage => json['page_start'] as int?;
  int? get lastPage => json['page_end'] as int?;
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
    _ => 'Người lớn và trẻ em',
  };
  List<String> texts(String field) => List<String>.from(json[field] as List);
  List<ReferenceStep> get steps => (json['steps'] as List)
      .map((s) => ReferenceStep(Map<String, dynamic>.from(s as Map)))
      .toList(growable: false);
  List<ArticleReference> get references => (json['references'] as List)
      .map((r) => ArticleReference(Map<String, dynamic>.from(r as Map)))
      .toList(growable: false);
}

class ReferenceCategory {
  ReferenceCategory(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'] as String;
  String get code => json['code'] as String;
  String get name => json['name'] as String;
}

class ReferenceLibrary {
  ReferenceLibrary._(
    this.articles,
    this.sources,
    this.categories,
    this.reviewNotice,
  );
  final List<ReferenceArticle> articles;
  final Map<String, ReferenceSource> sources;
  final Map<String, ReferenceCategory> categories;
  final String reviewNotice;
  List<ReferenceArticle> forCategory(String code) =>
      articles.where((a) => a.categoryCode == code).toList(growable: false);

  factory ReferenceLibrary.parse(String text, {bool includeDrafts = false}) {
    final data = jsonDecode(text) as Map<String, dynamic>;
    if (data['schema_version'] != 2 || data['kind'] != 'editorial_preview') {
      throw const FormatException('Unsupported content schema');
    }
    final sources = <String, ReferenceSource>{};
    for (final row in data['sources'] as List) {
      final source = ReferenceSource(Map<String, dynamic>.from(row as Map));
      if (sources.containsKey(source.id) ||
          source.title.trim().isEmpty ||
          source.publisher.trim().isEmpty ||
          source.json['is_active'] != true ||
          !{'PDF', 'WEB'}.contains(source.json['media_type'])) {
        throw const FormatException('Invalid source');
      }
      if (source.isPdf) {
        if (source.pageCount == null || source.pageCount! < 1) {
          throw const FormatException('Invalid PDF source');
        }
      } else {
        final url = Uri.tryParse(source.json['original_url'] as String? ?? '');
        if (source.pageCount != null ||
            url == null ||
            url.scheme != 'https' ||
            url.host.isEmpty) {
          throw const FormatException('Invalid web source');
        }
      }
      sources[source.id] = source;
    }
    final categories = <String, ReferenceCategory>{};
    final categoryIds = <String>{};
    for (final row in data['categories'] as List) {
      final category = ReferenceCategory(Map<String, dynamic>.from(row as Map));
      if (!RegExp(r'^FA(0[1-9]|1[0-8])$').hasMatch(category.code) ||
          categories.containsKey(category.code) ||
          !categoryIds.add(category.id) ||
          category.name.trim().isEmpty) {
        throw const FormatException('Invalid category');
      }
      categories[category.code] = category;
    }
    if (categories.length != 18) {
      throw const FormatException('Expected 18 categories');
    }
    final articles = <ReferenceArticle>[];
    final allArticles = <ReferenceArticle>[];
    final ids = <String>{}, variants = <String>{}, stepIds = <String>{};
    for (final row in data['articles'] as List) {
      final article = ReferenceArticle(Map<String, dynamic>.from(row as Map));
      if (!ids.add(article.id) ||
          !variants.add('${article.categoryCode}:${article.variantKey}') ||
          categories[article.categoryCode]?.id != article.json['category_id'] ||
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
      if (article.steps.isEmpty) throw const FormatException('Missing steps');
      for (final (index, step) in article.steps.indexed) {
        if (step.position != index + 1 ||
            step.title.trim().isEmpty ||
            step.instruction.trim().isEmpty ||
            !stepIds.add(step.json['id'] as String)) {
          throw const FormatException('Invalid steps');
        }
      }
      if (article.references.isEmpty) {
        throw const FormatException('Missing evidence');
      }
      for (final reference in article.references) {
        final source = sources[reference.sourceId];
        if (source == null) throw const FormatException('Unknown evidence');
        if (source.isPdf) {
          if (reference.firstPage == null ||
              reference.lastPage == null ||
              reference.firstPage! < 1 ||
              reference.lastPage! < reference.firstPage! ||
              reference.lastPage! > source.pageCount!) {
            throw const FormatException('Invalid evidence pages');
          }
        } else if (reference.firstPage != null || reference.lastPage != null) {
          throw const FormatException('Web evidence cannot invent PDF pages');
        }
      }
      allArticles.add(article);
      if (article.isPublic ||
          (includeDrafts && article.json['status'] == 'DRAFT')) {
        articles.add(article);
      }
    }
    for (final category in categories.values) {
      final declared = List<String>.from(category.json['article_ids'] as List);
      final actual = allArticles
          .where((a) => a.categoryCode == category.code)
          .map((a) => a.id)
          .toSet();
      if (declared.length != declared.toSet().length ||
          declared.toSet().difference(actual).isNotEmpty ||
          actual.difference(declared.toSet()).isNotEmpty ||
          actual.isEmpty) {
        throw const FormatException('Invalid category article links');
      }
    }
    return ReferenceLibrary._(
      List.unmodifiable(articles),
      Map.unmodifiable(sources),
      Map.unmodifiable(categories),
      data['review_notice'] as String,
    );
  }
}

class ReferenceContentRepository {
  // Editorial drafts are visible in debug builds only until human content review.
  static Future<ReferenceLibrary> load() async {
    final bytes = await rootBundle.load(
      'assets/content/reference_library.json',
    );
    final text = utf8.decode(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    return ReferenceLibrary.parse(text, includeDrafts: kDebugMode);
  }
}
