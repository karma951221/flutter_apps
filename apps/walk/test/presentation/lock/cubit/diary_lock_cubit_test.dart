import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_attempts.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_policy.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_state.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

void main() {
  late SharedPreferences prefs;
  late PrefsLockRepository repo;
  late FakeDeviceAuth auth;
  late MutableClock clock;
  late MediaPickGuard guard;

  DiaryLockCubit newCubit() => DiaryLockCubit(repo, auth, clock, guard);

  Future<void> enableLock({
    LockMethod method = LockMethod.pin,
    String secret = '1234',
    RelockDelay delay = RelockDelay.minute1,
  }) async {
    await repo.setSecret(method, secret);
    await repo.saveConfig(
      LockConfig(enabled: true, method: method, relockDelay: delay),
    );
  }

  /// [cubit] 를 잠금 해제된 상태로 만든다.
  Future<DiaryLockCubit> unlocked() async {
    final cubit = newCubit()..start();
    await cubit.submit('1234');
    expect(cubit.state, const DiaryLockState.unlocked());
    return cubit;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = PrefsLockRepository(prefs);
    auth = FakeDeviceAuth();
    clock = MutableClock(diaryT0);
    guard = MediaPickGuard();
  });

  group('start', () {
    blocTest<DiaryLockCubit, DiaryLockState>(
      '잠금이 꺼져 있으면 unlocked',
      build: newCubit,
      act: (c) => c.start(),
      expect: () => [const DiaryLockState.unlocked()],
    );

    blocTest<DiaryLockCubit, DiaryLockState>(
      '켜져 있으면 설정한 방식으로 locked',
      setUp: () => enableLock(method: LockMethod.pattern, secret: '0-1-2-5'),
      build: newCubit,
      act: (c) => c.start(),
      verify: (c) => expect(
        c.state,
        const DiaryLockState.locked(method: LockMethod.pattern),
      ),
    );
  });

  group('submit', () {
    setUp(enableLock);

    blocTest<DiaryLockCubit, DiaryLockState>(
      '맞으면 unlocked · 실패 횟수 0',
      setUp: () => repo.saveAttempts(const LockAttempts(failures: 3)),
      build: newCubit,
      act: (c) async {
        c.start();
        await c.submit('1234');
      },
      expect: () => [
        const DiaryLockState.locked(method: LockMethod.pin),
        const DiaryLockState.unlocked(),
      ],
      verify: (_) => expect(repo.loadAttempts(), const LockAttempts()),
    );

    blocTest<DiaryLockCubit, DiaryLockState>(
      '틀리면 wrong 으로 locked 유지',
      build: newCubit,
      act: (c) async {
        c.start();
        await c.submit('0000');
      },
      expect: () => [
        const DiaryLockState.locked(method: LockMethod.pin),
        const DiaryLockState.locked(method: LockMethod.pin, wrong: true),
      ],
      verify: (_) => expect(repo.loadAttempts().failures, 1),
    );

    test('5회째 틀리면 30초 차단', () async {
      final cubit = newCubit()..start();
      for (var i = 0; i < 4; i++) {
        await cubit.submit('0000');
      }
      expect((cubit.state as LockLocked).blockedFor, isNull);

      await cubit.submit('0000');

      expect(
        cubit.state,
        const DiaryLockState.locked(
          method: LockMethod.pin,
          wrong: true,
          blockedFor: LockPolicy.shortBlock,
        ),
      );
      await cubit.close();
    });

    test('차단 중에는 맞는 비밀도 무시하고 차단을 늘리지 않는다', () async {
      await repo.saveAttempts(
        LockAttempts(blockedUntil: diaryT0.add(const Duration(seconds: 20))),
      );
      final cubit = newCubit()..start();
      clock.advance(const Duration(seconds: 5));

      await cubit.submit('1234');
      await cubit.submit('0000');

      expect(
        cubit.state,
        const DiaryLockState.locked(
          method: LockMethod.pin,
          blockedFor: Duration(seconds: 15),
        ),
      );
      expect(
        repo.loadAttempts().blockedUntil,
        diaryT0.add(const Duration(seconds: 20)),
      );
      await cubit.close();
    });

    test('24시간 차단 중 틀려도 30초 차단으로 덮어쓰지 않는다', () async {
      await repo.saveAttempts(LockPolicy.deviceAuthFailed(diaryT0));
      final cubit = newCubit()..start();

      await cubit.submit('0000');

      expect(repo.loadAttempts(), LockPolicy.deviceAuthFailed(diaryT0));
      expect((cubit.state as LockLocked).longBlock, isTrue);
      await cubit.close();
    });

    test('차단이 끝나면 다시 풀 수 있다', () async {
      final cubit = newCubit()..start();
      for (var i = 0; i < 5; i++) {
        await cubit.submit('0000');
      }
      clock.advance(LockPolicy.shortBlock);

      await cubit.submit('1234');

      expect(cubit.state, const DiaryLockState.unlocked());
      await cubit.close();
    });

    test('재시작(새 cubit · 같은 prefs)해도 차단이 남는다', () async {
      final first = newCubit()..start();
      for (var i = 0; i < 5; i++) {
        await first.submit('0000');
      }
      await first.close();
      clock.advance(const Duration(seconds: 10));

      final restarted = DiaryLockCubit(
        PrefsLockRepository(await SharedPreferences.getInstance()),
        auth,
        clock,
        guard,
      )..start();

      expect(
        restarted.state,
        const DiaryLockState.locked(
          method: LockMethod.pin,
          blockedFor: Duration(seconds: 20),
        ),
      );
      await restarted.submit('1234');
      expect(restarted.state, isA<LockLocked>());
      await restarted.close();
    });

    test('24시간 차단도 재시작 뒤 longBlock 으로 남는다', () async {
      await repo.saveAttempts(LockPolicy.deviceAuthFailed(diaryT0));
      clock.advance(const Duration(hours: 1));

      final cubit = newCubit()..start();

      expect(
        cubit.state,
        const DiaryLockState.locked(
          method: LockMethod.pin,
          blockedFor: Duration(hours: 23),
          longBlock: true,
        ),
      );
      await cubit.close();
    });
  });

  group('tick', () {
    setUp(enableLock);

    test('남은 시간을 줄이고 끝나면 차단 표시를 지운다', () async {
      await repo.saveAttempts(
        LockAttempts(blockedUntil: diaryT0.add(const Duration(seconds: 30))),
      );
      final cubit = newCubit()..start();

      clock.advance(const Duration(seconds: 1));
      cubit.tick();
      expect(
        (cubit.state as LockLocked).blockedFor,
        const Duration(seconds: 29),
      );

      clock.advance(const Duration(seconds: 29));
      cubit.tick();
      expect(cubit.state, const DiaryLockState.locked(method: LockMethod.pin));
      await cubit.close();
    });
  });

  group('forgot', () {
    setUp(enableLock);

    test('폰 인증 성공 → resetting · 실패 횟수 0', () async {
      await repo.saveAttempts(const LockAttempts(failures: 2));
      final cubit = newCubit()..start();

      await cubit.forgot('reason');

      expect(cubit.state, const DiaryLockState.resetting());
      expect(repo.loadAttempts(), const LockAttempts());
      await cubit.close();
    });

    for (final result in [
      DeviceAuthResult.failed,
      DeviceAuthResult.lockedOut,
    ]) {
      test('폰 인증 $result → 24시간 longBlock', () async {
        auth.result = result;
        final cubit = newCubit()..start();

        await cubit.forgot('reason');

        expect(
          cubit.state,
          const DiaryLockState.locked(
            method: LockMethod.pin,
            blockedFor: LockPolicy.longBlock,
            longBlock: true,
          ),
        );
        expect(repo.loadAttempts(), LockPolicy.deviceAuthFailed(diaryT0));
        await cubit.close();
      });
    }

    test('취소하면 locked 그대로 · 차단 없음', () async {
      auth.result = DeviceAuthResult.canceled;
      final cubit = newCubit()..start();

      await cubit.forgot('reason');

      expect(cubit.state, const DiaryLockState.locked(method: LockMethod.pin));
      expect(repo.loadAttempts(), const LockAttempts());
      await cubit.close();
    });

    test('폰 인증을 쓸 수 없으면 안내만 하고 차단하지 않는다', () async {
      auth.result = DeviceAuthResult.unavailable;
      final cubit = newCubit()..start();

      await cubit.forgot('reason');

      expect(
        cubit.state,
        const DiaryLockState.locked(
          method: LockMethod.pin,
          deviceUnavailable: true,
        ),
      );
      expect(repo.loadAttempts(), const LockAttempts());
      await cubit.close();
    });

    test('차단 중이면 폰 인증을 띄우지 않는다', () async {
      await repo.saveAttempts(
        LockAttempts(blockedUntil: diaryT0.add(LockPolicy.shortBlock)),
      );
      final cubit = newCubit()..start();

      await cubit.forgot('reason');

      expect(auth.calls, 0);
      expect(cubit.state, isA<LockLocked>());
      await cubit.close();
    });

    test('finishReset → 새 비밀 · 방식 저장 후 unlocked', () async {
      final cubit = newCubit()..start();
      await cubit.forgot('reason');

      await cubit.finishReset(LockMethod.pattern, '0-1-2-5');

      expect(cubit.state, const DiaryLockState.unlocked());
      expect(repo.verify('0-1-2-5'), isTrue);
      expect(repo.verify('1234'), isFalse);
      expect(
        repo.loadConfig(),
        const LockConfig(enabled: true, method: LockMethod.pattern),
      );
      await cubit.close();
    });

    test('resetting 이 아니면 finishReset 은 아무것도 하지 않는다', () async {
      final cubit = newCubit()..start();

      await cubit.finishReset(LockMethod.pin, '9999');

      expect(repo.verify('1234'), isTrue);
      expect(cubit.state, isA<LockLocked>());
      await cubit.close();
    });
  });

  group('다시 잠그기', () {
    setUp(enableLock);

    test('1분 설정에서 70초 뒤 돌아오면 locked', () async {
      final cubit = await unlocked();

      cubit.onPaused();
      clock.advance(const Duration(seconds: 70));
      cubit.onResumed();

      expect(cubit.state, const DiaryLockState.locked(method: LockMethod.pin));
      await cubit.close();
    });

    test('1분 설정에서 50초 뒤 돌아오면 unlocked', () async {
      final cubit = await unlocked();

      cubit.onPaused();
      clock.advance(const Duration(seconds: 50));
      cubit.onResumed();

      expect(cubit.state, const DiaryLockState.unlocked());
      await cubit.close();
    });

    test('미디어 선택 중이면 3분 뒤 돌아와도 unlocked', () async {
      final cubit = await unlocked();
      final pick = Completer<void>();
      final picking = guard.run(() => pick.future);

      cubit.onPaused();
      clock.advance(const Duration(minutes: 3));
      pick.complete();
      await picking;
      cubit.onResumed();

      expect(cubit.state, const DiaryLockState.unlocked());
      await cubit.close();
    });

    test('미디어 선택이 끝난 뒤의 백그라운드는 다시 센다', () async {
      final cubit = await unlocked();
      await guard.run(() async {
        cubit.onPaused();
        cubit.onResumed();
      });

      cubit.onPaused();
      clock.advance(const Duration(minutes: 3));
      cubit.onResumed();

      expect(cubit.state, isA<LockLocked>());
      await cubit.close();
    });

    test('시계가 거꾸로 가면 locked', () async {
      final cubit = await unlocked();

      cubit.onPaused();
      clock.advance(const Duration(seconds: -1));
      cubit.onResumed();

      expect(cubit.state, isA<LockLocked>());
      await cubit.close();
    });

    test('잠금이 꺼져 있으면 오래 지나도 unlocked', () async {
      await repo.saveConfig(const LockConfig());
      final cubit = newCubit()..start();

      cubit.onPaused();
      clock.advance(const Duration(hours: 1));
      cubit.onResumed();

      expect(cubit.state, const DiaryLockState.unlocked());
      await cubit.close();
    });

    test('pause 없이 resume 만 오면 그대로', () async {
      final cubit = await unlocked();
      clock.advance(const Duration(hours: 1));

      cubit.onResumed();

      expect(cubit.state, const DiaryLockState.unlocked());
      await cubit.close();
    });
  });
}
