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
import 'package:walk/domain/chat/chat_model_catalog.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/data/location/background_location_access.dart';
import 'package:walk/domain/location/entity/record_retention.dart';
import 'package:walk/domain/location/recorder/location_recorder.dart';
import 'package:walk/domain/location/repository/location_preferences.dart';
import 'package:walk/domain/location/repository/location_repository.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/map/map_open_requests.dart';
import 'package:walk/presentation/shell/page/main_shell_page.dart';
import 'package:walk/domain/chat/attachment/attachment_loader.dart';
import 'package:walk/domain/chat/workspace/workspace.dart';
import '../support/unused_chat_attachments.dart';

import '../support/fake_device_auth.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/usecase/open_conversation.dart';
import '../support/fake_chat_settings.dart';
import '../support/fake_chat_key_verifier.dart';
import '../support/fake_chat_model_catalog.dart';
import 'package:walk/domain/chat/usecase/chat_key_verifier.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';

class _MockAlarmUseCase extends Mock implements AlarmUseCase {}

class _MockWalk extends Mock implements WalkUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockSettings extends Mock implements SettingsRepository {}

class _MockDiaryRepo extends Mock implements DiaryRepository {}

class _MockDiaryUseCase extends Mock implements DiaryUseCase {}

class _MockPlaceSource extends Mock implements PlaceSource {}

class _MockRecorder extends Mock implements LocationRecorder {}

class _MockAlwaysAccess extends Mock implements BackgroundLocationAccess {}

class _MockLocationPrefs extends Mock implements LocationPreferences {}

class _MockLocations extends Mock implements LocationRepository {}

class _MockChatSession extends Mock implements ChatSession {
  _MockChatSession() {
    when(
      () => target,
    ).thenReturn((vendor: ChatVendor.anthropic, model: 'claude-test'));
    when(() => attachmentRoom).thenReturn((images: 12, docs: 5));
  }
}

class _MockChatHistory extends Mock implements ChatHistoryRepository {}

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

    setUpAll(() {
      registerFallbackValue(const EntryFilter.all());
      registerFallbackValue(const AppSettings());
    });
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
      final chatSettings = FakeChatSettings();
      final chatVerifier = FakeChatKeyVerifier();
      final chatCatalog = FakeChatModelCatalog();
      getIt
        ..registerSingleton<DiaryUseCase>(diary)
        ..registerSingleton<ChatSettings>(chatSettings)
        ..registerSingleton<ChatKeyVerifier>(chatVerifier)
        ..registerSingleton<ChatModelCatalog>(chatCatalog)
        ..registerSingleton<ChatModelChoice>(
          ChatModelChoice(
            chatSettings,
            chatCatalog,
            chatVerifier,
            const Clock(),
          ),
        )
        ..registerSingleton<DiaryRepository>(diaryRepo)
        ..registerSingleton<DiaryPreferences>(PrefsDiaryPreferences(prefs))
        ..registerSingleton<LockRepository>(PrefsLockRepository(prefs))
        ..registerSingleton<DeviceAuth>(FakeDeviceAuth())
        ..registerSingleton<MediaPickGuard>(MediaPickGuard())
        ..registerSingleton<MapOpenRequests>(MapOpenRequests())
        ..registerSingleton<Workspace>(const UnusedWorkspace())
        ..registerSingleton<AttachmentLoader>(const UnusedAttachmentLoader())
        ..registerSingleton<ChatSession>(_MockChatSession())
        ..registerSingleton<ChatHistoryRepository>(_MockChatHistory())
        ..registerSingleton<OpenConversation>(OpenConversation())
        ..registerSingleton<ChatTrace>(const NoopChatTrace())
        ..registerSingleton<PlaceSource>(_MockPlaceSource());
      // 설정 화면을 열면 셸의 지도 기록 cubit 을 만든다 — 만들 때 보관 기간만 읽는다.
      final locationPrefs = _MockLocationPrefs();
      when(() => locationPrefs.retention).thenReturn(RecordRetention.never);
      getIt
        ..registerSingleton<LocationRecorder>(_MockRecorder())
        ..registerSingleton<BackgroundLocationAccess>(_MockAlwaysAccess())
        ..registerSingleton<LocationPreferences>(locationPrefs)
        ..registerSingleton<LocationRepository>(_MockLocations());
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

    testWidgets('앱 설정에서 다크를 고르면 바로 어두워진다', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      when(settings.load).thenReturn(const AppSettings());
      when(() => settings.save(any())).thenAnswer((_) async {});

      await tester.pumpWidget(const WalkApp());
      await tester.pumpAndSettle();
      // 앱 설정이 위에 얹혀도 아래 셸까지 같은 테마다.
      Brightness brightness() => Theme.of(
        tester.element(find.byType(MainShellPage, skipOffstage: false)),
      ).brightness;
      expect(brightness(), Brightness.light);

      // 일기 탭 ⋮ → 앱 설정 → 다크.
      await tester.tap(find.byIcon(Icons.more_vert).hitTestable().first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu-settings-app')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is RadioListTile<AppThemeMode> && w.value == AppThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(brightness(), Brightness.dark);
    });
  });
}
