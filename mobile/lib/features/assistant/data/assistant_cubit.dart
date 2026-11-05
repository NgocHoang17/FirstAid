import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/app_services.dart';

enum ChatStatus {
  answered,
  clarificationNeeded,
  emergencyRedirect,
  insufficientEvidence,
  outOfScope,
  unavailable,
}

class ChatCitation {
  ChatCitation(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'] as String;
  String get sourceId => json['source_id'] as String;
  int get revision => json['source_revision'] as int;
}

class ChatReply {
  ChatReply({
    required this.status,
    this.blocks = const [],
    this.citations = const [],
    this.question,
    this.categoryCode,
    this.articleId,
  });
  final ChatStatus status;
  final List<String> blocks;
  final List<ChatCitation> citations;
  final String? question, categoryCode, articleId;

  factory ChatReply.parse(Map<String, dynamic> data, String requestId) {
    if (data['request_id'] != requestId) {
      throw const FormatException('Mismatched request');
    }
    final status = switch (data['status']) {
      'answered' => ChatStatus.answered,
      'clarification_needed' => ChatStatus.clarificationNeeded,
      'emergency_redirect' => ChatStatus.emergencyRedirect,
      'insufficient_evidence' => ChatStatus.insufficientEvidence,
      'out_of_scope' => ChatStatus.outOfScope,
      'unavailable' => ChatStatus.unavailable,
      _ => throw const FormatException('Unknown chat status'),
    };
    final blocks = <String>[], citations = <ChatCitation>[];
    if (status == ChatStatus.answered) {
      final byId = <String, ChatCitation>{};
      for (final raw in data['citations'] as List) {
        final citation = ChatCitation(Map<String, dynamic>.from(raw as Map));
        if (citation.id.isEmpty ||
            citation.sourceId.isEmpty ||
            citation.revision < 1 ||
            byId.containsKey(citation.id) ||
            (citation.json['evidence_id'] as String? ?? '').isEmpty) {
          throw const FormatException('Invalid citation');
        }
        byId[citation.id] = citation;
      }
      for (final raw in data['answer_blocks'] as List) {
        final text = (raw['text'] as String).trim();
        final ids = List<String>.from(raw['citation_ids'] as List);
        if (text.isEmpty ||
            ids.isEmpty ||
            ids.any((id) => !byId.containsKey(id))) {
          throw const FormatException('Uncited answer');
        }
        blocks.add(text);
        for (final id in ids) {
          if (!citations.contains(byId[id])) citations.add(byId[id]!);
        }
      }
      if (blocks.isEmpty) throw const FormatException('Empty answer');
    }
    final question = data['clarification_question'] as String?;
    if (status == ChatStatus.clarificationNeeded &&
        (question == null || question.trim().isEmpty)) {
      throw const FormatException('Missing clarification');
    }
    return ChatReply(
      status: status,
      blocks: blocks,
      citations: citations,
      question: question,
      categoryCode: data['suggested_category_code'] as String?,
      articleId: data['suggested_article_id'] as String?,
    );
  }
}

class ChatTurn {
  const ChatTurn(this.message, this.age, {this.reply, this.offline = false});
  final String message;
  final String? age;
  final ChatReply? reply;
  final bool offline;
}

class AssistantState {
  const AssistantState({
    this.turns = const [],
    this.sending = false,
    this.offline = false,
  });
  final List<ChatTurn> turns;
  final bool sending, offline;
}

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit(this.api) : super(const AssistantState());
  final PublicApi api;
  Future<void> checkConnection() async {
    final online = await api.network.isOnline();
    if (!isClosed) {
      emit(
        AssistantState(
          turns: state.turns,
          sending: state.sending,
          offline: !online,
        ),
      );
    }
  }

  String _requestId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> send(String message, String? age, {bool retry = false}) async {
    message = message.trim();
    if (state.sending || message.isEmpty || message.length > 2000) return;
    final previous = [...state.turns];
    if (retry && previous.isNotEmpty) previous.removeLast();
    emit(
      AssistantState(
        turns: [...previous, ChatTurn(message, age)],
        sending: true,
      ),
    );
    ChatReply reply;
    var offline = false;
    try {
      final id = _requestId();
      final response = await api.ask({
        'client_request_id': id,
        'message': message,
        'age_group': age,
        'context_mode': 'learning',
      });
      reply = ChatReply.parse(response, id);
    } catch (error) {
      offline = error is OfflineException;
      reply = ChatReply(status: ChatStatus.unavailable);
    }
    if (!isClosed) {
      emit(
        AssistantState(
          turns: [
            ...previous,
            ChatTurn(message, age, reply: reply, offline: offline),
          ],
          offline: offline,
        ),
      );
    }
  }
}
