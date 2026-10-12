import 'package:freezed_annotation/freezed_annotation.dart';

part 'lock_attempts.freezed.dart';

/// 잠금 해제 시도 기록. 재시작해도 유지한다(스펙 §7).
@freezed
class LockAttempts with _$LockAttempts {
  /// 연속으로 틀린 횟수. 차단이 걸리면 0 으로 돌아간다.
  @override
  final int failures;

  /// 이 시각 전까지 모든 해제 시도를 거절한다.
  @override
  final DateTime? blockedUntil;

  /// 폰 인증 실패로 걸린 24시간 차단이면 true(아니면 30초 차단).
  @override
  final bool longBlock;

  const LockAttempts({
    this.failures = 0,
    this.blockedUntil,
    this.longBlock = false,
  });
}
