import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/alarm/ring_log.dart';

part 'alarm_history_state.freezed.dart';

@freezed
sealed class AlarmHistoryState with _$AlarmHistoryState {
  const factory AlarmHistoryState.loading() = AlarmHistoryLoading;

  /// [groups] 는 최근 회차가 먼저. [now] 는 날짜 머리(오늘 · 어제)의 기준.
  const factory AlarmHistoryState.loaded({
    required List<RingLogGroup> groups,
    required DateTime now,
  }) = AlarmHistoryLoaded;

  const factory AlarmHistoryState.failure() = AlarmHistoryFailure;
}
