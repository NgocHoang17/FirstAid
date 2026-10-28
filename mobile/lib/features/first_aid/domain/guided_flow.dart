import 'dart:convert';

enum GuidedNodeType { question, openArticle, unsupported }

class GuidedOption {
  const GuidedOption(this.code, this.label, this.nextNode);
  final String code, label, nextNode;
}

class GuidedNode {
  const GuidedNode({
    required this.id,
    required this.type,
    this.prompt,
    this.options = const [],
    this.categoryCode,
    this.variantKey,
    this.ageGroup,
    this.messageCode,
  });
  final String id;
  final GuidedNodeType type;
  final String? prompt, categoryCode, variantKey, ageGroup, messageCode;
  final List<GuidedOption> options;
}

class GuidedFlow {
  GuidedFlow._(this.key, this.categoryCode, this.entry, this.nodes);
  final String key, categoryCode, entry;
  final Map<String, GuidedNode> nodes;

  factory GuidedFlow.parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    String requiredText(Map<String, dynamic> data, String key) {
      final value = data[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing $key');
      }
      return value;
    }

    final key = requiredText(json, 'flow_key');
    final category = requiredText(json, 'category_code');
    if (!{'FA01', 'FA02', 'FA03'}.contains(category)) {
      throw const FormatException('Unsupported flow');
    }
    final entry = requiredText(json, 'entry_node');
    final nodes = <String, GuidedNode>{};
    for (final raw in json['nodes'] as List<dynamic>) {
      final data = raw as Map<String, dynamic>;
      final id = requiredText(data, 'id');
      if (nodes.containsKey(id)) throw const FormatException('Duplicate node');
      final type = switch (data['type']) {
        'question' => GuidedNodeType.question,
        'open_article' => GuidedNodeType.openArticle,
        'unsupported' => GuidedNodeType.unsupported,
        _ => throw const FormatException('Invalid node type'),
      };
      final options = <GuidedOption>[];
      if (type == GuidedNodeType.question) {
        final codes = <String>{};
        for (final rawOption in data['options'] as List<dynamic>) {
          final option = rawOption as Map<String, dynamic>;
          final code = requiredText(option, 'code');
          if (!codes.add(code)) throw const FormatException('Duplicate option');
          options.add(
            GuidedOption(
              code,
              requiredText(option, 'label'),
              requiredText(option, 'next_node'),
            ),
          );
        }
        if (options.length < 2 || !codes.contains('unknown')) {
          throw const FormatException('Missing unknown choice');
        }
      }
      nodes[id] = GuidedNode(
        id: id,
        type: type,
        prompt: type == GuidedNodeType.question
            ? requiredText(data, 'prompt')
            : null,
        options: List.unmodifiable(options),
        categoryCode: type == GuidedNodeType.openArticle
            ? requiredText(data, 'category_code')
            : null,
        variantKey: type == GuidedNodeType.openArticle
            ? requiredText(data, 'variant_key')
            : null,
        ageGroup: type == GuidedNodeType.openArticle
            ? requiredText(data, 'age_group')
            : null,
        messageCode: type == GuidedNodeType.unsupported
            ? requiredText(data, 'message_code')
            : null,
      );
      if (type == GuidedNodeType.openArticle &&
          (nodes[id]!.categoryCode != category ||
              !{'ADULT', 'CHILD', 'ALL'}.contains(nodes[id]!.ageGroup))) {
        throw const FormatException('Invalid article target');
      }
    }
    if (!nodes.containsKey(entry)) throw const FormatException('Missing entry');
    final visiting = <String>{}, visited = <String>{};
    void validate(String id) {
      if (!nodes.containsKey(id)) throw const FormatException('Broken route');
      if (visiting.contains(id)) {
        throw const FormatException('Unexpected cycle');
      }
      if (visited.contains(id)) return;
      visiting.add(id);
      for (final option in nodes[id]!.options) {
        validate(option.nextNode);
      }
      visiting.remove(id);
      visited.add(id);
    }

    for (final id in nodes.keys) {
      validate(id);
    }
    return GuidedFlow._(key, category, entry, Map.unmodifiable(nodes));
  }
}

class GuidedFlowController {
  GuidedFlowController(this.flow) : _current = flow.entry;
  final GuidedFlow flow;
  String _current;
  final List<String> _history = [];
  GuidedNode get current => flow.nodes[_current]!;
  bool get canGoBack => _history.isNotEmpty;
  void choose(String code) {
    final option = current.options.singleWhere((option) => option.code == code);
    _history.add(_current);
    _current = option.nextNode;
  }

  void back() {
    if (canGoBack) _current = _history.removeLast();
  }

  void restart() {
    _history.clear();
    _current = flow.entry;
  }
}
