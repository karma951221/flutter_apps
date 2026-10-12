import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/lock/device_auth.dart';
import '../../../domain/lock/lock_attempts.dart';
import '../../../domain/lock/lock_config.dart';
import '../../../domain/lock/lock_policy.dart';
import '../../../domain/lock/lock_repository.dart';
import '../../../domain/lock/relock_timer.dart';
import '../media_pick_guard.dart';
import 'diary_lock_state.dart';

/// 일기 잠금 상태(스펙 §7). 셸이 소유하고 [start] 한 뒤 앱 생명주기를 [onPaused] ·
/// [onResumed] 로 넘긴다. 차단 중 남은 시간 갱신([tick])은 게이트 위젯의 1초 타이머가 부른다.
///
/// 차단 여부는 매번 저장소의 시도 기록으로 다시 판단한다 — `LockPolicy.wrongSecret` 은 기존
/// 차단을 보지 않으므로, 차단 중 입력을 그대로 넘기면 24시간 차단을 30초로 덮어쓴다.
class DiaryLockCubit extends Cubit<DiaryLockState> {
  DiaryLockCubit(this._repo, this._auth, this._clock, this._guard)
    : super(const DiaryLockState.locked(method: LockMethod.pin));

  final LockRepository _repo;
  final DeviceAuth _auth;
  final Clock _clock;
  final MediaPickGuard _guard;

  /// 해제된 채 백그라운드로 간 시각. 잠긴 동안에는 기록하지 않는다.
  DateTime? _pausedAt;

  /// 백그라운드로 갈 때 미디어 선택 중이었다.
  bool _pausedWhilePicking = false;

  /// 해시 확인 · 폰 인증 · 저장이 겹치지 않게 한다(빠른 연속 입력).
  bool _busy = false;

  /// 잠금 꺼짐 → unlocked, 켜짐(깨진 prefs 포함) → locked. 차단은 재시작 뒤에도 이어진다.
  void start() {
    _pausedAt = null;
    final config = _repo.loadConfig();
    emit(
      config.enabled ? _locked(config.method) : const DiaryLockState.unlocked(),
    );
  }

  /// PIN('1234') · 패턴('0-1-2-5') 확인. 차단 중이면 무시하고 남은 시간만 갱신한다.
  Future<void> submit(String secret) async {
    final current = state;
    if (current is! LockLocked || _busy) return;
    final now = _clock.now();
    final attempts = _repo.loadAttempts();
    if (LockPolicy.remaining(attempts, now) != null) {
      emit(_locked(current.method, attempts: attempts, now: now));
      return;
    }
    _busy = true;
    try {
      if (_repo.verify(secret)) {
        await _repo.saveAttempts(LockPolicy.success());
        _pausedAt = null;
        if (!isClosed) emit(const DiaryLockState.unlocked());
        return;
      }
      final next = LockPolicy.wrongSecret(attempts, now);
      await _repo.saveAttempts(next);
      if (!isClosed) {
        emit(_locked(current.method, attempts: next, now: now, wrong: true));
      }
    } finally {
      _busy = false;
    }
  }

  /// "잊어버렸어요" → 폰 인증. 성공하면 [LockResetting], 실패 · 폰이 인증을 잠갔으면 24시간
  /// 차단, 취소하면 그대로, 인증을 띄울 수 없으면 안내만. 차단 중이면 인증을 띄우지 않는다.
  Future<void> forgot(String reason) async {
    final current = state;
    if (current is! LockLocked || _busy) return;
    final attempts = _repo.loadAttempts();
    final before = _clock.now();
    if (LockPolicy.remaining(attempts, before) != null) {
      emit(_locked(current.method, attempts: attempts, now: before));
      return;
    }
    _busy = true;
    try {
      final result = await _auth.authenticate(reason);
      final now = _clock.now();
      switch (result) {
        case DeviceAuthResult.success:
          await _repo.saveAttempts(LockPolicy.success());
          if (!isClosed) emit(const DiaryLockState.resetting());
        case DeviceAuthResult.failed || DeviceAuthResult.lockedOut:
          final next = LockPolicy.deviceAuthFailed(now);
          await _repo.saveAttempts(next);
          if (!isClosed) {
            emit(_locked(current.method, attempts: next, now: now));
          }
        case DeviceAuthResult.canceled:
          if (!isClosed) emit(_locked(current.method, now: now));
        case DeviceAuthResult.unavailable:
          if (!isClosed) {
            emit(_locked(current.method, now: now, deviceUnavailable: true));
          }
      }
    } finally {
      _busy = false;
    }
  }

  /// 폰 인증 뒤 새 비밀을 등록하고 잠금을 푼다. [LockResetting] 이 아니면 무시한다.
  Future<void> finishReset(LockMethod method, String secret) async {
    if (state is! LockResetting || _busy) return;
    _busy = true;
    try {
      // setSecret 이 방식도 바꾼다 — 설정은 그 뒤에 새로 읽어 저장한다.
      await _repo.setSecret(method, secret);
      final config = _repo.loadConfig();
      await _repo.saveConfig(config.copyWith(enabled: true, method: method));
      await _repo.saveAttempts(LockPolicy.success());
      _pausedAt = null;
      if (!isClosed) emit(const DiaryLockState.unlocked());
    } finally {
      _busy = false;
    }
  }

  /// 설정 화면(`LockSetupPage`)이 잠금을 켜고 끄거나 방식을 바꾼 뒤 부른다(설정 탭이
  /// 페이지가 `true` 로 닫히면 호출). 꺼졌으면 unlocked, 잠긴 중이면 새 방식으로 다시
  /// 잠그고(진행 중인 차단은 유지), 풀린 · 재설정 중이면 그대로 둔다 — 새로 켰으면 다음
  /// 백그라운드 복귀에서 잠긴다.
  void configChanged() {
    final config = _repo.loadConfig();
    if (!config.enabled) {
      emit(const DiaryLockState.unlocked());
      return;
    }
    if (state is LockLocked) emit(_locked(config.method));
  }

  void onPaused() {
    if (state is LockLocked) return;
    _pausedAt = _clock.now();
    _pausedWhilePicking = _guard.active;
  }

  void onResumed() {
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null || state is LockLocked) return;
    final config = _repo.loadConfig();
    if (!config.enabled) return;
    final lock = RelockTimer.shouldLock(
      pausedAt: pausedAt,
      now: _clock.now(),
      delay: config.relockDelay,
      pickingMedia: _pausedWhilePicking || _guard.active,
    );
    if (lock) emit(_locked(config.method));
  }

  /// 차단 남은 시간을 다시 계산한다. 끝났으면 차단 표시를 지운다.
  void tick() {
    final current = state;
    if (current is! LockLocked || current.blockedFor == null) return;
    emit(_locked(current.method));
  }

  LockLocked _locked(
    LockMethod method, {
    LockAttempts? attempts,
    DateTime? now,
    bool wrong = false,
    bool deviceUnavailable = false,
  }) {
    final a = attempts ?? _repo.loadAttempts();
    final left = LockPolicy.remaining(a, now ?? _clock.now());
    return LockLocked(
      method: method,
      blockedFor: left,
      longBlock: left != null && a.longBlock,
      wrong: wrong,
      deviceUnavailable: deviceUnavailable,
    );
  }
}
