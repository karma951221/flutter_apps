import 'package:freezed_annotation/freezed_annotation.dart';

import '../entity/record_interval.dart';
import '../entity/record_mode.dart';

part 'recorder_status.freezed.dart';

/// 위치 기록 서비스의 지금 상태.
@freezed
sealed class RecorderStatus with _$RecorderStatus {
  /// 기록하지 않는다.
  const factory RecorderStatus.off() = RecorderOff;

  /// 기록 중. [stillDetection] 이 false 면 정지 감지 없이 3분 간격.
  /// [intervalSec] 은 고정 주기 기록([RecordMode.dense])의 주기(초) — 평소 모드에서도 저장된 값을 싣는다.
  /// [recordingSince] 는 지금 서비스 인스턴스가 기록을 시작한 시각(UTC). 그 뒤로 끊김 없이 기록
  /// 중이다. 서비스가 죽어 있다가 이번 `status` 가 되살렸으면 null.
  const factory RecorderStatus.running(
    RecordMode mode, {
    required bool stillDetection,
    DateTime? recordingSince,
    @Default(RecordInterval.minSeconds) int intervalSec,
  }) = RecorderRunning;

  /// 켜 두었지만 권한을 잃어 기록하지 못한다.
  const factory RecorderStatus.blocked(
    RecordMode mode, {
    @Default(RecordInterval.minSeconds) int intervalSec,
  }) = RecorderBlocked;
}

/// 켜 둔 기록의 주기. 꺼져 있으면 null.
RecordInterval? recordIntervalOf(RecorderStatus status) => switch (status) {
  RecorderOff() => null,
  RecorderRunning(:final mode, :final intervalSec) ||
  RecorderBlocked(
    :final mode,
    :final intervalSec,
  ) => RecordInterval.of(mode, intervalSec),
};
