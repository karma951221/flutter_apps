import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/alarm/entity/alarm.dart';

part 'alarm_list_state.freezed.dart';

@freezed
sealed class AlarmListState with _$AlarmListState {
  const factory AlarmListState.loading() = AlarmListLoading;

  /// [untilNext] 는 켜진 알람 중 가장 이른 회차까지 — 없으면 null(머리 숨김).
  /// [canRing] 이 false 면 알림 · 정확한 알람 중 하나가 거부된 상태(경고 배너).
  const factory AlarmListState.loaded({
    required List<Alarm> alarms,
    Duration? untilNext,
    @Default(true) bool canRing,
  }) = AlarmListLoaded;
}
