import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/lock/lock_config.dart';

part 'diary_lock_state.freezed.dart';

/// 일기 잠금 게이트 상태(스펙 §7). 기록 위젯은 [LockUnlocked] 일 때만 트리에 있다.
@freezed
sealed class DiaryLockState with _$DiaryLockState {
  const factory DiaryLockState.unlocked() = LockUnlocked;

  /// [blockedFor] 가 있으면 그동안 모든 해제 시도를 거절한다. [longBlock] 은 폰 인증
  /// 실패로 걸린 24시간 차단. [wrong] 은 방금 틀렸다. [deviceUnavailable] 은 방금 폰
  /// 인증을 띄울 수 없었다(안내만, 차단 아님).
  const factory DiaryLockState.locked({
    required LockMethod method,
    Duration? blockedFor,
    @Default(false) bool longBlock,
    @Default(false) bool wrong,
    @Default(false) bool deviceUnavailable,
  }) = LockLocked;

  /// 폰 인증 성공 → 새 비밀 등록 화면.
  const factory DiaryLockState.resetting() = LockResetting;
}
