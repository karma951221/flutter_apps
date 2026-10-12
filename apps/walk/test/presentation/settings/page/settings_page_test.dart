import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar_access.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/diary/entity/diary_usage.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_state.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/lock/page/lock_setup_page.dart';
import 'package:walk/presentation/lock/widget/pattern_lock.dart';
import 'package:walk/presentation/settings/cubit/diary_settings_cubit.dart';
import 'package:walk/presentation/settings/cubit/holiday_settings_cubit.dart';
import 'package:walk/presentation/settings/cubit/settings_permissions_cubit.dart';
import 'package:walk/presentation/settings/cubit/theme_cubit.dart';
import 'package:walk/presentation/settings/page/settings_page.dart';
import 'package:walk/presentation/walk/cubit/step_goal_cubit.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

class _MockRequester extends Mock implements PermissionRequester {}

class _MockWalk extends Mock implements WalkUseCase {}

class _MockSettings extends Mock implements SettingsRepository {}

class _MockAccess extends Mock implements HolidayCalendarAccess {}

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockDiaryRepo extends Mock implements DiaryRepository {}

class _NoRefresh implements HolidayRefresher {
  @override
  Future<void> refresh({bool force = false}) async {}

  @override
  Stream<void> get refreshed => const Stream.empty();
}

class _FakeHolidays implements HolidayCalendar {
  @override
  HolidaySource source = const HolidaySource.bundled(
    firstYear: 2026,
    lastYear: 2027,
  );

  @override
  String? nameOf(DateTime date) => null;
}

void main() {
  late _MockRequester notification;
  late _MockRequester exactAlarm;
  late _MockRequester fullScreen;
  late _MockWalk walk;
  late _MockSettings settings;
  late SettingsPermissionsCubit permissions;
  late ThemeCubit theme;
  late StepGoalCubit goal;
  late _FakeHolidays holidays;
  late _MockAccess access;
  late _MockUseCase alarms;
  late HolidaySettingsCubit holiday;
  late PrefsLockRepository lockRepo;
  late DiaryPreferences diaryPrefs;
  late _MockDiaryRepo diaryRepo;
  late DiaryLockCubit diaryLock;
  late DiarySettingsCubit diarySettings;

  setUpAll(() => registerFallbackValue(const AppSettings()));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    lockRepo = PrefsLockRepository(prefs);
    diaryPrefs = PrefsDiaryPreferences(prefs);
    diaryRepo = _MockDiaryRepo();
    when(diaryRepo.usage).thenAnswer(
      (_) async => const DiaryUsage(
        photos: 340,
        videos: 52,
        bytes: 1288490189,
        trashBytes: 83886080,
      ),
    );
    final clock = MutableClock(diaryT0);
    getIt
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth())
      ..registerSingleton<Clock>(clock);
    diaryLock = DiaryLockCubit(
      lockRepo,
      FakeDeviceAuth(),
      clock,
      MediaPickGuard(),
    )..start();
    diarySettings = DiarySettingsCubit(lockRepo, diaryPrefs, diaryRepo);
    notification = _MockRequester();
    exactAlarm = _MockRequester();
    fullScreen = _MockRequester();
    walk = _MockWalk();
    settings = _MockSettings();
    when(notification.check).thenAnswer((_) async => PermissionStatus.granted);
    when(exactAlarm.check).thenAnswer((_) async => PermissionStatus.denied);
    when(fullScreen.check).thenAnswer((_) async => PermissionStatus.granted);
    when(fullScreen.openSettings).thenAnswer((_) async {});
    when(walk.access).thenAnswer((_) async => HealthAccess.notInstalled);
    when(settings.load).thenReturn(const AppSettings());
    when(() => settings.save(any())).thenAnswer((_) async {});
    permissions = SettingsPermissionsCubit(
      AlarmPermissions(
        notification: notification,
        exactAlarm: exactAlarm,
        fullScreenIntent: fullScreen,
      ),
      walk,
    );
    theme = ThemeCubit(settings);
    goal = StepGoalCubit(settings);
    holidays = _FakeHolidays();
    access = _MockAccess();
    alarms = _MockUseCase();
    when(access.check).thenAnswer((_) async => PermissionStatus.denied);
    when(alarms.sync).thenAnswer((_) async {});
    when(() => access.refresher).thenReturn(_NoRefresh());
    holiday = HolidaySettingsCubit(settings, holidays, access, alarms);
  });
  tearDown(() async {
    await permissions.close();
    await theme.close();
    await goal.close();
    await holiday.close();
    await diaryLock.close();
    await diarySettings.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester, {bool checked = true}) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    if (checked) {
      await permissions.check();
      await holiday.check();
    }
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: permissions),
          BlocProvider.value(value: theme),
          BlocProvider.value(value: goal),
          BlocProvider.value(value: holiday),
          BlocProvider.value(value: diaryLock),
          BlocProvider.value(value: diarySettings),
        ],
        child: BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, mode) => MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode == AppThemeMode.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('권한 상태를 보인다', (tester) async {
    await pump(tester);

    expect(find.text('허용됨'), findsNWidgets(2));
    expect(find.text('허용 필요 ›'), findsOneWidget);
    expect(find.text('설치 필요 ›'), findsOneWidget);
  });

  testWidgets('앱 정보(버전 · 라이선스)와 14일 안내가 없다', (tester) async {
    await pump(tester);

    expect(find.text('앱 정보'), findsNothing);
    expect(find.text('버전'), findsNothing);
    expect(find.text('1.0.0 (1)'), findsNothing);
    expect(find.text('오픈소스 라이선스'), findsNothing);
    expect(find.textContaining('14일'), findsNothing);
  });

  testWidgets('권한 행을 누르면 해당 설정을 연다', (tester) async {
    await pump(tester);

    await tester.tap(find.text('전체 화면 알림'));
    verify(fullScreen.openSettings).called(1);
  });

  testWidgets('테마를 고르면 즉시 반영하고 저장한다', (tester) async {
    await pump(tester);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.light,
    );

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    expect(theme.state, AppThemeMode.dark);
    verify(
      () => settings.save(const AppSettings(themeMode: AppThemeMode.dark)),
    ).called(1);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('확인 중(null)이면 상태 문구를 비운다', (tester) async {
    await pump(tester, checked: false);

    expect(find.text('알림'), findsOneWidget);
    for (final label in ['허용됨', '허용 필요 ›', '설치 필요 ›', '업데이트 필요 ›']) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });

  testWidgets('알림 행: 아직 물을 수 있으면(denied) 다시 묻고 상태를 다시 읽는다', (tester) async {
    when(notification.check).thenAnswer((_) async => PermissionStatus.denied);
    when(notification.requestAgain).thenAnswer((_) async {
      when(
        notification.check,
      ).thenAnswer((_) async => PermissionStatus.granted);
      return PermissionStatus.granted;
    });
    await pump(tester);
    expect(find.text('허용 필요 ›'), findsNWidgets(2));

    await tester.tap(find.text('알림'));
    await tester.pumpAndSettle();

    verify(notification.requestAgain).called(1);
    verifyNever(notification.openSettings);
    // 알림은 허용됨으로 바뀌고 정확한 알람만 허용 필요.
    expect(find.text('허용 필요 ›'), findsOneWidget);
  });

  testWidgets('알림 행: 이미 허용이면 앱 설정을 연다', (tester) async {
    when(notification.openSettings).thenAnswer((_) async {});
    await pump(tester);

    await tester.tap(find.text('알림'));
    await tester.pumpAndSettle();

    verify(notification.openSettings).called(1);
    verifyNever(notification.requestAgain);
  });

  testWidgets('정확한 알람 행을 누르면 정확한 알람 설정을 연다', (tester) async {
    when(exactAlarm.openSettings).thenAnswer((_) async {});
    await pump(tester);

    await tester.tap(find.text('정확한 알람'));
    await tester.pumpAndSettle();

    verify(exactAlarm.openSettings).called(1);
  });

  testWidgets('Health Connect 행: 설치가 필요하면 설치 화면을 연다', (tester) async {
    when(walk.openInstall).thenAnswer((_) async {});
    await pump(tester);

    await tester.tap(find.text('Health Connect'));
    await tester.pumpAndSettle();

    verify(walk.openInstall).called(1);
  });

  testWidgets('걷기 섹션의 하루 목표 행이 현재 목표를 보여준다', (tester) async {
    await pump(tester);

    expect(find.text('걷기'), findsOneWidget);
    expect(find.text('하루 목표'), findsOneWidget);
    expect(find.text('10,000 걸음'), findsOneWidget);
  });

  testWidgets('슬라이더를 옮기고 저장하면 cubit 과 행이 바뀐다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-step-goal')));
    await tester.pumpAndSettle();
    final slider = tester.widget<Slider>(
      find.byKey(const Key('step-goal-slider')),
    );
    slider.onChanged!(8000);
    await tester.pump();
    expect(find.text('8,000 걸음'), findsWidgets);

    await tester.tap(find.byKey(const Key('step-goal-save')));
    await tester.pumpAndSettle();

    expect(goal.state, 8000);
    expect(find.byKey(const Key('step-goal-slider')), findsNothing);
    expect(find.text('8,000 걸음'), findsOneWidget);
  });

  testWidgets('저장하지 않고 닫으면 그대로다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-step-goal')));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byKey(const Key('step-goal-slider'))).onChanged!(
      8000,
    );
    await tester.pump();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(goal.state, 10000);
    expect(find.text('10,000 걸음'), findsOneWidget);
  });

  group('알람 섹션', () {
    testWidgets('걷기와 권한 사이 — 공휴일 미리 알림 스위치(켬) · 공휴일 출처(내장 표) · 캘린더 권한', (
      tester,
    ) async {
      await pump(tester);

      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(top('걷기'), lessThan(top('알람')));
      expect(top('알람'), lessThan(top('권한')));
      expect(find.text('공휴일 미리 알림'), findsOneWidget);
      expect(find.text('반복 알람이 공휴일에 울리면 하루 전에 알려요'), findsOneWidget);
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(const Key('settings-holiday-reminder')),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isTrue,
      );
      expect(find.text('공휴일 출처'), findsOneWidget);
      expect(find.text('내장 표 2026–2027'), findsOneWidget);
      final status = tester.widget<Text>(find.text('캘린더 허용 필요 ›'));
      final scheme = Theme.of(
        tester.element(find.byType(SettingsPage)),
      ).colorScheme;
      expect(status.style?.color, scheme.error);
    });

    testWidgets('폰 캘린더에서 읽으면 그 캘린더 이름과 허용됨', (tester) async {
      holidays.source = const HolidaySource.device(calendarName: '대한민국의 휴일');
      when(access.check).thenAnswer((_) async => PermissionStatus.granted);
      await pump(tester);

      expect(find.text('폰 캘린더: 대한민국의 휴일'), findsOneWidget);
      expect(find.text('캘린더 허용됨'), findsOneWidget);
    });

    testWidgets('이름을 모르는 폰 캘린더는 폰 캘린더만', (tester) async {
      holidays.source = const HolidaySource.device(calendarName: '');
      await pump(tester);

      expect(find.text('폰 캘린더'), findsOneWidget);
    });

    testWidgets('확인 중(null)이면 출처 · 권한 문구를 비운다', (tester) async {
      await pump(tester, checked: false);

      expect(find.text('공휴일 출처'), findsOneWidget);
      expect(find.textContaining('내장 표'), findsNothing);
      expect(find.textContaining('캘린더 허용'), findsNothing);
    });

    testWidgets('스위치를 끄면 저장하고 알람을 맞춘다', (tester) async {
      when(() => settings.save(any())).thenAnswer((i) async {
        when(
          settings.load,
        ).thenReturn(i.positionalArguments.single as AppSettings);
      });
      await pump(tester);

      await tester.tap(find.text('공휴일 미리 알림'));
      await tester.pumpAndSettle();

      verify(
        () => settings.save(const AppSettings(holidayReminder: false)),
      ).called(1);
      verify(alarms.sync).called(1);
      expect(holiday.state.holidayReminder, isFalse);
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(const Key('settings-holiday-reminder')),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('공휴일 출처 행을 누르면 캘린더 권한을 다시 묻는다', (tester) async {
      when(
        access.requestAgain,
      ).thenAnswer((_) async => PermissionStatus.denied);
      await pump(tester);

      await tester.tap(find.text('공휴일 출처'));
      await tester.pumpAndSettle();

      verify(access.requestAgain).called(1);
    });

    for (final locale in const [Locale('en'), Locale('ja')]) {
      testWidgets('320dp 에서 넘치지 않는다 ($locale)', (tester) async {
        holidays.source = const HolidaySource.device(
          calendarName: 'Holidays in South Korea',
        );
        await pump(tester);
        await tester.binding.setSurfaceSize(const Size(320, 1800));
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: permissions),
              BlocProvider.value(value: theme),
              BlocProvider.value(value: goal),
              BlocProvider.value(value: holiday),
              BlocProvider.value(value: diaryLock),
              BlocProvider.value(value: diarySettings),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SettingsPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('일기 섹션', () {
    Finder inLock(String text) => find.descendant(
      of: find.byKey(const Key('settings-diary-lock')),
      matching: find.text(text),
    );
    Finder inRow(String key, String text) =>
        find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

    Future<void> typePin(WidgetTester tester, String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.widgetWithText(TextButton, d));
        await tester.pump();
      }
      await tester.pump();
      await tester.pump();
    }

    Future<void> enablePin() async {
      await lockRepo.setSecret(LockMethod.pin, '1234');
      await lockRepo.saveConfig(const LockConfig(enabled: true));
      diaryLock.start();
    }

    testWidgets('알람과 권한 사이 — 잠금 꺼짐 · 안내 문구', (tester) async {
      await pump(tester);

      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(top('알람'), lessThan(top('일기')));
      expect(top('일기'), lessThan(top('권한')));
      expect(find.text('일기 잠금'), findsOneWidget);
      expect(inLock('꺼짐'), findsOneWidget);
      expect(find.text('기록은 이 폰에만 저장돼요. 앱을 지우면 함께 사라져요.'), findsOneWidget);
    });

    testWidgets('잠금 행은 켜진 방식을 보인다(PIN)', (tester) async {
      await enablePin();
      await pump(tester);

      expect(inLock('PIN 4자리'), findsOneWidget);
    });

    testWidgets('잠금 행은 켜진 방식을 보인다(패턴)', (tester) async {
      await lockRepo.setSecret(LockMethod.pattern, '0-1-2-5');
      await lockRepo.saveConfig(
        const LockConfig(enabled: true, method: LockMethod.pattern),
      );
      await pump(tester);

      expect(inLock('패턴'), findsOneWidget);
    });

    testWidgets('용량 문구: 크기 · 사진 · 영상 수 · 휴지통 몫', (tester) async {
      await pump(tester);

      expect(find.text('사용 중 1.2GB'), findsOneWidget);
      expect(find.text('사진 340장 · 영상 52개, 휴지통 80.0MB 포함'), findsOneWidget);
    });

    testWidgets('용량은 B · KB 도 줄여 쓴다', (tester) async {
      when(diaryRepo.usage).thenAnswer(
        (_) async => const DiaryUsage(
          photos: 0,
          videos: 0,
          bytes: 2048,
          trashBytes: 512,
        ),
      );
      await pump(tester);

      expect(find.text('사용 중 2KB'), findsOneWidget);
      expect(find.text('사진 0장 · 영상 0개, 휴지통 512B 포함'), findsOneWidget);
    });

    testWidgets('설정 탭이 다시 보일 때 용량을 다시 읽는다', (tester) async {
      Future<void> show({required bool active}) async {
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: permissions),
              BlocProvider.value(value: theme),
              BlocProvider.value(value: goal),
              BlocProvider.value(value: holiday),
              BlocProvider.value(value: diaryLock),
              BlocProvider.value(value: diarySettings),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              locale: const Locale('ko'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: SettingsPage(active: active),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await show(active: false);
      expect(find.text('사용 중 1.2GB'), findsOneWidget);
      when(diaryRepo.usage).thenAnswer(
        (_) async => const DiaryUsage(
          photos: 1,
          videos: 0,
          bytes: 5 * 1024 * 1024,
          trashBytes: 0,
        ),
      );

      await show(active: true);

      expect(find.text('사용 중 5.0MB'), findsOneWidget);
    });

    testWidgets('휴지통 보관 기간: 4개 중 고르면 저장한다(기본 7일)', (tester) async {
      await pump(tester);
      expect(inRow('settings-diary-retention', '7일'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings-diary-retention')));
      await tester.pumpAndSettle();
      for (final label in ['1일', '7일', '30일', '지우지 않음']) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      await tester.tap(find.text('30일').last);
      await tester.pumpAndSettle();

      expect(diaryPrefs.trashRetention, TrashRetention.day30);
      expect(inRow('settings-diary-retention', '30일'), findsOneWidget);
    });

    testWidgets('다시 잠기는 시간: 4개 중 고르면 최신 설정에 저장하고 잠금에 알린다', (tester) async {
      await enablePin();
      await pump(tester);

      await tester.tap(find.byKey(const Key('settings-diary-relock')));
      await tester.pumpAndSettle();
      for (final label in ['바로', '30초 뒤', '1분 뒤', '5분 뒤']) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      // 시트가 열린 사이 잠금 방식이 패턴으로 바뀌었다 — 오래된 설정으로 덮어쓰면 안 된다.
      await lockRepo.setSecret(LockMethod.pattern, '0-1-2-5');
      await lockRepo.saveConfig(
        const LockConfig(enabled: true, method: LockMethod.pattern),
      );
      await tester.tap(find.text('5분 뒤').last);
      await tester.pumpAndSettle();

      expect(
        lockRepo.loadConfig(),
        const LockConfig(
          enabled: true,
          method: LockMethod.pattern,
          relockDelay: RelockDelay.minutes5,
        ),
      );
      // configChanged 가 불렸다.
      expect((diaryLock.state as LockLocked).method, LockMethod.pattern);
    });

    testWidgets('잠금이 꺼져 있으면 다시 잠기는 시간 행은 눌러도 열리지 않는다', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const Key('settings-diary-relock')));
      await tester.pumpAndSettle();

      expect(find.text('5분 뒤'), findsNothing);
    });

    testWidgets('잠금 행을 누르면 LockSetupPage', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const Key('settings-diary-lock')));
      await tester.pumpAndSettle();

      expect(find.byType(LockSetupPage), findsOneWidget);
    });

    testWidgets('PIN → 패턴으로 바꾸면 일기 잠금 상태와 행이 새 방식을 따른다', (tester) async {
      await enablePin();
      await pump(tester);
      expect((diaryLock.state as LockLocked).method, LockMethod.pin);

      await tester.tap(find.byKey(const Key('settings-diary-lock')));
      await tester.pumpAndSettle();
      await typePin(tester, '1234');
      await tester.tap(find.text('패턴'));
      await tester.pump();
      tester.widget<PatternLock>(find.byType(PatternLock)).onCompleted([
        0, 1, 2, 5, //
      ]);
      await tester.pump();
      tester.widget<PatternLock>(find.byType(PatternLock)).onCompleted([
        0, 1, 2, 5, //
      ]);
      await tester.pumpAndSettle();

      expect(find.byType(LockSetupPage), findsNothing);
      expect(lockRepo.loadConfig().method, LockMethod.pattern);
      expect((diaryLock.state as LockLocked).method, LockMethod.pattern);
      expect(inLock('패턴'), findsOneWidget);
    });

    testWidgets('잠금을 끄면 일기가 풀리고 행은 꺼짐', (tester) async {
      await enablePin();
      await pump(tester);

      await tester.tap(find.byKey(const Key('settings-diary-lock')));
      await tester.pumpAndSettle();
      await typePin(tester, '1234');
      await tester.tap(find.text('잠금 끄기'));
      await tester.pumpAndSettle();

      expect(diaryLock.state, isA<LockUnlocked>());
      expect(inLock('꺼짐'), findsOneWidget);
    });

    testWidgets('설정 화면을 그냥 닫으면 잠금 상태를 건드리지 않는다', (tester) async {
      await enablePin();
      await pump(tester);

      await tester.tap(find.byKey(const Key('settings-diary-lock')));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(LockSetupPage))).pop();
      await tester.pumpAndSettle();

      expect(diaryLock.state, isA<LockLocked>());
    });
  });
}
