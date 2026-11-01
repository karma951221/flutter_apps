import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/entity/chat_usage_summary.dart';

part 'chat_usage_state.freezed.dart';

/// 사용량 화면 — 보고 있는 달과 그 달의 합계.
@freezed
class ChatUsageState with _$ChatUsageState {
  @override
  final int year;
  @override
  final int month;

  /// null = 아직 읽지 않음(또는 읽기 실패).
  @override
  final ChatUsageMonth? usage;
  @override
  final bool loading;

  const ChatUsageState({
    required this.year,
    required this.month,
    this.usage,
    this.loading = true,
  });
}
