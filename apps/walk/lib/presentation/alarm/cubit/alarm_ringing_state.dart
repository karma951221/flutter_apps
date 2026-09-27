import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/alarm/entity/alarm.dart';

part 'alarm_ringing_state.freezed.dart';

@freezed
class AlarmRingingState with _$AlarmRingingState {
  /// 울리는 회차의 알람. 못 찾았거나(지워짐) 아직 읽는 중이면 null — 기본 제목을 보인다.
  @override
  final Alarm? alarm;

  /// 끄기 · 스누즈를 처리 중 — 버튼을 잠근다.
  @override
  final bool busy;

  const AlarmRingingState({this.alarm, this.busy = false});
}
