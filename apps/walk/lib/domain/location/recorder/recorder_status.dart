import 'package:freezed_annotation/freezed_annotation.dart';

import '../entity/record_mode.dart';

part 'recorder_status.freezed.dart';

/// 위치 기록 서비스의 지금 상태.
@freezed
sealed class RecorderStatus with _$RecorderStatus {
  /// 기록하지 않는다.
  const factory RecorderStatus.off() = RecorderOff;

  /// 기록 중. [stillDetection] 이 false 면 정지 감지 없이 3분 간격.
  /// [recordingSince] 는 지금 서비스 인스턴스가 기록을 시작한 시각(UTC). 그 뒤로 끊김 없이 기록
  /// 중이다. 서비스가 죽어 있다가 이번 `status` 가 되살렸으면 null.
  const factory RecorderStatus.running(
    RecordMode mode, {
    required bool stillDetection,
    DateTime? recordingSince,
  }) = RecorderRunning;

  /// 켜 두었지만 권한을 잃어 기록하지 못한다.
  const factory RecorderStatus.blocked(RecordMode mode) = RecorderBlocked;
}
