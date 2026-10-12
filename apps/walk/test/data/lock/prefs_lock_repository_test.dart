import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/lock/lock_attempts.dart';
import 'package:walk/domain/lock/lock_config.dart';

void main() {
  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('저장한 적이 없으면 꺼짐 · 비밀 없음 · 시도 기록 없음', () async {
    final repository = PrefsLockRepository(await prefsWith({}));

    expect(repository.loadConfig(), const LockConfig());
    expect(repository.hasSecret, isFalse);
    expect(repository.verify('1234'), isFalse);
    expect(repository.loadAttempts(), const LockAttempts());
  });

  test('설정을 저장하고 새 인스턴스에서 읽는다', () async {
    final prefs = await prefsWith({});
    const config = LockConfig(
      enabled: true,
      method: LockMethod.pattern,
      relockDelay: RelockDelay.minutes5,
    );

    await PrefsLockRepository(prefs).saveConfig(config);

    expect(PrefsLockRepository(prefs).loadConfig(), config);
  });

  group('비밀', () {
    test('원문 PIN 이 prefs 어떤 값에도 없다', () async {
      final prefs = await prefsWith({});

      await PrefsLockRepository(prefs).setSecret(LockMethod.pin, '1234');

      for (final key in prefs.getKeys()) {
        expect('${prefs.get(key)}', isNot(contains('1234')), reason: key);
      }
    });

    test('같은 PIN 을 두 번 등록하면 salt 때문에 해시가 다르다', () async {
      final prefs = await prefsWith({});
      final repository = PrefsLockRepository(prefs);

      await repository.setSecret(LockMethod.pin, '1234');
      final firstHash = prefs.get(PrefsLockRepository.hashKey);
      final firstSalt = prefs.get(PrefsLockRepository.saltKey);
      await repository.setSecret(LockMethod.pin, '1234');

      expect(prefs.get(PrefsLockRepository.hashKey), isNot(firstHash));
      expect(prefs.get(PrefsLockRepository.saltKey), isNot(firstSalt));
      expect(repository.verify('1234'), isTrue);
    });

    test('맞으면 통과, 틀리면 거절', () async {
      final repository = PrefsLockRepository(await prefsWith({}));

      await repository.setSecret(LockMethod.pin, '1234');

      expect(repository.hasSecret, isTrue);
      expect(repository.verify('1234'), isTrue);
      expect(repository.verify('1235'), isFalse);
      expect(repository.verify(''), isFalse);
    });

    test('패턴은 순서를 구분한다', () async {
      final repository = PrefsLockRepository(await prefsWith({}));

      await repository.setSecret(LockMethod.pattern, '0-1-2-5');

      expect(repository.verify('0-1-2-5'), isTrue);
      expect(repository.verify('5-2-1-0'), isFalse);
    });

    test('등록하면 방식도 함께 저장한다', () async {
      final prefs = await prefsWith({});

      await PrefsLockRepository(prefs).setSecret(LockMethod.pattern, '0-1-2-5');

      expect(
        PrefsLockRepository(prefs).loadConfig().method,
        LockMethod.pattern,
      );
    });

    test('재시작한 새 인스턴스에서도 검증된다', () async {
      final prefs = await prefsWith({});
      await PrefsLockRepository(prefs).setSecret(LockMethod.pin, '1234');

      expect(PrefsLockRepository(prefs).verify('1234'), isTrue);
    });

    test('지우면 비밀이 없다', () async {
      final repository = PrefsLockRepository(await prefsWith({}));
      await repository.setSecret(LockMethod.pin, '1234');

      await repository.clearSecret();

      expect(repository.hasSecret, isFalse);
      expect(repository.verify('1234'), isFalse);
    });
  });

  group('시도 기록', () {
    test('실패 횟수 · 차단 해제 시각이 재시작 뒤에도 남는다', () async {
      final prefs = await prefsWith({});
      final attempts = LockAttempts(
        failures: 3,
        blockedUntil: DateTime(2026, 10, 12, 9, 0, 30),
        longBlock: true,
      );

      await PrefsLockRepository(prefs).saveAttempts(attempts);

      expect(PrefsLockRepository(prefs).loadAttempts(), attempts);
    });

    test('차단이 없는 기록을 저장하면 해제 시각을 지운다', () async {
      final prefs = await prefsWith({});
      final repository = PrefsLockRepository(prefs);
      await repository.saveAttempts(
        LockAttempts(blockedUntil: DateTime(2026, 10, 12, 9)),
      );

      await repository.saveAttempts(const LockAttempts(failures: 1));

      expect(
        PrefsLockRepository(prefs).loadAttempts(),
        const LockAttempts(failures: 1),
      );
    });
  });

  group('깨진 prefs 는 잠금을 유지한다', () {
    test('해시만 있고 salt 가 없으면 켜짐 · 검증은 항상 거절', () async {
      final repository = PrefsLockRepository(
        await prefsWith({
          PrefsLockRepository.enabledKey: false,
          PrefsLockRepository.hashKey:
              'zTcFOxqC7XKL6T7VzTE/ulL94pPzH512qAiFFTJYpXk=',
        }),
      );

      expect(repository.loadConfig().enabled, isTrue);
      expect(repository.hasSecret, isFalse);
      expect(repository.verify('1234'), isFalse);
      expect(repository.verify(''), isFalse);
    });

    test('salt 만 있고 해시가 없으면 켜짐', () async {
      final repository = PrefsLockRepository(
        await prefsWith({
          PrefsLockRepository.saltKey: 'c2FsdHNhbHRzYWx0c2FsdA==',
        }),
      );

      expect(repository.loadConfig().enabled, isTrue);
      expect(repository.verify('1234'), isFalse);
    });

    test('켜짐 값의 타입이 틀리면 켜짐', () async {
      final repository = PrefsLockRepository(
        await prefsWith({PrefsLockRepository.enabledKey: 'no'}),
      );

      expect(repository.loadConfig().enabled, isTrue);
    });

    test('해시의 타입이 틀리면 켜짐 · 검증 거절', () async {
      final repository = PrefsLockRepository(
        await prefsWith({
          PrefsLockRepository.saltKey: 'c2FsdHNhbHRzYWx0c2FsdA==',
          PrefsLockRepository.hashKey: 42,
        }),
      );

      expect(repository.loadConfig().enabled, isTrue);
      expect(repository.verify('1234'), isFalse);
    });

    test('모르는 방식 · 다시 잠그기 값은 기본값으로 읽는다', () async {
      final repository = PrefsLockRepository(
        await prefsWith({
          PrefsLockRepository.methodKey: 'face',
          PrefsLockRepository.relockKey: 'forever',
        }),
      );

      expect(repository.loadConfig(), const LockConfig());
    });

    test('시도 기록 값의 타입이 틀리면 기본값으로 읽는다', () async {
      final repository = PrefsLockRepository(
        await prefsWith({
          PrefsLockRepository.failuresKey: 'x',
          PrefsLockRepository.blockedUntilKey: 'x',
          PrefsLockRepository.longBlockKey: 'x',
        }),
      );

      expect(repository.loadAttempts(), const LockAttempts());
    });
  });
}
