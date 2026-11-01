import 'package:freezed_annotation/freezed_annotation.dart';

import '../chat_usage_log.dart';
import '../chat_vendor.dart';

part 'chat_usage_summary.freezed.dart';

/// 한 달(또는 한 줄)의 합계. questions 는 서로 다른 질문 수.
@freezed
class ChatUsageTotals with _$ChatUsageTotals {
  @override
  final int questions;
  @override
  final int inputTokens;
  @override
  final int outputTokens;
  @override
  final int cacheReadTokens;

  const ChatUsageTotals({
    required this.questions,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
  });
}

/// 벤더 · 모델 · 쓰임별 한 줄. purpose 가 wikiDistill 이면 화면이 "위키 정리" 줄로 따로 보인다.
@freezed
class ChatUsageModelRow with _$ChatUsageModelRow {
  @override
  final ChatVendor vendor;
  @override
  final String model;
  @override
  final ChatUsagePurpose purpose;
  @override
  final int questions;
  @override
  final int inputTokens;
  @override
  final int outputTokens;

  const ChatUsageModelRow({
    required this.vendor,
    required this.model,
    required this.purpose,
    required this.questions,
    required this.inputTokens,
    required this.outputTokens,
  });
}

/// 그 달 위키 숫자 — purpose == chat · temporary == false 질문 기준.
/// 색인 수 · 글자 수는 질문의 1라운드 값, read_wiki 는 그 질문 라운드 합이 1 이상이면 센다.
@freezed
class ChatUsageWikiStats with _$ChatUsageWikiStats {
  @override
  final int questions;

  /// 질문당 평균 색인 메모 수. 질문이 없으면 0.
  @override
  final double avgIndexNotes;

  /// 질문당 평균 색인 글자 수. 질문이 없으면 0.
  @override
  final double avgIndexChars;

  /// read_wiki 를 한 번이라도 부른 질문 수.
  @override
  final int questionsWithReadWiki;

  const ChatUsageWikiStats({
    required this.questions,
    required this.avgIndexNotes,
    required this.avgIndexChars,
    required this.questionsWithReadWiki,
  });

  static const empty = ChatUsageWikiStats(
    questions: 0,
    avgIndexNotes: 0,
    avgIndexChars: 0,
    questionsWithReadWiki: 0,
  );
}

@freezed
class ChatUsageMonth with _$ChatUsageMonth {
  @override
  final int year;
  @override
  final int month;
  @override
  final ChatUsageTotals totals;

  /// 입력 토큰 많은 순.
  @override
  final List<ChatUsageModelRow> rows;

  @override
  final ChatUsageWikiStats wiki;

  const ChatUsageMonth({
    required this.year,
    required this.month,
    required this.totals,
    required this.rows,
    this.wiki = ChatUsageWikiStats.empty,
  });
}
