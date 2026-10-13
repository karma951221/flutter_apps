import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/lock/device_auth.dart';
import '../../../domain/lock/lock_attempts.dart';
import '../../../domain/lock/lock_config.dart';
import '../../../domain/lock/lock_policy.dart';
import '../../../domain/lock/lock_repository.dart';
import 'lock_setup_state.dart';

/// 새 비밀을 받는 곳. [Future] 가 끝나면 [SetupDone].
typedef LockSecretSave =
    Future<void> Function(LockMethod method, String secret);

/// 잠금 켜기 · 끄기 · 방식 변경(설정 화면)과 폰 인증 뒤 새 비밀 등록(스펙 §7).
///
/// 켜기는 폰 화면 잠금이 있어야 한다. 끄기 · 방식 변경은 현재 비밀을 확인한 뒤에만 —
/// 그 확인도 잠금 화면과 같은 실패 횟수 · 차단을 쓴다(설정 화면으로 우회하지 못하게).
/// 새 비밀은 두 번 같게 입력해야 받는다.
class LockSetupCubit extends Cubit<LockSetupState> {
  LockSetupCubit(this._repo, this._auth, this._clock)
    : super(const LockSetupState.loading());

  final LockRepository _repo;
  final DeviceAuth _auth;
  final Clock _clock;

  /// 확인 단계에서 비교할 첫 입력.
  String? _first;

  /// 새 비밀 저장. 기본은 설정 저장, 재설정 흐름은 바깥이 넘긴다.
  late LockSecretSave _save = _saveAndEnable;

  bool _busy = false;

  /// 설정 화면 진입. 켜져 있으면 확인부터, 꺼져 있으면 폰 화면 잠금을 확인한다.
  Future<void> start() async {
    final config = _repo.loadConfig();
    if (config.enabled) {
      emit(_verifying(config.method));
      return;
    }
    final hasScreenLock = await _auth.hasScreenLock();
    if (isClosed) return;
    emit(
      hasScreenLock
          ? const LockSetupState.choosing()
          : const LockSetupState.needsScreenLock(),
    );
  }

  /// 설정 앱을 다녀온 뒤. 화면 잠금 안내 중일 때만 다시 확인해, 생겼으면 이어서 진행한다.
  Future<void> recheck() async {
    if (state is! SetupNeedsScreenLock) return;
    final hasScreenLock = await _auth.hasScreenLock();
    if (isClosed || state is! SetupNeedsScreenLock || !hasScreenLock) return;
    emit(const LockSetupState.choosing());
  }

  /// 폰 인증 뒤 새 비밀 등록. 확인 없이 방식 고르기부터, 두 번 같으면 [save] 로 넘긴다.
  void startReset(LockSecretSave save) {
    _save = save;
    emit(const LockSetupState.choosing());
  }

  /// 현재 비밀 확인. 차단 중이면 무시하고 남은 시간만 갱신한다.
  Future<void> verifyCurrent(String secret) async {
    final current = state;
    if (current is! SetupVerifying || _busy) return;
    final now = _clock.now();
    final attempts = _repo.loadAttempts();
    if (LockPolicy.remaining(attempts, now) != null) {
      emit(_verifying(current.method, attempts: attempts, now: now));
      return;
    }
    _busy = true;
    try {
      if (_repo.verify(secret)) {
        await _repo.saveAttempts(LockPolicy.success());
        if (!isClosed) {
          emit(
            LockSetupState.choosing(current: current.method, canTurnOff: true),
          );
        }
        return;
      }
      final next = LockPolicy.wrongSecret(attempts, now);
      await _repo.saveAttempts(next);
      if (!isClosed) {
        emit(_verifying(current.method, attempts: next, now: now, wrong: true));
      }
    } finally {
      _busy = false;
    }
  }

  /// 차단 남은 시간을 다시 계산한다(화면의 1초 타이머).
  void tick() {
    final current = state;
    if (current is! SetupVerifying || current.blockedFor == null) return;
    emit(_verifying(current.method));
  }

  void choose(LockMethod method) {
    if (state is! SetupChoosing) return;
    _first = null;
    emit(LockSetupState.entering(method: method));
  }

  /// 새 비밀 입력. 첫 입력 → 확인 입력. 다르면 [LockSetupError.mismatch] 로 처음부터.
  Future<void> enter(String secret) async {
    final current = state;
    if (current is! SetupEntering || _busy) return;
    if (!_valid(current.method, secret)) {
      emit(current.copyWith(error: LockSetupError.tooShort));
      return;
    }
    final first = _first;
    if (first == null) {
      _first = secret;
      emit(LockSetupState.entering(method: current.method, confirming: true));
      return;
    }
    _first = null;
    if (first != secret) {
      emit(
        LockSetupState.entering(
          method: current.method,
          error: LockSetupError.mismatch,
        ),
      );
      return;
    }
    _busy = true;
    try {
      await _save(current.method, secret);
      if (!isClosed) emit(const LockSetupState.done());
    } finally {
      _busy = false;
    }
  }

  /// 확인을 마친 뒤에만. 비밀을 지우고 잠금을 끈다(다시 잠기는 시간은 그대로).
  Future<void> turnOff() async {
    final current = state;
    if (current is! SetupChoosing || !current.canTurnOff || _busy) return;
    _busy = true;
    try {
      await _repo.clearSecret();
      final config = _repo.loadConfig();
      await _repo.saveConfig(config.copyWith(enabled: false));
      if (!isClosed) emit(const LockSetupState.done());
    } finally {
      _busy = false;
    }
  }

  Future<void> _saveAndEnable(LockMethod method, String secret) async {
    // setSecret 이 방식도 바꾼다 — 설정은 그 뒤에 새로 읽어 저장한다.
    await _repo.setSecret(method, secret);
    final config = _repo.loadConfig();
    await _repo.saveConfig(config.copyWith(enabled: true, method: method));
  }

  static final _pin = RegExp(r'^\d{4}$');

  static bool _valid(LockMethod method, String secret) => switch (method) {
    LockMethod.pin => _pin.hasMatch(secret),
    LockMethod.pattern => secret.split('-').length >= PatternRule.minDots,
  };

  SetupVerifying _verifying(
    LockMethod method, {
    LockAttempts? attempts,
    DateTime? now,
    bool wrong = false,
  }) {
    final a = attempts ?? _repo.loadAttempts();
    final left = LockPolicy.remaining(a, now ?? _clock.now());
    return SetupVerifying(
      method: method,
      blockedFor: left,
      longBlock: left != null && a.longBlock,
      wrong: wrong,
    );
  }
}
