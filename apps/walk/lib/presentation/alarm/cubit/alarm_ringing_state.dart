import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/alarm/entity/alarm.dart';

part 'alarm_ringing_state.freezed.dart';

@freezed
class AlarmRingingState with _$AlarmRingingState {
  /// 울리는 회차의 알람. 못 찾았거나(지워짐) 아직 읽는 중이면 null — 기본 제목을 보인다.
  @override
  final Alarm? alarm;

  /// 이 회차를 스누즈할 수 있는가. 스누즈 한도를 다 썼으면 false — 스누즈 버튼을 숨긴다.
  /// 읽기 전 · 읽지 못했으면 true(늦게 눌린 스누즈는 use case 가 멈춤으로 바꾼다).
  @override
  final bool canSnooze;

  /// 끄기 · 스누즈를 처리 중 — 버튼을 잠근다.
  @override
  final bool busy;

  const AlarmRingingState({this.alarm, this.canSnooze = true, this.busy = false});
}
