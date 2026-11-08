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
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/domain/chat/chat_model_catalog.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/repository/wiki_repository.dart';
import 'package:walk/domain/chat/repository/chat_usage_repository.dart';
import 'package:walk/domain/chat/usecase/chat_key_verifier.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/domain/diary/entity/diary_usage.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/location/entity/record_retention.dart';
import 'package:walk/domain/location/recorder/location_recorder.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/domain/location/repository/location_preferences.dart';
import 'package:walk/domain/location/repository/location_repository.dart';
import 'package:walk/data/location/background_location_access.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/map/cubit/map_record_cubit.dart';
import 'package:walk/presentation/settings/cubit/diary_settings_cubit.dart';
import 'package:walk/presentation/settings/cubit/holiday_settings_cubit.dart';
import 'package:walk/presentation/settings/cubit/settings_permissions_cubit.dart';
import 'package:walk/presentation/settings/cubit/theme_cubit.dart';
import 'package:walk/presentation/walk/cubit/step_goal_cubit.dart';

import '../../support/diary_fixtures.dart';
import '../../support/fake_chat_history.dart';
import '../../support/fake_wiki_repository.dart';
import '../../support/fake_chat_key_verifier.dart';
import '../../support/fake_chat_model_catalog.dart';
import '../../support/fake_chat_settings.dart';
import '../../support/fake_device_auth.dart';

class MockRequester extends Mock implements PermissionRequester {}

class MockWalkUseCase extends Mock implements WalkUseCase {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockHolidayAccess extends Mock implements HolidayCalendarAccess {}

class MockAlarmUseCase extends Mock implements AlarmUseCase {}

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockLocationRecorder extends Mock implements LocationRecorder {}

class MockBackgroundLocationAccess extends Mock
    implements BackgroundLocationAccess {}

class MockLocationPreferences extends Mock implements LocationPreferences {}

class MockLocationRepository extends Mock implements LocationRepository {}

class _NoRefresh implements HolidayRefresher {
  @override
  Future<void> refresh({bool force = false}) async {}

  @override
  Stream<void> get refreshed => const Stream.empty();
}

class FakeHolidays implements HolidayCalendar {
  static const bundled = HolidaySource.bundled(firstYear: 2026, lastYear: 2027);

  @override
  HolidaySource source = bundled;

  @override
  String? nameOf(DateTime date) => null;
}

/// 설정 화면 테스트 공용 — 셸이 내리는 cubit 다섯(지도 기록 포함)과 앱이 내리는 테마 · 걸음 목표를 만든다.
/// [setUp] 은 테스트의 `setUp` 에서, [tearDown] 은 `tearDown` 에서 부른다.
class SettingsHarness {
  final notification = MockRequester();
  final exactAlarm = MockRequester();
  final fullScreen = MockRequester();
  final walk = MockWalkUseCase();
  final settings = MockSettingsRepository();
  final diaryRepo = MockDiaryRepository();
  final holidays = FakeHolidays();
  final holidayAccess = MockHolidayAccess();
  final alarms = MockAlarmUseCase();
  final locationRecorder = MockLocationRecorder();
  final locationAccess = MockBackgroundLocationAccess();
  final locationPrefs = MockLocationPreferences();
  final locations = MockLocationRepository();
  late PrefsLockRepository lockRepo;
  late DiaryPreferences diaryPrefs;
  late SettingsPermissionsCubit permissions;
  late ThemeCubit theme;
  late StepGoalCubit goal;
  late HolidaySettingsCubit holiday;
  late DiaryLockCubit diaryLock;
  late DiarySettingsCubit diarySettings;
  late MapRecordCubit mapRecord;

  static void registerFallbacks() => registerFallbackValue(const AppSettings());

  Future<void> setUp() async {
    // 한 파일의 테스트가 같은 목을 쓰므로 앞 테스트의 응답 · 호출 기록을 지운다.
    for (final mock in <Mock>[
      notification,
      exactAlarm,
      fullScreen,
      walk,
      settings,
      diaryRepo,
      holidayAccess,
      alarms,
      locationRecorder,
      locationAccess,
      locationPrefs,
      locations,
    ]) {
      reset(mock);
    }
    holidays.source = FakeHolidays.bundled;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    lockRepo = PrefsLockRepository(prefs);
    diaryPrefs = PrefsDiaryPreferences(prefs);
    when(diaryRepo.usage).thenAnswer(
      (_) async =>
          const DiaryUsage(photos: 1, videos: 0, bytes: 2048, trashBytes: 0),
    );
    final clock = MutableClock(diaryT0);
    final chatSettings = FakeChatSettings();
    final chatVerifier = FakeChatKeyVerifier();
    final chatCatalog = FakeChatModelCatalog();
    getIt
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth())
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<ChatSettings>(chatSettings)
      ..registerSingleton<ChatKeyVerifier>(chatVerifier)
      ..registerSingleton<ChatModelCatalog>(chatCatalog)
      ..registerSingleton<ChatModelChoice>(
        ChatModelChoice(chatSettings, chatCatalog, chatVerifier, clock),
      )
      ..registerSingleton<ChatHistorySettings>(FakeChatHistorySettings())
      ..registerSingleton<ChatHistoryRepository>(FakeChatHistoryCount())
      ..registerSingleton<WikiRepository>(FakeWikiRepository())
      ..registerSingleton<ChatUsageRepository>(FakeChatUsageRepository());
    diaryLock = DiaryLockCubit(
      lockRepo,
      FakeDeviceAuth(),
      clock,
      MediaPickGuard(),
    )..start();
    diarySettings = DiarySettingsCubit(lockRepo, diaryPrefs, diaryRepo);
    when(notification.check).thenAnswer((_) async => PermissionStatus.granted);
    when(exactAlarm.check).thenAnswer((_) async => PermissionStatus.denied);
    when(fullScreen.check).thenAnswer((_) async => PermissionStatus.granted);
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
    when(holidayAccess.check).thenAnswer((_) async => PermissionStatus.denied);
    when(alarms.sync).thenAnswer((_) async {});
    when(() => holidayAccess.refresher).thenReturn(_NoRefresh());
    holiday = HolidaySettingsCubit(settings, holidays, holidayAccess, alarms);
    when(() => locationPrefs.retention).thenReturn(RecordRetention.never);
    when(
      locationRecorder.status,
    ).thenAnswer((_) async => const RecorderStatus.off());
    when(locationAccess.check).thenAnswer((_) async => AlwaysAccess.denied);
    when(locationAccess.hasActivityRecognition).thenAnswer((_) async => true);
    when(locationAccess.hasNotification).thenAnswer((_) async => true);
    when(locations.hasAnyPoint).thenAnswer((_) async => false);
    mapRecord = MapRecordCubit(
      locationRecorder,
      locationAccess,
      locationPrefs,
      locations,
    );
  }

  Future<void> tearDown() async {
    await permissions.close();
    await theme.close();
    await goal.close();
    await holiday.close();
    await diaryLock.close();
    await diarySettings.close();
    await mapRecord.close();
    await getIt.reset();
  }

  /// 잠금(PIN 1234)을 켜고 일기를 잠근다.
  Future<void> lockWithPin() async {
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
    diaryLock.start();
  }

  /// 셸과 같은 자리에 cubit 을 둔 앱. [home] 은 그 아래.
  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: permissions),
              BlocProvider.value(value: holiday),
              BlocProvider.value(value: diaryLock),
              BlocProvider.value(value: diarySettings),
              BlocProvider.value(value: mapRecord),
            ],
            child: home,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}
