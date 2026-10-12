import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/lock/lock_config.dart';

part 'lock_setup_state.freezed.dart';

/// 새 비밀 입력이 거절된 이유.
enum LockSetupError {
  /// 확인 입력이 첫 입력과 다르다 — 처음부터 다시.
  mismatch,

  /// PIN 이 4자리가 아니거나 패턴 점이 4개보다 적다.
  tooShort,
}

/// 잠금 설정 화면 · 폰 인증 뒤 재설정 흐름(스펙 §7).
@freezed
sealed class LockSetupState with _$LockSetupState {
  const factory LockSetupState.loading() = SetupLoading;

  /// 폰 화면 잠금이 없어 켤 수 없다.
  const factory LockSetupState.needsScreenLock() = SetupNeedsScreenLock;

  /// 끄기 · 방식 변경 전 현재 비밀 확인. 실패 · 차단은 잠금 화면과 같은 기록을 쓴다.
  const factory LockSetupState.verifying({
    required LockMethod method,
    Duration? blockedFor,
    @Default(false) bool longBlock,
    @Default(false) bool wrong,
  }) = SetupVerifying;

  /// 방식 고르기. [current] 는 지금 쓰는 방식(꺼져 있으면 null).
  const factory LockSetupState.choosing({
    LockMethod? current,
    @Default(false) bool canTurnOff,
  }) = SetupChoosing;

  /// 새 비밀 입력. [confirming] 이면 두 번째(확인) 입력.
  const factory LockSetupState.entering({
    required LockMethod method,
    @Default(false) bool confirming,
    LockSetupError? error,
  }) = SetupEntering;

  const factory LockSetupState.done() = SetupDone;
}
