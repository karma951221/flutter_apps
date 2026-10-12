import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/lock/lock_attempts.dart';
import '../../domain/lock/lock_config.dart';
import '../../domain/lock/lock_repository.dart';
import 'secret_hasher.dart';

@LazySingleton(as: LockRepository)
class PrefsLockRepository implements LockRepository {
  PrefsLockRepository(this._prefs);

  final SharedPreferences _prefs;

  static const enabledKey = 'walk.lock.enabled';
  static const methodKey = 'walk.lock.method';
  static const relockKey = 'walk.lock.relock';
  static const saltKey = 'walk.lock.salt';
  static const hashKey = 'walk.lock.hash';
  static const failuresKey = 'walk.lock.failures';

  /// 차단 해제 시각(epoch 밀리초).
  static const blockedUntilKey = 'walk.lock.blockedUntil';
  static const longBlockKey = 'walk.lock.longBlock';

  // getString 등은 다른 타입 값에서 던진다 — 모두 get + 타입 확인으로 읽는다.

  @override
  LockConfig loadConfig() {
    final enabled = _prefs.get(enabledKey);
    final method = _prefs.get(methodKey);
    final relock = _prefs.get(relockKey);
    final corrupt =
        (enabled != null && enabled is! bool) ||
        (method != null && method is! String) ||
        (relock != null && relock is! String) ||
        _secretCorrupt;
    return LockConfig(
      // 깨졌으면 잠금을 끄지 않는다 — 잠긴 채 폰 인증 재설정으로 유도한다.
      enabled: corrupt || enabled == true,
      method: LockMethod.values.asNameMap()[method] ?? LockMethod.pin,
      relockDelay:
          RelockDelay.values.asNameMap()[relock] ?? RelockDelay.fallback,
    );
  }

  /// 해시 · salt 중 하나만 있거나 문자열이 아니다.
  bool get _secretCorrupt {
    final salt = _prefs.get(saltKey);
    final hash = _prefs.get(hashKey);
    if (salt == null && hash == null) return false;
    return salt is! String || hash is! String;
  }

  @override
  Future<void> saveConfig(LockConfig c) async {
    await Future.wait([
      _prefs.setBool(enabledKey, c.enabled),
      _prefs.setString(methodKey, c.method.name),
      _prefs.setString(relockKey, c.relockDelay.name),
    ]);
  }

  @override
  Future<void> setSecret(LockMethod m, String secret) async {
    final salt = SecretHasher.newSalt();
    final hash = SecretHasher.hash(salt, secret);
    await Future.wait([
      _prefs.setString(saltKey, salt),
      _prefs.setString(hashKey, hash),
      _prefs.setString(methodKey, m.name),
    ]);
  }

  @override
  bool verify(String secret) {
    final salt = _prefs.get(saltKey);
    final hash = _prefs.get(hashKey);
    if (salt is! String || hash is! String) return false;
    return SecretHasher.matches(SecretHasher.hash(salt, secret), hash);
  }

  @override
  bool get hasSecret =>
      _prefs.get(saltKey) is String && _prefs.get(hashKey) is String;

  @override
  Future<void> clearSecret() async {
    await Future.wait([_prefs.remove(saltKey), _prefs.remove(hashKey)]);
  }

  @override
  LockAttempts loadAttempts() {
    final failures = _prefs.get(failuresKey);
    final blockedUntil = _prefs.get(blockedUntilKey);
    final longBlock = _prefs.get(longBlockKey);
    return LockAttempts(
      failures: failures is int && failures > 0 ? failures : 0,
      blockedUntil: blockedUntil is int
          ? DateTime.fromMillisecondsSinceEpoch(blockedUntil)
          : null,
      longBlock: longBlock is bool && longBlock,
    );
  }

  @override
  Future<void> saveAttempts(LockAttempts a) async {
    final blockedUntil = a.blockedUntil;
    await Future.wait([
      _prefs.setInt(failuresKey, a.failures),
      if (blockedUntil == null)
        _prefs.remove(blockedUntilKey)
      else
        _prefs.setInt(blockedUntilKey, blockedUntil.millisecondsSinceEpoch),
      _prefs.setBool(longBlockKey, a.longBlock),
    ]);
  }
}
