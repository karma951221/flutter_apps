import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar_access.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/entity/daily_activity.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/entity/period_kind.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/alarm/page/alarm_list_page.dart';
import 'package:walk/presentation/settings/cubit/theme_cubit.dart';
import 'package:walk/presentation/settings/page/settings_page.dart';
import 'package:walk/presentation/shell/page/main_shell_page.dart';
import 'package:walk/presentation/walk/cubit/step_goal_cubit.dart';
import 'package:walk/presentation/walk/page/walk_home_page.dart';

class _MockAlarmUseCase extends Mock implements AlarmUseCase {}

class _MockWalk extends Mock implements WalkUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockSettings extends Mock implements SettingsRepository {}

class _MockHolidays extends Mock implements HolidayRefresher {}

class _MockAccess extends Mock implements HolidayCalendarAccess {}

class _FakeCalendar implements HolidayCalendar {
  @override
  HolidaySource source = const HolidaySource.bundled(firstYear: 2026, lastYear: 2027);

  @override
  String? nameOf(DateTime date) => null;
}

class _MemorySettings implements SettingsRepository {
  AppSettings value = const AppSettings();
  var saves = 0;

  @override
  AppSettings load() => value;

  @override
  Future<void> save(AppSettings settings) async {
    saves++;
    value = settings;
  }
}

void main() {
  late _MockAlarmUseCase alarms;
  late _MockWalk walk;
  late _MockRequester notification;
  late _MockHolidays holidays;
  late _MockAccess calendarAccess;
  late _FakeCalendar calendar;
  late _MemorySettings memorySettings;

  setUpAll(() => registerFallbackValue(PeriodKind.week));
  setUp(() {
    alarms = _MockAlarmUseCase();
    walk = _MockWalk();
    notification = _MockRequester();
    holidays = _MockHolidays();
    when(() => holidays.refresh(force: any(named: 'force'))).thenAnswer((_) async {});
    when(() => holidays.refresh()).thenAnswer((_) async {});
    when(() => holidays.refreshed).thenAnswer((_) => const Stream.empty());
    calendar = _FakeCalendar();
    calendarAccess = _MockAccess();
    when(calendarAccess.check).thenAnswer((_) async => PermissionStatus.denied);
    when(() => calendarAccess.refresher).thenReturn(holidays);
    memorySettings = _MemorySettings();
    final exactAlarm = _MockRequester();
    final fullScreen = _MockRequester();
    for (final r in [notification, exactAlarm, fullScreen]) {
      when(r.check).thenAnswer((_) async => PermissionStatus.granted);
    }
    when(alarms.list).thenAnswer((_) async => []);
    when(alarms.nextRings).thenAnswer((_) async => {});
    when(alarms.sync).thenAnswer((_) async {});
    when(alarms.timeZoneChanged).thenAnswer((_) async {});
    when(walk.access).thenAnswer((_) async => HealthAccess.permissionDenied);
    when(() => walk.permissionDeclinedThisSession).thenReturn(false);
    getIt
      ..registerSingleton<AlarmUseCase>(alarms)
      ..registerSingleton<WalkUseCase>(walk)
      ..registerSingleton<Clock>(Clock())
      ..registerSingleton<HolidayRefresher>(holidays)
      ..registerSingleton<HolidayCalendar>(calendar)
      ..registerSingleton<HolidayCalendarAccess>(calendarAccess)
      ..registerSingleton<SettingsRepository>(memorySettings)
      ..registerSingleton<AlarmPermissions>(
        AlarmPermissions(
          notification: notification,
          exactAlarm: exactAlarm,
          fullScreenIntent: fullScreen,
        ),
      );
  });
  tearDown(getIt.reset);

  Future<StepGoalCubit> pump(
    WidgetTester tester, {
    SettingsRepository? settings,
  }) async {
    if (settings == null) {
      final mock = _MockSettings();
      when(mock.load).thenReturn(const AppSettings());
      settings = mock;
    }
    final theme = ThemeCubit(settings);
    addTearDown(theme.close);
    final goal = StepGoalCubit(settings);
    addTearDown(goal.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: theme),
          BlocProvider.value(value: goal),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [appRouteObserver],
          home: const MainShellPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return goal;
  }

  bool onstage(Type page) =>
      find.byType(page).hitTestable().evaluate().isNotEmpty;

  testWidgets('첫 탭은 걷기, 시작할 때 예약을 동기화한다', (tester) async {
    await pump(tester);

    expect(onstage(WalkHomePage), isTrue);
    expect(onstage(AlarmListPage), isFalse);
    verify(alarms.sync).called(1);
  });

  testWidgets('탭 아이콘은 선택 시 채워진 변형을 쓴다', (tester) async {
    await pump(tester);

    final destinations = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .toList();
    IconData icon(Widget? w) => (w! as Icon).icon!;
    expect(icon(destinations[0].icon), Icons.alarm_outlined);
    expect(icon(destinations[0].selectedIcon), Icons.alarm);
    expect(icon(destinations[1].icon), Icons.directions_walk);
    expect(destinations[1].selectedIcon, isNull);
    expect(icon(destinations[2].icon), Icons.settings_outlined);
    expect(icon(destinations[2].selectedIcon), Icons.settings);
  });

  testWidgets('탭을 누르면 해당 화면으로 바뀐다', (tester) async {
    await pump(tester);

    await tester.tap(find.byIcon(Icons.alarm_outlined));
    await tester.pumpAndSettle();
    expect(onstage(AlarmListPage), isTrue);
    expect(find.text('알람이 없어요'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(onstage(SettingsPage), isTrue);
    expect(onstage(AlarmListPage), isFalse);
  });

  testWidgets('복귀하면 다시 동기화한다', (tester) async {
    await pump(tester);
    clearInteractions(alarms);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    verify(alarms.sync).called(1);
  });

  testWidgets('위에 얹힌 울림 화면이 걷히면 예약을 동기화한 뒤 목록을 다시 읽는다', (tester) async {
    await pump(tester);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const Text('ringing')),
      ),
    );
    await tester.pumpAndSettle();
    clearInteractions(alarms);

    navigator.pop();
    await tester.pumpAndSettle();

    verifyInOrder([alarms.sync, alarms.list]);
  });

  void resume(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  testWidgets('복귀하면 설정 권한 행을 다시 읽는다', (tester) async {
    when(notification.check).thenAnswer((_) async => PermissionStatus.denied);
    await pump(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    // 알림 · Health Connect 가 허용 필요.
    expect(find.text('허용 필요 ›'), findsNWidgets(2));

    // 시스템 설정에서 알림을 허용하고 돌아왔다.
    when(notification.check).thenAnswer((_) async => PermissionStatus.granted);
    resume(tester);
    await tester.pumpAndSettle();

    expect(find.text('허용 필요 ›'), findsOneWidget);
    expect(find.text('허용됨'), findsNWidgets(3));
  });

  testWidgets('설정 탭 알람 섹션: 시작 때 출처 · 캘린더 권한을 읽고, 시스템 설정에서 허용하고 돌아오면 다시 읽는다', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('내장 표 2026–2027'), findsOneWidget);
    expect(find.text('캘린더 허용 필요 ›'), findsOneWidget);
    clearInteractions(alarms);

    when(calendarAccess.check).thenAnswer((_) async => PermissionStatus.granted);
    when(() => holidays.refresh(force: true)).thenAnswer((_) async {
      calendar.source = const HolidaySource.device(calendarName: '대한민국의 휴일');
    });
    resume(tester);
    await tester.pumpAndSettle();

    expect(find.text('폰 캘린더: 대한민국의 휴일'), findsOneWidget);
    expect(find.text('캘린더 허용됨'), findsOneWidget);
    verify(() => holidays.refresh(force: true)).called(1);
  });

  testWidgets('시작 시 sync 가 끝난 뒤 목록을 읽는다', (tester) async {
    final syncing = Completer<void>();
    when(alarms.sync).thenAnswer((_) => syncing.future);
    await pump(tester);
    // sync 가 끝나기 전에 읽은 목록(첫 화면용)은 지난 1회성이 아직 켜진 목록일 수 있다.
    clearInteractions(alarms);

    syncing.complete();
    await tester.pumpAndSettle();

    verify(alarms.list).called(1);
  });

  testWidgets('예약 동기화가 실패해도 목록은 읽는다', (tester) async {
    await pump(tester);
    clearInteractions(alarms);
    when(alarms.sync).thenThrow(Exception('scheduler'));

    resume(tester);
    await tester.pumpAndSettle();

    verifyInOrder([alarms.sync, alarms.list]);
  });

  testWidgets('시작할 때 예약 동기화가 실패해도 목록 탭은 빈 목록을 보인다', (tester) async {
    when(alarms.sync).thenThrow(Exception('scheduler'));
    await pump(tester);

    await tester.tap(find.byIcon(Icons.alarm_outlined));
    await tester.pumpAndSettle();

    expect(find.text('알람이 없어요'), findsOneWidget);
  });

  /// 네이티브(시간대 변경 수신기)가 메인 엔진에 `resync` 를 부른 것처럼 보낸다. 응답 봉투를 돌려준다.
  Future<ByteData?> platformResync(WidgetTester tester) {
    const codec = StandardMethodCodec();
    final reply = Completer<ByteData?>();
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'walk/background',
      codec.encodeMethodCall(const MethodCall('resync')),
      reply.complete,
    );
    return reply.future;
  }

  testWidgets('네이티브가 resync 를 부르면 예약을 새 시간대로 다시 건 뒤 목록을 다시 읽고 응답한다', (
    tester,
  ) async {
    await pump(tester);
    clearInteractions(alarms);

    final reply = platformResync(tester);
    await tester.pumpAndSettle();

    verifyInOrder([alarms.timeZoneChanged, alarms.list]);
    final envelope = await reply;
    expect(envelope, isNotNull);
    expect(const StandardMethodCodec().decodeEnvelope(envelope!), isNull);
  });

  testWidgets('시작 · resync 때 공휴일 캐시를 먼저 새로 읽고(하루 한 번은 캐시가 판단) 예약을 채운다', (
    tester,
  ) async {
    await pump(tester);
    verifyInOrder([() => holidays.refresh(), alarms.sync]);
    clearInteractions(holidays);
    clearInteractions(alarms);

    final reply = platformResync(tester);
    await tester.pumpAndSettle();

    verifyInOrder([() => holidays.refresh(), alarms.timeZoneChanged]);
    expect(await reply, isNotNull);
  });

  testWidgets('공휴일 캐시 읽기가 실패해도 예약을 채운다', (tester) async {
    when(() => holidays.refresh()).thenThrow(Exception('calendar'));
    await pump(tester);
    verify(alarms.sync).called(1);
  });

  testWidgets('resync 중 동기화가 실패해도 목록을 읽고 응답한다', (tester) async {
    await pump(tester);
    clearInteractions(alarms);
    when(alarms.timeZoneChanged).thenThrow(Exception('scheduler'));

    final reply = platformResync(tester);
    await tester.pumpAndSettle();

    verifyInOrder([alarms.timeZoneChanged, alarms.list]);
    expect(await reply, isNotNull);
  });

  testWidgets('셸이 사라지면 resync 핸들러를 걷는다', (tester) async {
    await pump(tester);
    await tester.pumpWidget(const SizedBox());
    clearInteractions(alarms);

    final reply = platformResync(tester);
    await tester.pump();

    expect(await reply, isNull);
    verifyNever(alarms.timeZoneChanged);
  });

  /// 네이티브(미리 알림 액션 수신기)가 메인 엔진에 `reminderAction` 을 부른 것처럼 보낸다.
  Future<ByteData?> platformReminderAction(WidgetTester tester, int packageId) {
    const codec = StandardMethodCodec();
    final reply = Completer<ByteData?>();
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'walk/background',
      codec.encodeMethodCall(
        MethodCall('reminderAction', {
          'action': 'skip',
          'packageId': packageId,
        }),
      ),
      reply.complete,
    );
    return reply.future;
  }

  testWidgets('네이티브가 reminderAction 을 부르면 그 회차를 건너뛰고 목록을 다시 읽은 뒤 true 로 응답한다', (
    tester,
  ) async {
    when(() => alarms.skipOccurrence(any())).thenAnswer((_) async {});
    await pump(tester);
    clearInteractions(alarms);

    final reply = platformReminderAction(tester, 1203);
    await tester.pumpAndSettle();

    verifyInOrder([() => alarms.skipOccurrence(1203), alarms.list]);
    final envelope = await reply;
    expect(const StandardMethodCodec().decodeEnvelope(envelope!), isTrue);
  });

  testWidgets('reminderAction 의 건너뛰기가 실패하면 목록은 읽고 false 로 응답한다(알림을 남긴다)', (
    tester,
  ) async {
    when(() => alarms.skipOccurrence(any())).thenThrow(Exception('scheduler'));
    await pump(tester);
    clearInteractions(alarms);

    final reply = platformReminderAction(tester, 1203);
    await tester.pumpAndSettle();

    verify(alarms.list).called(1);
    final envelope = await reply;
    expect(const StandardMethodCodec().decodeEnvelope(envelope!), isFalse);
  });

  testWidgets('설정 탭에서 목표를 낮춰 달성해도 걷기 탭을 열 때 한 번만 축하한다', (tester) async {
    final settings = memorySettings;
    when(walk.access).thenAnswer((_) async => HealthAccess.granted);
    when(walk.today).thenAnswer(
      (_) async => Ok(DailyActivity(date: DateTime(2026, 9, 23), steps: 6240)),
    );
    when(
      () => walk.period(any(), any()),
    ).thenAnswer((_) async => const Err(Failure.unknown()));
    var celebrations = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.mediumImpact') {
          celebrations++;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final goal = await pump(tester, settings: settings);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // 설정 탭의 목표 시트가 고른 값을 반영한 것과 같다.
    await goal.select(6000);
    await tester.pumpAndSettle();

    expect(celebrations, 0);
    expect(settings.value.goalCelebratedOn, isNull);
    expect(settings.value.stepGoal, 6000);

    await tester.tap(find.byIcon(Icons.directions_walk));
    await tester.pumpAndSettle();

    expect(celebrations, 1);
    expect(settings.value.goalCelebratedOn, DateTime(2026, 9, 23));
    expect(settings.value.stepGoal, 6000);
  });
}
