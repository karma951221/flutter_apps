import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_attempts.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_policy.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/lock/widget/diary_lock_gate.dart';
import 'package:walk/presentation/lock/widget/pattern_lock.dart';
import 'package:walk/presentation/lock/widget/pin_pad.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

void main() {
  const childKey = ValueKey('diary-content');
  late PrefsLockRepository repo;
  late FakeDeviceAuth auth;
  late MutableClock clock;
  late DiaryLockCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = PrefsLockRepository(await SharedPreferences.getInstance());
    auth = FakeDeviceAuth();
    clock = MutableClock(diaryT0);
    cubit = DiaryLockCubit(repo, auth, clock, MediaPickGuard());
    getIt
      ..registerSingleton<LockRepository>(repo)
      ..registerSingleton<DeviceAuth>(auth)
      ..registerSingleton<Clock>(clock);
  });

  tearDown(() async {
    await cubit.close();
    await getIt.reset();
  });

  Future<void> enableLock({
    LockMethod method = LockMethod.pin,
    String secret = '1234',
  }) async {
    await repo.setSecret(method, secret);
    await repo.saveConfig(LockConfig(enabled: true, method: method));
  }

  Future<void> pump(WidgetTester tester) async {
    cubit.start();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const DiaryLockGate(child: Text('기록', key: childKey)),
          ),
        ),
      ),
    );
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.widgetWithText(TextButton, d));
      await tester.pump();
    }
    // 저장소 쓰기(비동기)가 끝나고 상태가 바뀔 때까지.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('잠금이 꺼져 있으면 기록이 보인다', (tester) async {
    await pump(tester);

    expect(find.byKey(childKey), findsOneWidget);
  });

  testWidgets('잠겨 있으면 기록 위젯이 트리에 없다', (tester) async {
    await enableLock();
    await pump(tester);

    // 가려진(Offstage) 것도 아니고 트리에 아예 없다.
    expect(find.byKey(childKey, skipOffstage: false), findsNothing);
    expect(find.text('일기가 잠겨 있어요'), findsOneWidget);
    expect(find.byType(PinPad), findsOneWidget);
  });

  testWidgets('패턴 방식이면 패턴 입력을 보인다', (tester) async {
    await enableLock(method: LockMethod.pattern, secret: '0-1-2-5');
    await pump(tester);

    expect(find.byType(PatternLock), findsOneWidget);
    expect(find.byType(PinPad), findsNothing);
  });

  testWidgets('맞는 PIN 이면 기록이 나타난다', (tester) async {
    await enableLock();
    await pump(tester);

    await typePin(tester, '1234');

    expect(find.byKey(childKey), findsOneWidget);
  });

  testWidgets('틀리면 안내하고 잠긴 채', (tester) async {
    await enableLock();
    await pump(tester);

    await typePin(tester, '0000');

    expect(find.text('맞지 않아요. 다시 해 보세요'), findsOneWidget);
    expect(find.byKey(childKey), findsNothing);
  });

  testWidgets('30초 차단 중이면 남은 초를 1초마다 줄이고 입력을 막는다', (tester) async {
    await enableLock();
    await repo.saveAttempts(
      LockAttempts(blockedUntil: diaryT0.add(LockPolicy.shortBlock)),
    );
    await pump(tester);
    expect(find.text('30초 뒤에 다시 시도할 수 있어요'), findsOneWidget);

    clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('29초 뒤에 다시 시도할 수 있어요'), findsOneWidget);

    final pad = tester.widget<PinPad>(find.byType(PinPad));
    expect(pad.enabled, isFalse);
  });

  testWidgets('24시간 차단이면 남은 시간 · 분을 보인다', (tester) async {
    await enableLock();
    await repo.saveAttempts(LockPolicy.deviceAuthFailed(diaryT0));
    clock.advance(const Duration(minutes: 90));
    await pump(tester);

    expect(find.text('폰 인증에 실패했어요. 22시간 30분 뒤에 다시 시도할 수 있어요'), findsOneWidget);
  });

  testWidgets('잊어버렸어요 → 폰 인증 성공 → 새 PIN 두 번 → 기록이 나타난다', (tester) async {
    await enableLock();
    await pump(tester);

    await tester.tap(find.text('잊어버렸어요'));
    await tester.pump();
    await tester.pump();
    expect(find.text('잠금 방식을 고르세요'), findsOneWidget);
    expect(find.text('잠금 끄기'), findsNothing);
    expect(find.byKey(childKey), findsNothing);

    await tester.tap(find.text('PIN 4자리'));
    await tester.pump();
    await typePin(tester, '9876');
    expect(find.text('확인을 위해 한 번 더 입력하세요'), findsOneWidget);
    await typePin(tester, '9876');

    expect(find.byKey(childKey), findsOneWidget);
    expect(repo.verify('9876'), isTrue);
  });

  testWidgets('폰 인증을 쓸 수 없으면 안내한다', (tester) async {
    auth.result = DeviceAuthResult.unavailable;
    await enableLock();
    await pump(tester);

    await tester.tap(find.text('잊어버렸어요'));
    await tester.pump();
    await tester.pump();

    expect(find.text('지금은 폰 인증을 쓸 수 없어요. 폰 화면 잠금 설정을 확인해 주세요'), findsOneWidget);
  });
}
