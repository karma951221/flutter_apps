import 'package:freezed_annotation/freezed_annotation.dart';

import 'alarm_trigger.dart';

part 'ring_log_entry.freezed.dart';

/// 울림 기록 한 줄의 종류(웨이브 4 스펙 C4). 이름이 곧 저장 형식이다(포크 `RingLogKind.wire`).
enum RingLogKind {
  /// 울리기 시작했다(스누즈 뒤 다시 울림도).
  rang,

  /// 사용자가 껐다(울림 화면 · 알림).
  stopped,

  /// 자동 멈춤(`Alarm.autoStopMinutes`).
  autoStopped,

  /// 스누즈했다.
  snoozed,

  /// 회차를 건너뛰었다. 이 줄의 [RingLogEntry.at] 은 건너뛴 회차의 시각이다.
  skipped,
}

/// 울림 기록 한 줄. 울림 · 끔 · 스누즈는 포크 네이티브가, 건너뛰기는 Dart 가 쓴다.
@freezed
class RingLogEntry with _$RingLogEntry {
  /// 일어난 시각. [RingLogKind.skipped] 는 건너뛴 회차의 시각.
  @override
  final DateTime at;

  /// 회차의 패키지 id.
  @override
  final int packageId;
  @override
  final RingLogKind kind;

  const RingLogEntry({required this.at, required this.packageId, required this.kind});

  int get alarmId => alarmIdOf(packageId);
}
