import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/lock/lock_attempts.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_policy.dart';
import 'package:walk/presentation/lock/cubit/lock_setup_cubit.dart';
import 'package:walk/presentation/lock/cubit/lock_setup_state.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

void main() {
  late PrefsLockRepository repo;
  late FakeDeviceAuth auth;
  late MutableClock clock;
  late LockSetupCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = PrefsLockRepository(await SharedPreferences.getInstance());
    auth = FakeDeviceAuth();
    clock = MutableClock(diaryT0);
    cubit = LockSetupCubit(repo, auth, clock);
  });

  tearDown(() => cubit.close());

  Future<void> enableLock({
    LockMethod method = LockMethod.pin,
    String secret = '1234',
  }) async {
    await repo.setSecret(method, secret);
    await repo.saveConfig(
      LockConfig(
        enabled: true,
        method: method,
        relockDelay: RelockDelay.minutes5,
      ),
    );
  }

  group('켜기', () {
    test('폰 화면 잠금이 없으면 needsScreenLock', () async {
      auth.screenLock = false;

      await cubit.start();

      expect(cubit.state, const LockSetupState.needsScreenLock());
    });

    test('꺼져 있으면 방식 고르기(끄기 없음)', () async {
      await cubit.start();

      expect(cubit.state, const LockSetupState.choosing());
    });

    test('PIN 두 번 같게 입력하면 켜고 저장한다', () async {
      await cubit.start();
      cubit.choose(LockMethod.pin);
      expect(
        cubit.state,
        const LockSetupState.entering(method: LockMethod.pin),
      );

      await cubit.enter('2580');
      expect(
        cubit.state,
        const LockSetupState.entering(method: LockMethod.pin, confirming: true),
      );
      await cubit.enter('2580');

      expect(cubit.state, const LockSetupState.done());
      expect(repo.verify('2580'), isTrue);
      expect(repo.loadConfig().enabled, isTrue);
      expect(repo.loadConfig().method, LockMethod.pin);
    });

    test('확인 입력이 다르면 mismatch 로 처음부터', () async {
      await cubit.start();
      cubit.choose(LockMethod.pin);
      await cubit.enter('2580');

      await cubit.enter('2581');

      expect(
        cubit.state,
        const LockSetupState.entering(
          method: LockMethod.pin,
          error: LockSetupError.mismatch,
        ),
      );
      expect(repo.hasSecret, isFalse);
      expect(repo.loadConfig().enabled, isFalse);

      await cubit.enter('1111');
      await cubit.enter('1111');
      expect(repo.verify('1111'), isTrue);
    });

    test('패턴 3점 이하는 tooShort 로 거절', () async {
      await cubit.start();
      cubit.choose(LockMethod.pattern);

      await cubit.enter('0-1-2');

      expect(
        cubit.state,
        const LockSetupState.entering(
          method: LockMethod.pattern,
          error: LockSetupError.tooShort,
        ),
      );
    });

    test('4자리가 아닌 PIN 은 tooShort 로 거절', () async {
      await cubit.start();
      cubit.choose(LockMethod.pin);

      await cubit.enter('123');

      expect((cubit.state as SetupEntering).error, LockSetupError.tooShort);
    });

    test('패턴 4점은 받아 저장한다', () async {
      await cubit.start();
      cubit.choose(LockMethod.pattern);
      await cubit.enter('0-1-2-5');
      await cubit.enter('0-1-2-5');

      expect(cubit.state, const LockSetupState.done());
      expect(repo.verify('0-1-2-5'), isTrue);
      expect(repo.loadConfig().method, LockMethod.pattern);
    });

    test('켤 때 다시 잠기는 시간은 그대로 둔다', () async {
      await repo.saveConfig(
        const LockConfig(relockDelay: RelockDelay.seconds30),
      );
      await cubit.start();
      cubit.choose(LockMethod.pin);
      await cubit.enter('2580');
      await cubit.enter('2580');

      expect(repo.loadConfig().relockDelay, RelockDelay.seconds30);
    });
  });

  group('켜져 있을 때', () {
    setUp(() => enableLock());

    test('먼저 현재 비밀을 확인한다', () async {
      await cubit.start();

      expect(
        cubit.state,
        const LockSetupState.verifying(method: LockMethod.pin),
      );
    });

    test('확인 전에는 끄기 · 방식 변경을 받지 않는다', () async {
      await cubit.start();

      await cubit.turnOff();
      cubit.choose(LockMethod.pattern);

      expect(cubit.state, isA<SetupVerifying>());
      expect(repo.loadConfig().enabled, isTrue);
    });

    test('틀리면 wrong · 실패 횟수가 잠금 화면과 같이 쌓인다', () async {
      await cubit.start();

      await cubit.verifyCurrent('0000');

      expect(
        cubit.state,
        const LockSetupState.verifying(method: LockMethod.pin, wrong: true),
      );
      expect(repo.loadAttempts().failures, 1);
    });

    test('5회째 틀리면 30초 차단 · 차단 중 맞는 비밀도 무시', () async {
      await cubit.start();
      for (var i = 0; i < 5; i++) {
        await cubit.verifyCurrent('0000');
      }
      expect((cubit.state as SetupVerifying).blockedFor, LockPolicy.shortBlock);

      await cubit.verifyCurrent('1234');

      expect(cubit.state, isA<SetupVerifying>());
    });

    test('24시간 차단 중이면 확인을 받지 않고 덮어쓰지 않는다', () async {
      await repo.saveAttempts(LockPolicy.deviceAuthFailed(diaryT0));
      await cubit.start();

      await cubit.verifyCurrent('0000');

      expect(repo.loadAttempts(), LockPolicy.deviceAuthFailed(diaryT0));
      expect(
        cubit.state,
        const LockSetupState.verifying(
          method: LockMethod.pin,
          blockedFor: LockPolicy.longBlock,
          longBlock: true,
        ),
      );
    });

    test('맞으면 현재 방식 표시 + 끄기 가능한 고르기 · 실패 횟수 0', () async {
      await repo.saveAttempts(const LockAttempts(failures: 2));
      await cubit.start();

      await cubit.verifyCurrent('1234');

      expect(
        cubit.state,
        const LockSetupState.choosing(
          current: LockMethod.pin,
          canTurnOff: true,
        ),
      );
      expect(repo.loadAttempts(), const LockAttempts());
    });

    test('끄기 → 비밀을 지우고 꺼짐 저장 · 다시 잠기는 시간 유지', () async {
      await cubit.start();
      await cubit.verifyCurrent('1234');

      await cubit.turnOff();

      expect(cubit.state, const LockSetupState.done());
      expect(repo.hasSecret, isFalse);
      expect(repo.loadConfig().enabled, isFalse);
      expect(repo.loadConfig().relockDelay, RelockDelay.minutes5);
    });

    test('방식 변경 → 새 패턴 두 번 → 패턴으로 저장', () async {
      await cubit.start();
      await cubit.verifyCurrent('1234');
      cubit.choose(LockMethod.pattern);
      await cubit.enter('0-4-8-5');
      await cubit.enter('0-4-8-5');

      expect(cubit.state, const LockSetupState.done());
      expect(repo.verify('0-4-8-5'), isTrue);
      expect(repo.verify('1234'), isFalse);
      expect(
        repo.loadConfig(),
        const LockConfig(
          enabled: true,
          method: LockMethod.pattern,
          relockDelay: RelockDelay.minutes5,
        ),
      );
    });
  });

  group('재설정(폰 인증 뒤)', () {
    test('확인 없이 고르기 → 두 번 입력 → onSave 로 넘기고 직접 저장하지 않는다', () async {
      await enableLock();
      LockMethod? savedMethod;
      String? savedSecret;

      cubit.startReset((method, secret) async {
        savedMethod = method;
        savedSecret = secret;
      });
      expect(cubit.state, const LockSetupState.choosing());

      cubit.choose(LockMethod.pin);
      await cubit.enter('9999');
      await cubit.enter('9999');

      expect(cubit.state, const LockSetupState.done());
      expect(savedMethod, LockMethod.pin);
      expect(savedSecret, '9999');
      expect(repo.verify('1234'), isTrue);
    });
  });

  group('recheck', () {
    test('화면 잠금이 생기면 방식 고르기로 넘어간다', () async {
      auth.screenLock = false;
      await cubit.start();
      expect(cubit.state, isA<SetupNeedsScreenLock>());

      auth.screenLock = true;
      await cubit.recheck();

      expect(cubit.state, isA<SetupChoosing>());
    });

    test('여전히 없으면 그대로 둔다', () async {
      auth.screenLock = false;
      await cubit.start();
      await cubit.recheck();

      expect(cubit.state, isA<SetupNeedsScreenLock>());
    });

    test('다른 단계에서는 건드리지 않는다', () async {
      await cubit.start();
      cubit.choose(LockMethod.pin);
      await cubit.recheck();

      expect(cubit.state, isA<SetupEntering>());
    });
  });
}
