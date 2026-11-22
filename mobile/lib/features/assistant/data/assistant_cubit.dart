import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/app_services.dart';
import '../../first_aid/presentation/quick_aid_pages.dart'
    show searchKey, situations;

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
    this.blockKinds = const [],
  });
  final ChatStatus status;
  final List<String> blocks;
  final List<String> blockKinds;
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
    final blocks = <String>[], kinds = <String>[], citations = <ChatCitation>[];
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
        final kind =
            raw['kind'] as String? ??
            (blocks.length == 1 ? 'heading' : 'paragraph');
        if (!{
          'paragraph',
          'heading',
          'steps',
          'warning',
          'help',
        }.contains(kind)) {
          throw const FormatException('Unknown answer block kind');
        }
        kinds.add(kind);
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
      blockKinds: kinds,
      citations: citations,
      question: question,
      categoryCode: data['suggested_category_code'] as String?,
      articleId: data['suggested_article_id'] as String?,
    );
  }
}

class ChatTurn {
  const ChatTurn(
    this.message,
    this.age, {
    this.reply,
    this.offline = false,
    this.hasImage = false,
    this.issue,
  });
  final String message;
  final String? age;
  final ChatReply? reply;
  final bool offline, hasImage;
  final String? issue;
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
  void clearConversation() {
    if (!state.sending) emit(AssistantState(offline: state.offline));
  }

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

  Future<void> send(
    String message,
    String? age, {
    bool retry = false,
    Uint8List? image,
    String? mime,
  }) async {
    message = message.trim();
    if (state.sending || message.isEmpty || message.length > 2000) return;
    final previous = [...state.turns];
    if (retry && previous.isNotEmpty) previous.removeLast();
    final normalized = searchKey(message);
    final ages = RegExp(r'\b(\d{1,3}) tuoi\b').allMatches(normalized).toList();
    if (RegExp(r'\b(tre|be)\b').hasMatch(normalized) &&
        !normalized.contains('nguoi lon')) {
      age = 'CHILD';
    } else if (normalized.contains('nguoi lon') &&
        !normalized.contains('tre em')) {
      age = 'ADULT';
    } else {
      age ??= ages.length == 1
          ? (int.parse(ages.single.group(1)!) >= 18 ? 'ADULT' : 'CHILD')
          : previous.isEmpty
          ? null
          : previous.last.age;
    }
    final context = previous
        .where(
          (turn) =>
              turn.reply?.status == ChatStatus.answered ||
              turn.reply?.status == ChatStatus.clarificationNeeded,
        )
        .map((turn) {
          final code = turn.reply?.categoryCode;
          if (turn.hasImage &&
              code != null &&
              RegExp(r'^FA\d{2}$').hasMatch(code)) {
            final index = int.parse(code.substring(2)) - 1;
            if (index >= 0 &&
                index < situations.length &&
                turn.message.length < 1900) {
              return '${situations[index]} · ${turn.message}';
            }
          }
          return turn.message;
        })
        .toList();
    emit(
      AssistantState(
        turns: [
          ...previous,
          ChatTurn(message, age, hasImage: image != null),
        ],
        sending: true,
      ),
    );
    ChatReply reply;
    String? issue;
    var offline = false;
    try {
      final id = _requestId();
      final request = <String, dynamic>{
        'client_request_id': id,
        'message': message,
        'age_group': age,
        'context_mode': 'learning',
        if (context.isNotEmpty)
          'context_messages': context
              .skip(context.length > 4 ? context.length - 4 : 0)
              .toList(),
      };
      final response = image == null
          ? await api.ask(request)
          : await api.askImage(request, image, mime!);
      reply = ChatReply.parse(response, id);
    } catch (error) {
      offline = error is OfflineException;
      if (image != null && error is DioException) {
        issue = switch (error.response?.statusCode) {
          403 =>
            'Máy chủ chưa cho phép gửi ảnh. Bạn có thể tiếp tục bằng câu hỏi văn bản.',
          404 || 405 =>
            'Máy chủ chưa hỗ trợ nhận ảnh. Bạn có thể mô tả hình bằng chữ để tiếp tục.',
          413 => 'Ảnh quá lớn. Hãy chọn ảnh dưới 5 MiB và 16 triệu điểm ảnh.',
          415 => 'Máy chủ chỉ nhận ảnh JPEG hoặc PNG hợp lệ.',
          _ => null,
        };
      }
      reply = ChatReply(status: ChatStatus.unavailable);
    }
    if (!isClosed) {
      emit(
        AssistantState(
          turns: [
            ...previous,
            ChatTurn(
              message,
              age,
              reply: reply,
              offline: offline,
              hasImage: image != null,
              issue: issue,
            ),
          ],
          offline: offline,
        ),
      );
    }
  }
}
