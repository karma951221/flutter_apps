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

  const ChatUsageMonth({
    required this.year,
    required this.month,
    required this.totals,
    required this.rows,
  });
}
