import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/core/app.dart';
import 'package:walk/core/background/background_task.dart';
import 'package:walk/data/alarm/channel_next_alarm_widget.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar_access.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/alarm/widget/next_alarm_widget.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/shell/page/main_shell_page.dart';

import '../support/fake_device_auth.dart';

class _MockAlarmUseCase extends Mock implements AlarmUseCase {}

class _MockWalk extends Mock implements WalkUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockSettings extends Mock implements SettingsRepository {}

class _MockDiaryRepo extends Mock implements DiaryRepository {}

class _MockDiaryUseCase extends Mock implements DiaryUseCase {}

class _NoHolidays implements HolidayRefresher, HolidayCalendar {
  @override
  Future<void> refresh({bool force = false}) async {}

  @override
  Stream<void> get refreshed => const Stream.empty();

  @override
  String? nameOf(DateTime date) => null;

  @override
  HolidaySource get source =>
      const HolidaySource.bundled(firstYear: 2026, lastYear: 2027);
}

void main() {
  group('themeModeOf', () {
    test('앱 테마 선택을 Flutter ThemeMode 로 옮긴다', () {
      expect(themeModeOf(AppThemeMode.system), ThemeMode.system);
      expect(themeModeOf(AppThemeMode.light), ThemeMode.light);
      expect(themeModeOf(AppThemeMode.dark), ThemeMode.dark);
    });
  });

  group('WalkApp', () {
    late _MockSettings settings;

    setUpAll(() => registerFallbackValue(const EntryFilter.all()));
    setUp(() async {
      // 네이티브 디스패처 자리: 헤드리스 일이 없어 셸의 awaitIdle 에 바로 답한다.
      final messenger =
          TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        backgroundChannel,
        (call) async => null,
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(backgroundChannel, null),
      );
      final alarms = _MockAlarmUseCase();
      final walk = _MockWalk();
      final requester = _MockRequester();
      when(requester.check).thenAnswer((_) async => PermissionStatus.granted);
      when(alarms.list).thenAnswer((_) async => []);
      when(alarms.nextRings).thenAnswer((_) async => {});
      when(alarms.sync).thenAnswer((_) async {});
      when(walk.access).thenAnswer((_) async => HealthAccess.permissionDenied);
      when(() => walk.permissionDeclinedThisSession).thenReturn(false);
      settings = _MockSettings();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final diary = _MockDiaryUseCase();
      when(diary.maintain).thenAnswer((_) async {});
      when(diary.cleanOrphans).thenAnswer((_) async {});
      final diaryRepo = _MockDiaryRepo();
      when(diaryRepo.watchStories).thenAnswer((_) => Stream.value(const []));
      when(
        () => diaryRepo.watchEntries(any()),
      ).thenAnswer((_) => Stream.value(const []));
      getIt
        ..registerSingleton<DiaryUseCase>(diary)
        ..registerSingleton<DiaryRepository>(diaryRepo)
        ..registerSingleton<DiaryPreferences>(PrefsDiaryPreferences(prefs))
        ..registerSingleton<LockRepository>(PrefsLockRepository(prefs))
        ..registerSingleton<DeviceAuth>(FakeDeviceAuth())
        ..registerSingleton<MediaPickGuard>(MediaPickGuard());
      getIt
        ..registerSingleton<AlarmUseCase>(alarms)
        ..registerSingleton<WalkUseCase>(walk)
        ..registerSingleton<SettingsRepository>(settings)
        ..registerSingleton<Clock>(Clock())
        // 채널이 없어 위젯으로 열지 않은 시작이다.
        ..registerSingleton<NextAlarmWidget>(const ChannelNextAlarmWidget())
        ..registerSingleton<HolidayRefresher>(_NoHolidays())
        ..registerSingleton<HolidayCalendar>(_NoHolidays())
        ..registerSingleton<HolidayCalendarAccess>(
          HolidayCalendarAccess(
            calendar: requester,
            refresher: _NoHolidays(),
            settings: settings,
          ),
        )
        ..registerSingleton<AlarmPermissions>(
          AlarmPermissions(
            notification: requester,
            exactAlarm: requester,
            fullScreenIntent: requester,
          ),
        );
    });
    tearDown(getIt.reset);

    testWidgets('저장된 다크 테마로 첫 프레임부터 뜬다', (tester) async {
      // 기기는 라이트 — 시스템 테마로 떴다면 밝게 보인다.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      when(
        settings.load,
      ).thenReturn(const AppSettings(themeMode: AppThemeMode.dark));

      await tester.pumpWidget(const WalkApp());

      final context = tester.element(find.byType(MainShellPage));
      expect(Theme.of(context).brightness, Brightness.dark);

      await tester.pumpAndSettle();
    });
  });
}
