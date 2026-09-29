import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/alarm/entity/alarm.dart';

part 'alarm_list_state.freezed.dart';

@freezed
sealed class AlarmListState with _$AlarmListState {
  const factory AlarmListState.loading() = AlarmListLoading;

  /// [nextAt] 은 켜진 알람 id → 실제 다음 울림(스누즈 포함). 예약이 없으면 키가 없다.
  /// 남은 시간은 상태에 두지 않고 화면이 `nextAt[id]!.difference(now)` 로 센다.
  /// [now] 는 표시 기준 시각 — `load` · `tick` 때 정한다.
  /// [canRing] 이 false 면 알림 · 정확한 알람 중 하나가 거부된 상태(경고 배너).
  const factory AlarmListState.loaded({
    required List<Alarm> alarms,
    required Map<int, DateTime> nextAt,
    required DateTime now,
    @Default(true) bool canRing,
  }) = AlarmListLoaded;
}
