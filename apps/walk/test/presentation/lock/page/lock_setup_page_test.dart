import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/lock/page/lock_setup_page.dart';
import 'package:walk/presentation/lock/widget/pattern_lock.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

void main() {
  late PrefsLockRepository repo;
  late FakeDeviceAuth auth;
  late List<Object?> results;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = PrefsLockRepository(await SharedPreferences.getInstance());
    auth = FakeDeviceAuth();
    results = [];
    getIt
      ..registerSingleton<LockRepository>(repo)
      ..registerSingleton<DeviceAuth>(auth)
      ..registerSingleton<Clock>(MutableClock(diaryT0));
  });

  tearDown(getIt.reset);

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: AppButton.primary(
              label: 'open',
              onPressed: () async => results.add(
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const LockSetupPage()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.widgetWithText(TextButton, d));
      await tester.pump();
    }
    await tester.pump();
    await tester.pump();
  }

  testWidgets('폰 화면 잠금이 없으면 켤 수 없다고 안내한다', (tester) async {
    auth.screenLock = false;
    await open(tester);

    expect(find.text('폰 화면 잠금을 먼저 설정해야 일기 잠금을 켤 수 있어요'), findsOneWidget);
    expect(find.text('PIN 4자리'), findsNothing);
  });

  testWidgets('PIN 두 번 → 저장 알림과 함께 true 로 닫힌다', (tester) async {
    await open(tester);
    expect(find.text('잠금 끄기'), findsNothing);

    await tester.tap(find.text('PIN 4자리'));
    await tester.pump();
    expect(find.text('새 PIN 4자리를 입력하세요'), findsOneWidget);
    await typePin(tester, '2580');
    expect(find.text('확인을 위해 한 번 더 입력하세요'), findsOneWidget);
    await typePin(tester, '2580');
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(find.text('일기 잠금 설정을 저장했어요'), findsOneWidget);
    expect(repo.verify('2580'), isTrue);
    expect(repo.loadConfig().enabled, isTrue);
  });

  testWidgets('확인 입력이 다르면 오류 문구', (tester) async {
    await open(tester);
    await tester.tap(find.text('PIN 4자리'));
    await tester.pump();

    await typePin(tester, '2580');
    await typePin(tester, '0852');

    expect(find.text('처음 입력과 달라요. 처음부터 다시 입력하세요'), findsOneWidget);
    expect(find.text('새 PIN 4자리를 입력하세요'), findsOneWidget);
  });

  testWidgets('패턴을 고르면 패턴 입력을 보인다', (tester) async {
    await open(tester);

    await tester.tap(find.text('패턴'));
    await tester.pump();

    expect(find.byType(PatternLock), findsOneWidget);
    expect(find.text('점 4개 이상을 이어 새 패턴을 그리세요'), findsOneWidget);
  });

  testWidgets('켜져 있으면 현재 PIN 확인 뒤 끌 수 있다', (tester) async {
    await repo.setSecret(LockMethod.pin, '1234');
    await repo.saveConfig(const LockConfig(enabled: true));
    await open(tester);
    expect(find.text('지금 쓰는 PIN · 패턴을 입력하세요'), findsOneWidget);
    expect(find.text('잠금 끄기'), findsNothing);

    await typePin(tester, '0000');
    expect(find.text('맞지 않아요. 다시 해 보세요'), findsOneWidget);

    await typePin(tester, '1234');
    expect(find.text('PIN 4자리 (사용 중)'), findsOneWidget);
    await tester.tap(find.text('잠금 끄기'));
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(repo.loadConfig().enabled, isFalse);
    expect(repo.hasSecret, isFalse);
  });
}
