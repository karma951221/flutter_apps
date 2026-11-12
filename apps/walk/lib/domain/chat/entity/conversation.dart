import 'package:characters/characters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../attachment/chat_attachment.dart';
import '../chat_vendor.dart';

part 'conversation.freezed.dart';

/// 목록 한 줄. [turnCount] 는 저장된 턴 수.
///
/// `toString` 은 제목(첫 질문에서 온 글)을 담지 않는다.
@freezed
class Conversation with _$Conversation {
  @override
  final String id;
  @override
  final String title;
  @override
  final bool titleEdited;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final int turnCount;

  const Conversation({
    required this.id,
    required this.title,
    required this.titleEdited,
    required this.createdAt,
    required this.updatedAt,
    required this.turnCount,
  });

  @override
  String toString() => 'Conversation(id: $id, turns: $turnCount)';
}

/// 저장된 턴 하나(보이는 글만 — D1).
///
/// `toString` 은 질문 · 답 글 대신 길이만 담는다.
@freezed
class ChatTurnRecord with _$ChatTurnRecord {
  @override
  final String conversationId;

  /// 대화 안에서 1부터.
  @override
  final int seq;
  @override
  final String question;
  @override
  final String answer;
  @override
  final List<String> citedEntryIds;
  @override
  final bool stopped;
  @override
  final ChatVendor vendor;
  @override
  final String model;
  @override
  final DateTime askedAt;

  /// 이 질문에 붙은 파일(본문 없음).
  @override
  final List<ChatAttachmentRef> attachments;

  const ChatTurnRecord({
    required this.conversationId,
    required this.seq,
    required this.question,
    required this.answer,
    required this.citedEntryIds,
    required this.stopped,
    required this.vendor,
    required this.model,
    required this.askedAt,
    this.attachments = const [],
  });

  ChatTurnText get text => ChatTurnText(
    question: question,
    answer: answer,
    stopped: stopped,
    attachmentNames: [for (final a in attachments) a.name],
  );

  @override
  String toString() =>
      'ChatTurnRecord(conversationId: $conversationId, seq: $seq, '
      'answerLength: ${answer.length}, stopped: $stopped, '
      'attachments: ${attachments.length})';
}

/// cubit 이 저장소에 넘기는 새 턴.
@freezed
class ChatTurnDraft with _$ChatTurnDraft {
  @override
  final String question;
  @override
  final String answer;
  @override
  final List<String> citedEntryIds;
  @override
  final bool stopped;
  @override
  final ChatVendor vendor;
  @override
  final String model;

  /// 이 질문에 붙은 파일(본문 없음).
  @override
  final List<ChatAttachmentRef> attachments;

  const ChatTurnDraft({
    required this.question,
    required this.answer,
    required this.citedEntryIds,
    this.stopped = false,
    required this.vendor,
    required this.model,
    this.attachments = const [],
  });

  @override
  String toString() =>
      'ChatTurnDraft(questionLength: ${question.length}, '
      'answerLength: ${answer.length}, stopped: $stopped, '
      'attachments: ${attachments.length})';
}

/// 세션이 문맥을 다시 채울 때 쓰는 글만의 턴(Task 4).
@freezed
class ChatTurnText with _$ChatTurnText {
  @override
  final String question;
  @override
  final String answer;
  @override
  final bool stopped;

  /// 이 질문에 붙었던 파일 이름(문맥을 다시 채울 때 질문 끝 줄에 붙인다).
  @override
  final List<String> attachmentNames;

  const ChatTurnText({
    required this.question,
    required this.answer,
    this.stopped = false,
    this.attachmentNames = const [],
  });

  @override
  String toString() =>
      'ChatTurnText(questionLength: ${question.length}, '
      'answerLength: ${answer.length}, stopped: $stopped, '
      'attachments: ${attachmentNames.length})';
}

/// appendTurn 이 돌려주는 저장 위치.
typedef ChatTurnRef = ({String conversationId, int seq});

const conversationTitleMax = 30;

final _whitespace = RegExp(r'\s+');

/// 첫 질문의 앞 30자(공백 · 줄바꿈 묶음은 공백 하나, trim, 글자는 grapheme 단위). 넘치면 끝에 '…'.
String conversationTitleFrom(String question) {
  final chars = question.replaceAll(_whitespace, ' ').trim().characters;
  if (chars.length <= conversationTitleMax) return chars.string;
  return '${chars.take(conversationTitleMax)}…';
}
