import 'lock_attempts.dart';
import 'lock_config.dart';

/// 일기 잠금 설정 · 비밀 · 시도 기록 저장. 비밀 원문은 저장하지 않는다(salt + 반복 해시).
/// 비밀 문자열: PIN 은 '1234', 패턴은 점 인덱스(0~8)를 '-' 로 이은 '0-1-2-5'.
abstract interface class LockRepository {
  /// 깨진 prefs(해시 · salt 중 하나만 있음, 타입 오류) → enabled=true 로 돌려 잠금을 유지한다.
  LockConfig loadConfig();

  Future<void> saveConfig(LockConfig c);

  /// 새 salt 로 [secret] 의 해시를 저장하고 방식을 [m] 으로 바꾼다.
  Future<void> setSecret(LockMethod m, String secret);

  /// 저장된 비밀과 같으면 true. 비밀이 없거나 깨졌으면 항상 false(재설정 유도).
  bool verify(String secret);

  bool get hasSecret;

  LockAttempts loadAttempts();

  Future<void> saveAttempts(LockAttempts a);

  Future<void> clearSecret();
}
