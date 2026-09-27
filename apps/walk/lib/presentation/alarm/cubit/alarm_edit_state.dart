import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/alarm/entity/alarm.dart';

part 'alarm_edit_state.freezed.dart';

@freezed
class AlarmEditState with _$AlarmEditState {
  /// 고치는 중인 알람. 새 알람이면 id 가 [Alarm.unsavedId].
  @override
  final Alarm alarm;

  /// 저장 · 삭제 중 — 버튼을 잠근다.
  @override
  final bool busy;

  const AlarmEditState({required this.alarm, this.busy = false});

  bool get isNew => alarm.id == Alarm.unsavedId;
}
