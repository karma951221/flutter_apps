import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_vendor.dart';

part 'chat_usage_log.freezed.dart';

/// 사용량이 생긴 쓰임. 기록 기획의 위키 정리는 wikiDistill(키 기획 §9 의 `wiki` 를 이 이름으로 맞춤).
enum ChatUsagePurpose { chat, wikiDistill }

/// 요청(도구 라운드) 하나의 토큰 사용량. 질문 · 답 글 · 대화 id 는 담지 않는다.
@freezed
class ChatUsageRecord with _$ChatUsageRecord {
  @override
  final DateTime at;

  /// 한 질문의 라운드를 묶는 무작위 값.
  @override
  final String questionKey;
  @override
  final ChatVendor vendor;
  @override
  final String model;
  @override
  final bool fastMode;
  @override
  final ChatUsagePurpose purpose;

  /// 질문 안에서 1부터.
  @override
  final int round;

  /// 임시 대화 여부.
  @override
  final bool temporary;
  @override
  final int inputTokens;
  @override
  final int outputTokens;
  @override
  final int cacheReadTokens;
  @override
  final int cacheWriteTokens;
  @override
  final int? reasoningTokens;
  @override
  final int wikiIndexNotes;
  @override
  final int wikiIndexChars;
  @override
  final int readWikiCalls;

  const ChatUsageRecord({
    required this.at,
    required this.questionKey,
    required this.vendor,
    required this.model,
    required this.fastMode,
    required this.purpose,
    required this.round,
    required this.temporary,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
    required this.cacheWriteTokens,
    this.reasoningTokens,
    this.wikiIndexNotes = 0,
    this.wikiIndexChars = 0,
    this.readWikiCalls = 0,
  });
}

abstract interface class ChatUsageLog {
  Future<void> record(ChatUsageRecord record);
}
