import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/entity/activity_period.dart';
import 'package:walk/domain/entity/daily_activity.dart';
import 'package:walk/domain/entity/health_access.dart';
import 'package:walk/domain/entity/period_kind.dart';
import 'package:walk/domain/usecase/walk_use_case.dart';
import 'package:walk/presentation/page/walk_home_page.dart';

class _MockUseCase extends Mock implements WalkUseCase {}

ActivityPeriod _period(PeriodKind kind) => ActivityPeriod(
  kind: kind,
  start: DateTime(2026, 9, 21),
  end: DateTime(2026, 9, 27),
  today: DateTime(2026, 9, 23),
  days: [
    DailyActivity(date: DateTime(2026, 9, 21), steps: 1000),
    for (var d = 22; d <= 27; d++) DailyActivity.empty(DateTime(2026, 9, d)),
  ],
);

void main() {
  late _MockUseCase useCase;

  setUpAll(() => registerFallbackValue(PeriodKind.week));
  setUp(() {
    useCase = _MockUseCase();
    getIt.registerSingleton<WalkUseCase>(useCase);
    when(() => useCase.permissionDeclinedThisSession).thenReturn(false);
    when(() => useCase.today()).thenAnswer(
      (_) async => Ok(
        DailyActivity(
          date: DateTime(2026, 9, 23),
          steps: 6240,
          distanceMeters: 4310,
        ),
      ),
    );
    when(() => useCase.period(any(), any())).thenAnswer(
      (i) async => Ok(_period(i.positionalArguments[0] as PeriodKind)),
    );
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WalkHomePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('권한이 있으면 오늘 걸음 · 거리 · 없는 칼로리 – 를 보여준다', (tester) async {
    when(() => useCase.access()).thenAnswer((_) async => HealthAccess.granted);
    await pump(tester);

    expect(find.text('6,240 걸음'), findsOneWidget);
    expect(find.text('4.3 km'), findsWidgets);
    expect(find.text('–'), findsWidgets);
    expect(find.text('주간'), findsOneWidget);
    expect(find.text('월간'), findsOneWidget);
  });

  testWidgets('현재 기간이면 다음 버튼이 꺼져 있다', (tester) async {
    when(() => useCase.access()).thenAnswer((_) async => HealthAccess.granted);
    await pump(tester);

    final next = tester.widget<IconButton>(
      find.byKey(const Key('walk-period-next')),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('월간 탭을 누르면 월간 기간을 보여준다', (tester) async {
    when(() => useCase.access()).thenAnswer((_) async => HealthAccess.granted);
    await pump(tester);
    expect(find.text('9월 21일 – 9월 27일'), findsOneWidget);

    await tester.tap(find.text('월간'));
    await tester.pumpAndSettle();

    expect(find.text('2026년 9월'), findsOneWidget);
  });

  testWidgets('권한이 없으면 안내하고, 누르면 요청한다', (tester) async {
    when(
      () => useCase.access(),
    ).thenAnswer((_) async => HealthAccess.permissionDenied);
    when(
      () => useCase.requestAccess(),
    ).thenAnswer((_) async => HealthAccess.granted);
    await pump(tester);

    expect(find.text('걸음 기록을 읽을 권한이 필요해요'), findsOneWidget);
    await tester.tap(find.text('권한 허용'));
    await tester.pumpAndSettle();

    expect(find.text('6,240 걸음'), findsOneWidget);
  });

  testWidgets('거부 기록이 없으면 설정 열기가 없다', (tester) async {
    when(
      () => useCase.access(),
    ).thenAnswer((_) async => HealthAccess.permissionDenied);
    await pump(tester);

    expect(find.text('권한 허용'), findsOneWidget);
    expect(find.text('설정 열기'), findsNothing);
  });

  testWidgets('이번 세션에 거부했으면 설정 열기를 함께 보이고, 누르면 설정을 연다', (tester) async {
    when(
      () => useCase.access(),
    ).thenAnswer((_) async => HealthAccess.permissionDenied);
    when(() => useCase.permissionDeclinedThisSession).thenReturn(true);
    when(() => useCase.openPermissionSettings()).thenAnswer((_) async {});
    await pump(tester);

    await tester.tap(find.text('설정 열기'));
    verify(() => useCase.openPermissionSettings()).called(1);
  });

  testWidgets('Health Connect 가 없으면 설치를 안내한다', (tester) async {
    when(
      () => useCase.access(),
    ).thenAnswer((_) async => HealthAccess.notInstalled);
    when(() => useCase.openInstall()).thenAnswer((_) async {});
    await pump(tester);

    await tester.tap(find.text('설치하기'));
    verify(() => useCase.openInstall()).called(1);
  });

  testWidgets('오늘 읽기 실패는 재시도를 준다', (tester) async {
    when(() => useCase.access()).thenAnswer((_) async => HealthAccess.granted);
    when(
      () => useCase.today(),
    ).thenAnswer((_) async => const Err(Failure.unknown()));
    await pump(tester);

    expect(find.text('기록을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  Future<void> resume(WidgetTester tester) async {
    // AppLifecycleListener 는 실제 전이 순서만 받는다: 백그라운드로 갔다가 돌아온다.
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('복귀하면 접근을 다시 확인하고 새로 읽는다', (tester) async {
    when(() => useCase.access()).thenAnswer((_) async => HealthAccess.granted);
    await pump(tester);
    expect(find.text('6,240 걸음'), findsOneWidget);

    when(() => useCase.today()).thenAnswer(
      (_) async => Ok(DailyActivity(date: DateTime(2026, 9, 23), steps: 7000)),
    );
    await resume(tester);

    verify(() => useCase.access()).called(2);
    expect(find.text('7,000 걸음'), findsOneWidget);
  });

  testWidgets('복귀해서 권한이 생기면 한 번만 읽는다', (tester) async {
    var access = HealthAccess.permissionDenied;
    when(() => useCase.access()).thenAnswer((_) async => access);
    await pump(tester);
    verifyNever(() => useCase.today());

    access = HealthAccess.granted;
    await resume(tester);

    expect(find.text('6,240 걸음'), findsOneWidget);
    verify(() => useCase.today()).called(1);
    verify(() => useCase.period(PeriodKind.week, any())).called(1);
    verify(() => useCase.period(PeriodKind.month, any())).called(1);
  });
}
