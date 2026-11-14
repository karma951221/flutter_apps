import 'dart:async';
import 'package:walk/presentation/weather/cubit/weather_cubit.dart';
import 'package:walk/domain/weather/weather_problem.dart';
import 'package:walk/presentation/weather/cubit/weather_state.dart';
import 'package:walk/presentation/weather/page/weather_page.dart';
import 'package:walk/presentation/map/cubit/map_style_cubit.dart';
import 'package:walk/domain/chat/attachment/attachment_loader.dart';
import 'package:walk/domain/chat/attachment/attachment_rules.dart';
import 'package:walk/domain/chat/workspace/workspace.dart';
import '../../../support/unused_chat_attachments.dart';

import 'package:bloc_test/bloc_test.dart';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/core/background/background_task.dart';
import 'package:walk/data/location/background_location_access.dart';
import 'package:walk/data/diary/prefs_diary_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar_access.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/alarm/usecase/ring_archiver.dart';
import 'package:walk/domain/alarm/widget/next_alarm_widget.dart';
import 'package:walk/domain/chat/chat_model_catalog.dart';
import 'package:walk/domain/chat/usecase/chat_history_pruner.dart';
import 'package:walk/domain/diary/location/place_source.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/repository/diary_preferences.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/domain/location/entity/map_period.dart';
import 'package:walk/domain/location/entity/record_retention.dart';
import 'package:walk/domain/location/recorder/location_recorder.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/domain/location/repository/location_preferences.dart';
import 'package:walk/domain/location/repository/location_repository.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/entity/daily_activity.dart';
import 'package:walk/domain/walk/entity/health_access.dart';
import 'package:walk/domain/walk/entity/period_kind.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/alarm/page/alarm_list_page.dart';
import 'package:walk/presentation/chat/attachment/chat_file_picker.dart';
import 'package:walk/presentation/chat/page/chat_tab.dart';
import 'package:walk/presentation/commute/page/commute_tab.dart';
import 'package:walk/presentation/diary/page/diary_tab.dart';
import 'package:walk/presentation/diary/widget/story_ring_row.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/lock/widget/pin_pad.dart';
import 'package:walk/presentation/map/cubit/map_view_cubit.dart';
import 'package:walk/presentation/map/cubit/map_view_state.dart';
import 'package:walk/presentation/map/page/map_tab.dart';
import 'package:walk/presentation/map/widget/story_picker_sheet.dart';
import 'package:walk/presentation/settings/cubit/theme_cubit.dart';
import 'package:walk/presentation/map/map_open_requests.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/presentation/settings/page/alarm_settings_page.dart';
import 'package:walk/presentation/settings/page/app_settings_page.dart';
import 'package:walk/presentation/settings/page/chat_settings_page.dart';
import 'package:walk/presentation/settings/page/map_settings_page.dart';
import 'package:walk/presentation/settings/page/walk_settings_page.dart';
import 'package:walk/presentation/settings/widget/row_highlight.dart';
import 'package:walk/presentation/shell/page/main_shell_page.dart';
import 'package:walk/presentation/shell/page/tools_tab.dart';
import 'package:walk/presentation/walk/cubit/step_goal_cubit.dart';
import 'package:walk/presentation/walk/page/walk_home_page.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';
import '../../../support/fake_map_style_preferences.dart';
import '../../../support/stub_tile_provider.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/repository/wiki_repository.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/usecase/open_conversation.dart';
import '../../../support/fake_chat_history.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_wiki_repository.dart';
import 'package:walk/domain/chat/usecase/chat_key_verifier.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';

class _MockAlarmUseCase extends Mock implements AlarmUseCase {}

class _MockArchiver extends Mock implements RingArchiver {}

class _MockPruner extends Mock implements ChatHistoryPruner {}

class _MockWalk extends Mock implements WalkUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockSettings extends Mock implements SettingsRepository {}

class _MockHolidays extends Mock implements HolidayRefresher {}

class _MockAccess extends Mock implements HolidayCalendarAccess {}

class _MockDiaryRepo extends Mock implements DiaryRepository {}

class _MockDiaryUseCase extends Mock implements DiaryUseCase {}

class _MockPlaceSource extends Mock implements PlaceSource {}

class _MockChatSession extends Mock implements ChatSession {
  _MockChatSession() {
    when(
      () => target,
    ).thenReturn((vendor: ChatVendor.anthropic, model: 'claude-test'));
    when(() => attachmentRoom).thenReturn((
      images: 12,
      docs: 5,
      docBytes: AttachmentRules.maxDocBytesPerConversation,
    ));
  }
}

class _MockChatHistory extends Mock implements ChatHistoryRepository {}

class _FakeCalendar implements HolidayCalendar {
  @override
  HolidaySource source = const HolidaySource.bundled(
    firstYear: 2026,
    lastYear: 2027,
  );

  @override
  String? nameOf(DateTime date) => null;
}

/// 위젯을 눌러 연 횟수만큼 [takeLaunch] 가 한 번씩 true.
class _FakeWidget implements NextAlarmWidget {
  var launches = 0;

  @override
  Future<void> show(List<WidgetRing> upcoming) async {}

  @override
  Future<bool> takeLaunch() async {
    if (launches == 0) return false;
    launches--;
    return true;
  }
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
  late _MockArchiver archiver;
  late _MockPruner pruner;
  late _MockWalk walk;
  late _MockRequester notification;
  late _MockHolidays holidays;
  late _MockAccess calendarAccess;
  late _FakeCalendar calendar;
  late _MemorySettings memorySettings;
  late _FakeWidget homeWidget;
  late _MockDiaryUseCase diary;
  late _MockWeather weather;
  late PrefsLockRepository lockRepo;
  late MutableClock clock;

  setUpAll(() {
    registerFallbackValue(PeriodKind.week);
    registerFallbackValue(const EntryFilter.all());
    registerFallbackValue(MapPeriod.day(DateTime(2026)));
  });
  setUp(() async {
    // 네이티브 디스패처 자리: 헤드리스 일이 없어 awaitIdle 에 바로 답한다.
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(backgroundChannel, (call) async => null);
    alarms = _MockAlarmUseCase();
    archiver = _MockArchiver();
    when(() => archiver.archive()).thenAnswer((_) async {});
    pruner = _MockPruner();
    when(() => pruner.prune()).thenAnswer((_) => Future.value());
    walk = _MockWalk();
    notification = _MockRequester();
    holidays = _MockHolidays();
    when(
      () => holidays.refresh(force: any(named: 'force')),
    ).thenAnswer((_) async {});
    when(() => holidays.refresh()).thenAnswer((_) async {});
    when(() => holidays.refreshed).thenAnswer((_) => const Stream.empty());
    calendar = _FakeCalendar();
    calendarAccess = _MockAccess();
    when(calendarAccess.check).thenAnswer((_) async => PermissionStatus.denied);
    when(() => calendarAccess.refresher).thenReturn(holidays);
    memorySettings = _MemorySettings();
    homeWidget = _FakeWidget();
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
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    lockRepo = PrefsLockRepository(prefs);
    clock = MutableClock(DateTime.now());
    diary = _MockDiaryUseCase();
    weather = _MockWeather();
    whenListen(
      weather,
      const Stream<WeatherState>.empty(),
      initialState: const WeatherState.empty(WeatherProblem.offline),
    );
    when(weather.shown).thenAnswer((_) async {});
    when(weather.resumed).thenAnswer((_) async {});
    when(weather.refresh).thenAnswer((_) async {});
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
        ChatModelChoice(chatSettings, chatCatalog, chatVerifier, const Clock()),
      )
      ..registerSingleton<ChatHistorySettings>(FakeChatHistorySettings())
      ..registerSingleton<DiaryRepository>(diaryRepo)
      ..registerSingleton<DiaryPreferences>(PrefsDiaryPreferences(prefs))
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth())
      ..registerSingleton<MediaPickGuard>(MediaPickGuard());
    // 설정 화면을 열면 셸의 지도 기록 cubit 을 다시 걸어 만든다 — 만들 때 보관 기간만 읽는다.
    final locationPrefs = _MockLocationPrefs();
    when(() => locationPrefs.retention).thenReturn(RecordRetention.never);
    getIt
      ..registerSingleton<LocationRecorder>(_MockRecorder())
      ..registerSingleton<BackgroundLocationAccess>(_MockAlwaysAccess())
      ..registerSingleton<LocationPreferences>(locationPrefs)
      ..registerSingleton<LocationRepository>(_MockLocationRepository());
    getIt
      ..registerSingleton<MapOpenRequests>(MapOpenRequests())
      ..registerSingleton<Workspace>(const UnusedWorkspace())
      ..registerSingleton<AttachmentLoader>(const UnusedAttachmentLoader())
      ..registerSingleton<ChatFilePicker>(const NoopChatFilePicker())
      ..registerSingleton<ChatSession>(_MockChatSession())
      ..registerSingleton<ChatHistoryRepository>(_MockChatHistory())
      ..registerSingleton<WikiRepository>(FakeWikiRepository())
      ..registerSingleton<OpenConversation>(OpenConversation())
      ..registerSingleton<ChatTrace>(const NoopChatTrace())
      ..registerSingleton<PlaceSource>(_MockPlaceSource())
      ..registerFactory<WeatherCubit>(() => weather);
    getIt
      ..registerSingleton<AlarmUseCase>(alarms)
      ..registerSingleton<RingArchiver>(archiver)
      ..registerSingleton<ChatHistoryPruner>(pruner)
      ..registerSingleton<WalkUseCase>(walk)
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<HolidayRefresher>(holidays)
      ..registerSingleton<HolidayCalendar>(calendar)
      ..registerSingleton<HolidayCalendarAccess>(calendarAccess)
      ..registerSingleton<SettingsRepository>(memorySettings)
      ..registerSingleton<NextAlarmWidget>(homeWidget)
      ..registerSingleton<AlarmPermissions>(
        AlarmPermissions(
          notification: notification,
          exactAlarm: exactAlarm,
          fullScreenIntent: fullScreen,
        ),
      );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(backgroundChannel, null);
    return getIt.reset();
  });

  Future<StepGoalCubit> pump(
    WidgetTester tester, {
    SettingsRepository? settings,
  }) async {
    if (settings == null) {
      final mock = _MockSettings();
      when(mock.load).thenReturn(const AppSettings());
      settings = mock;
    }
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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

  /// 하단 탭을 이름으로 누른다(일기 빈 상태 안내도 같은 책 아이콘을 쓴다).
  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 도구 탭의 상단 탭을 이름으로 누른다.
  Future<void> tapToolsTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(of: find.byType(TabBar), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  ToolsSection toolsSection(WidgetTester tester) => tester
      .widget<ToolsTab>(find.byType(ToolsTab, skipOffstage: false))
      .section;

  /// 보이는 앱바의 ⋮ 를 열고 [key] 항목을 누른다.
  Future<void> openMenu(WidgetTester tester, String key) async {
    await tester.tap(find.byIcon(Icons.more_vert).hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('첫 탭은 도구 › 알람, 시작할 때 예약을 동기화한다', (tester) async {
    await pump(tester);

    expect(onstage(AlarmListPage), isTrue);
    expect(onstage(DiaryTab), isFalse);
    expect(onstage(WalkHomePage), isFalse);
    verify(alarms.sync).called(1);
  });

  testWidgets('탭 아이콘은 선택 시 채워진 변형을 쓴다', (tester) async {
    await pump(tester);

    final destinations = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .toList();
    IconData icon(Widget? w) => (w! as Icon).icon!;
    expect(icon(destinations[0].icon), Icons.handyman_outlined);
    expect(icon(destinations[0].selectedIcon), Icons.handyman);
    expect(icon(destinations[1].icon), Icons.menu_book_outlined);
    expect(icon(destinations[1].selectedIcon), Icons.menu_book);
    expect(icon(destinations[2].icon), Icons.chat_bubble_outline);
    expect(icon(destinations[2].selectedIcon), Icons.chat_bubble);
  });

  testWidgets('하단 탭은 도구 · 일기 · 물어보기 셋이고 통근 · 설정 탭은 없다', (tester) async {
    await pump(tester);

    final labels = [
      for (final d in tester.widgetList<NavigationDestination>(
        find.byType(NavigationDestination),
      ))
        d.label,
    ];
    expect(labels, ['도구', '일기', '물어보기']);
    expect(find.byType(CommuteTab, skipOffstage: false), findsNothing);
    expect(ShellTab.values, [ShellTab.tools, ShellTab.diary, ShellTab.chat]);
    expect(onstage(ToolsTab), isTrue);

    await tapTab(tester, '일기');
    expect(onstage(DiaryTab), isTrue);
    expect(find.byType(StoryRingRow), findsOneWidget);
  });

  testWidgets('일기 탭: 스낵바가 떠도 ＋ 를 가리지 않는다(＋ 가 위로 비킨다)', (tester) async {
    await pump(tester);
    await tapTab(tester, '일기');
    final fab = find.byTooltip('새 기록');
    final before = tester.getRect(fab);

    // 휴지통으로 옮기기 · 되살리기처럼 위에 얹힌 화면에서 띄운 것과 같은(앱 전체) 메신저.
    AppSnackBar.show(
      tester.element(find.byType(StoryRingRow)),
      message: '휴지통으로 옮겼어요',
      type: AppSnackBarType.success,
    );
    await tester.pumpAndSettle();

    final snack = tester.getRect(find.byType(SnackBar));
    final after = tester.getRect(fab);
    expect(after.overlaps(snack), isFalse, reason: '$after ∩ $snack');
    expect(after.right, before.right);
  });

  testWidgets('시작할 때 고아 미디어 청소를 한 번 부르고, 실패해도 화면은 뜬다', (tester) async {
    when(diary.cleanOrphans).thenAnswer((_) => Future.error(Exception('io')));
    await pump(tester);

    verify(diary.cleanOrphans).called(1);
    expect(tester.takeException(), isNull);
    expect(onstage(ToolsTab), isTrue);
  });

  Future<void> enableDiaryLock() async {
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
  }

  testWidgets('일기는 잠긴 채 시작하고, 풀었다가 백그라운드에 오래 있다 돌아오면 다시 잠긴다', (tester) async {
    await enableDiaryLock();
    await pump(tester);
    await tapTab(tester, '일기');
    expect(find.byType(PinPad), findsOneWidget);
    expect(find.byType(StoryRingRow, skipOffstage: false), findsNothing);

    for (final d in '1234'.split('')) {
      await tester.tap(find.widgetWithText(TextButton, d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.byType(StoryRingRow), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.advance(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byType(StoryRingRow, skipOffstage: false), findsNothing);
    expect(find.byType(PinPad), findsOneWidget);
  });

  testWidgets('일기가 잠겨 있어도 알람 울림 화면(셸 바깥 라우트)은 보인다', (tester) async {
    await enableDiaryLock();
    await pump(tester);
    await tapTab(tester, '일기');
    expect(find.byType(PinPad), findsOneWidget);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('ringing')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ringing').hitTestable(), findsOneWidget);
    expect(find.byType(PinPad), findsNothing);
  });

  testWidgets('탭을 누르면 해당 화면으로 바뀐다 — 도구는 알람 상단 탭부터', (tester) async {
    await pump(tester);

    await tapTab(tester, '도구');
    expect(onstage(AlarmListPage), isTrue);
    expect(find.text('알람이 없어요'), findsOneWidget);
    expect(onstage(DiaryTab), isFalse);

    await tapTab(tester, '물어보기');
    expect(onstage(ChatTab), isTrue);
    expect(onstage(AlarmListPage), isFalse);
  });

  /// 3초 동안 잘게 넘기며 본, [finders] 각각의 glow 불투명도 최댓값(같은 순서).
  Future<List<double>> peakGlows(
    WidgetTester tester,
    List<Finder> finders,
  ) async {
    final peaks = List.filled(finders.length, 0.0);
    const step = Duration(milliseconds: 50);
    for (var t = Duration.zero; t < const Duration(seconds: 3); t += step) {
      await tester.pump(step);
      for (var i = 0; i < finders.length; i++) {
        for (final e in finders[i].evaluate()) {
          final value = (e.widget as FadeTransition).opacity.value;
          if (value > peaks[i]) peaks[i] = value;
        }
      }
    }
    return peaks;
  }

  Future<double> peakGlow(WidgetTester tester, Finder finder) async =>
      (await peakGlows(tester, [finder])).single;

  const glowKey = Key('row-highlight-glow');

  /// 권한 행 [row] 를 감싼 RowHighlight 의 glow.
  Finder permissionGlow(String row) => find.descendant(
    of: find.ancestor(
      of: find.byKey(Key('settings-permission-$row')),
      matching: find.byType(RowHighlight),
    ),
    matching: find.byKey(glowKey),
  );

  testWidgets('물어보기 [설정 열기] → 물어보기 설정 화면이 열리고 연결 행이 glow', (tester) async {
    await pump(tester);
    await tapTab(tester, '물어보기');

    await tester.tap(find.text('설정 열기'));
    final peak = await peakGlow(
      tester,
      find.descendant(
        of: find.byType(ChatSettingsPage),
        matching: find.byKey(glowKey),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatSettingsPage), findsOneWidget);
    expect(
      tester
          .widget<ChatSettingsPage>(find.byType(ChatSettingsPage))
          .highlightConnection,
      isTrue,
    );
    expect(peak, greaterThan(0));
    expect(onstage(ChatTab), isFalse);
  });

  testWidgets('⋮ › 물어보기 설정으로 열면 glow 가 없다', (tester) async {
    await pump(tester);
    await tapTab(tester, '물어보기');

    await tester.tap(find.byIcon(Icons.more_vert).hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-settings-chat')));
    final peak = await peakGlow(
      tester,
      find.descendant(
        of: find.byType(ChatSettingsPage),
        matching: find.byKey(glowKey),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChatSettingsPage), findsOneWidget);
    expect(
      tester
          .widget<ChatSettingsPage>(find.byType(ChatSettingsPage))
          .highlightConnection,
      isFalse,
    );
    expect(peak, 0);
  });

  testWidgets('일기 ⋮ 는 잠긴 동안 앱 설정만, 앱 설정 화면이 열린다', (tester) async {
    await enableDiaryLock();
    await pump(tester);

    await tester.tap(find.byIcon(Icons.more_vert).hitTestable());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-settings-diary')), findsNothing);
    await tester.tap(find.byKey(const Key('menu-settings-app')));
    await tester.pumpAndSettle();

    expect(find.byType(AppSettingsPage), findsOneWidget);
  });

  testWidgets('시작할 때와 앱이 돌아올 때 울림 기록을 옮겨 담는다', (tester) async {
    await pump(tester);
    verify(() => archiver.archive()).called(1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    verify(() => archiver.archive()).called(1);
  });

  testWidgets('시작하면 대화 정리를 부른다', (tester) async {
    await pump(tester);

    verify(() => pruner.prune()).called(greaterThanOrEqualTo(1));
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

  testWidgets('홈 화면 위젯을 눌러 열면 도구 탭의 알람으로 시작한다', (tester) async {
    homeWidget.launches = 1;
    await pump(tester);

    expect(onstage(AlarmListPage), isTrue);
    expect(onstage(DiaryTab), isFalse);
    expect(toolsSection(tester), ToolsSection.alarm);
  });

  testWidgets('걷기 상단 탭을 보던 앱을 위젯으로 다시 열면(복귀) 도구 › 알람으로 바꾼다', (tester) async {
    await pump(tester);
    await tapTab(tester, '도구');
    await tapToolsTab(tester, '걷기');
    expect(toolsSection(tester), ToolsSection.walk);
    await tapTab(tester, '일기');

    homeWidget.launches = 1;
    resume(tester);
    await tester.pumpAndSettle();

    expect(onstage(AlarmListPage), isTrue);
    expect(toolsSection(tester), ToolsSection.alarm);
  });

  testWidgets('위젯으로 열지 않은 복귀는 탭을 그대로 둔다', (tester) async {
    await pump(tester);
    await tapTab(tester, '물어보기');

    resume(tester);
    await tester.pumpAndSettle();

    expect(onstage(ChatTab), isTrue);
  });

  testWidgets('도구에서 고른 상단 탭은 다른 탭에 다녀와도 그대로다', (tester) async {
    await pump(tester);
    await tapTab(tester, '도구');
    await tapToolsTab(tester, '걷기');
    await tapTab(tester, '일기');
    await tapTab(tester, '도구');

    expect(toolsSection(tester), ToolsSection.walk);
    expect(onstage(WalkHomePage), isTrue);
  });

  testWidgets('알람 권한 배너 → 알람 설정 화면의 거부된 권한 행이 glow, 돌아오면 권한을 다시 읽는다', (
    tester,
  ) async {
    when(notification.check).thenAnswer((_) async => PermissionStatus.denied);
    await pump(tester);
    await tapTab(tester, '도구');
    expect(find.text('알람이 울리지 않을 수 있어요'), findsOneWidget);

    await tester.tap(find.text('알람이 울리지 않을 수 있어요'));
    final [denied, granted] = await peakGlows(tester, [
      permissionGlow('notification'),
      permissionGlow('exact-alarm'),
    ]);
    await tester.pumpAndSettle();
    expect(find.byType(AlarmSettingsPage), findsOneWidget);
    expect(
      tester
          .widget<AlarmSettingsPage>(find.byType(AlarmSettingsPage))
          .highlightPermissions,
      isTrue,
    );
    expect(denied, greaterThan(0));
    expect(granted, 0);
    expect(find.text('허용 필요 ›'), findsOneWidget);

    // 알람 설정 화면에서 시스템 설정으로 나가 알림을 허용하고 돌아왔다.
    when(notification.check).thenAnswer((_) async => PermissionStatus.granted);
    clearInteractions(alarms);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    verifyInOrder([alarms.sync, alarms.list]);
    expect(onstage(AlarmListPage), isTrue);
    expect(find.text('알람이 울리지 않을 수 있어요'), findsNothing);
  });

  testWidgets('알람 설정 화면을 연 채 복귀하면 권한 행을 다시 읽는다', (tester) async {
    when(notification.check).thenAnswer((_) async => PermissionStatus.denied);
    await pump(tester);
    await tapTab(tester, '도구');
    await openMenu(tester, 'menu-settings-alarm');
    expect(find.text('허용 필요 ›'), findsOneWidget);

    // 시스템 설정에서 알림을 허용하고 돌아왔다.
    when(notification.check).thenAnswer((_) async => PermissionStatus.granted);
    resume(tester);
    await tester.pumpAndSettle();

    expect(find.text('허용 필요 ›'), findsNothing);
    expect(find.text('허용됨'), findsNWidgets(3));
  });

  testWidgets('알람 설정 화면: 출처 · 캘린더 권한을 읽고, 시스템 설정에서 허용하고 돌아오면 다시 읽는다', (
    tester,
  ) async {
    await pump(tester);
    await tapTab(tester, '도구');
    await openMenu(tester, 'menu-settings-alarm');
    expect(find.text('내장 표 2026–2027'), findsOneWidget);
    expect(find.text('캘린더 허용 필요 ›'), findsOneWidget);
    clearInteractions(alarms);

    when(
      calendarAccess.check,
    ).thenAnswer((_) async => PermissionStatus.granted);
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

    await tapTab(tester, '도구');

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

  testWidgets('걸음 목표를 낮춰 달성해도 걷기를 열 때 한 번만 축하한다', (tester) async {
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
    // 도구 › 알람 ⋮ › 앱 설정 › 걷기 설정 — 걷기 화면은 가려져 있다.
    await tapTab(tester, '도구');
    await openMenu(tester, 'menu-settings-app');
    await tester.tap(find.byKey(const Key('app-settings-open-walk')));
    await tester.pumpAndSettle();
    expect(find.byType(WalkSettingsPage), findsOneWidget);

    // 걷기 설정의 목표 시트가 고른 값을 반영한 것과 같다.
    await goal.select(6000);
    await tester.pumpAndSettle();

    expect(celebrations, 0);
    expect(settings.value.goalCelebratedOn, isNull);
    expect(settings.value.stepGoal, 6000);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator
      ..pop()
      ..pop();
    await tester.pumpAndSettle();
    expect(celebrations, 0);
    await tapToolsTab(tester, '걷기');

    expect(celebrations, 1);
    expect(settings.value.goalCelebratedOn, DateTime(2026, 9, 23));
    expect(settings.value.stepGoal, 6000);
  });

  testWidgets('도구 › 걷기 ⋮ › 걷기 설정에서 목표를 낮춰 달성하면 돌아왔을 때 한 번 축하한다', (
    tester,
  ) async {
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
    // 걷기 화면을 보고 있다 — 아직 목표에 못 미친다.
    await tapTab(tester, '도구');
    await tapToolsTab(tester, '걷기');
    expect(celebrations, 0);

    // 그 화면 ⋮ › 걷기 설정 — 셸 위에 얹혀 걷기 화면을 가린다.
    await openMenu(tester, 'menu-settings-walk');
    expect(find.byType(WalkSettingsPage), findsOneWidget);

    // 걷기 설정의 목표 시트가 고른 값을 반영한 것과 같다.
    await goal.select(6000);
    await tester.pumpAndSettle();

    expect(celebrations, 0);
    expect(settings.value.goalCelebratedOn, isNull);

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    expect(celebrations, 1);
    expect(settings.value.goalCelebratedOn, DateTime(2026, 9, 23));
  });

  group('헤드리스 작업 기다리기(awaitIdle)', () {
    late List<String> calls;
    late Completer<void> idle;

    void answerAwaitIdle(WidgetTester tester, {bool never = false}) {
      calls = [];
      idle = Completer<void>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        backgroundChannel,
        (call) async {
          calls.add(call.method);
          if (call.method == 'awaitIdle') {
            if (never) return Completer<Object?>().future;
            await idle.future;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          backgroundChannel,
          null,
        ),
      );
    }

    testWidgets('시작 sync 는 네이티브가 헤드리스 작업이 끝났다고 답한 뒤에 한다', (tester) async {
      answerAwaitIdle(tester);
      await pump(tester);

      expect(calls, ['awaitIdle']);
      verifyNever(alarms.sync);
      verifyNever(() => holidays.refresh());

      idle.complete();
      await tester.pumpAndSettle();

      verifyInOrder([() => holidays.refresh(), alarms.sync, alarms.list]);
    });

    testWidgets('복귀 sync 도 awaitIdle 응답 뒤에 한다', (tester) async {
      answerAwaitIdle(tester);
      idle.complete();
      await pump(tester);
      clearInteractions(alarms);
      idle = Completer<void>();

      resume(tester);
      await tester.pumpAndSettle();
      expect(calls, ['awaitIdle', 'awaitIdle']);
      verifyNever(alarms.sync);

      idle.complete();
      await tester.pumpAndSettle();
      verify(alarms.sync).called(1);
    });

    testWidgets('응답이 없으면 시간 한도(backgroundIdleTimeout) 뒤 그냥 sync 한다', (
      tester,
    ) async {
      answerAwaitIdle(tester, never: true);
      final start = tester.binding.clock.now();
      final syncedAfter = <Duration>[];
      when(alarms.sync).thenAnswer((_) async {
        syncedAfter.add(tester.binding.clock.now().difference(start));
      });
      await pump(tester);
      await tester.pump(backgroundIdleTimeout);
      await tester.pumpAndSettle();

      expect(syncedAfter, hasLength(1));
      expect(syncedAfter.single, greaterThanOrEqualTo(backgroundIdleTimeout));
    });

    testWidgets('네이티브 resync 는 awaitIdle 을 묻지 않는다(디스패처가 그 일을 돌리는 중이다)', (
      tester,
    ) async {
      answerAwaitIdle(tester);
      idle.complete();
      await pump(tester);
      calls.clear();

      final reply = platformResync(tester);
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
      expect(await reply, isNotNull);
    });
  });

  group('지도 상단 탭', () {
    late _MockMapView mapView;
    late _MockRecorder recorder;

    setUp(() {
      mapView = _MockMapView();
      recorder = _MockRecorder();
      final access = _MockAlwaysAccess();
      final prefs = _MockLocationPrefs();
      whenListen(
        mapView,
        const Stream<MapViewState>.empty(),
        initialState: MapViewState.empty(MapPeriod.day(DateTime(2026, 10, 10))),
      );
      when(mapView.refresh).thenAnswer((_) async {});
      when(() => mapView.show(any())).thenAnswer((_) async {});
      when(
        () => recorder.status(),
      ).thenAnswer((_) async => const RecorderStatus.off());
      when(access.check).thenAnswer((_) async => AlwaysAccess.denied);
      when(access.hasActivityRecognition).thenAnswer((_) async => false);
      when(access.hasNotification).thenAnswer((_) async => false);
      when(() => prefs.retention).thenReturn(RecordRetention.never);
      final locations = _MockLocationRepository();
      when(locations.hasAnyPoint).thenAnswer((_) async => true);
      getIt
        ..unregister<LocationRecorder>()
        ..unregister<BackgroundLocationAccess>()
        ..unregister<LocationPreferences>()
        ..unregister<LocationRepository>();
      getIt
        ..registerFactory<MapViewCubit>(() => mapView)
        ..registerSingleton<LocationRecorder>(recorder)
        ..registerSingleton<BackgroundLocationAccess>(access)
        ..registerSingleton<LocationPreferences>(prefs)
        ..registerSingleton<LocationRepository>(locations)
        ..registerFactory<TileProvider>(StubTileProvider.new)
        ..registerSingleton<MapStyleCubit>(
          MapStyleCubit(FakeMapStylePreferences()),
          dispose: (c) => c.close(),
        );
    });

    testWidgets('지도를 보던 중 복귀하면 기록 상태와 지도를 다시 읽는다', (tester) async {
      await pump(tester);
      await tapTab(tester, '도구');
      await tapToolsTab(tester, '지도');
      expect(onstage(MapTab), isTrue);
      clearInteractions(mapView);
      clearInteractions(recorder);

      resume(tester);
      await tester.pumpAndSettle();

      verify(mapView.refresh).called(1);
      verify(() => recorder.status()).called(1);
    });

    /// 일기 탭에서 잠금을 푼 뒤 도구 › 지도로 간다.
    Future<void> openMapUnlocked(WidgetTester tester) async {
      await enableDiaryLock();
      await pump(tester);
      await tapTab(tester, '일기');
      for (final d in '1234'.split('')) {
        await tester.tap(find.widgetWithText(TextButton, d));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      await tapTab(tester, '도구');
      await tapToolsTab(tester, '지도');
    }

    /// 백그라운드에 오래 있다 돌아와 다시 잠근다.
    Future<void> relockByBackground(WidgetTester tester) async {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      clock.advance(const Duration(minutes: 2));
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
    }

    testWidgets('스토리 고르기를 연 채 다시 잠기면 시트가 닫힌다', (tester) async {
      await openMapUnlocked(tester);
      await tester.tap(find.text('스토리'));
      await tester.pumpAndSettle();
      expect(find.byType(StoryPickerSheet), findsOneWidget);

      await relockByBackground(tester);

      expect(find.byType(StoryPickerSheet, skipOffstage: false), findsNothing);
      expect(find.byType(PinPad).hitTestable(), findsOneWidget);
    });

    testWidgets('지도 ⋮ 를 연 채 다시 잠기면 메뉴가 닫힌다', (tester) async {
      await openMapUnlocked(tester);
      await tester.tap(find.byIcon(Icons.more_vert).hitTestable());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('menu-settings-map')), findsOneWidget);

      await relockByBackground(tester);

      expect(find.byKey(const Key('menu-settings-map')), findsNothing);
      expect(find.byKey(const Key('menu-settings-app')), findsNothing);
    });

    testWidgets('지도 설정에서 돌아오면 기록 상태와 지도를 다시 읽는다', (tester) async {
      await pump(tester);
      await tapTab(tester, '도구');
      await tapToolsTab(tester, '지도');
      await openMenu(tester, 'menu-settings-map');
      expect(find.byType(MapSettingsPage), findsOneWidget);
      clearInteractions(mapView);
      clearInteractions(recorder);

      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();

      expect(onstage(MapTab), isTrue);
      verify(mapView.refresh).called(1);
      verify(() => recorder.status()).called(1);
    });

    final trip = Story(
      id: 'jeju',
      title: '제주 여행',
      status: StoryStatus.open,
      startedAt: DateTime(2026, 10, 6),
      createdAt: DateTime(2026, 10, 6),
    );

    testWidgets('스토리 뷰어의 지도 요청이 오면 도구 › 지도로 가서 그 스토리를 읽는다', (tester) async {
      await pump(tester);
      expect(onstage(MapTab), isFalse);

      getIt<MapOpenRequests>().open(trip);
      await tester.pumpAndSettle();

      expect(onstage(MapTab), isTrue);
      verify(() => mapView.show(MapPeriod.story(trip))).called(1);
    });

    testWidgets('셸 위에 얹힌 화면(스토리 페이지 등)에서 온 요청이면 그 화면을 닫고 지도를 보인다', (
      tester,
    ) async {
      await pump(tester);
      // 스토리 페이지 → 뷰어 순서로 얹혔다. 뷰어는 스스로 닫고 요청한다.
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('스토리 페이지')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('스토리 페이지'), findsOneWidget);

      getIt<MapOpenRequests>().open(trip);
      await tester.pumpAndSettle();

      expect(find.text('스토리 페이지'), findsNothing);
      expect(onstage(MapTab), isTrue);
      verify(() => mapView.show(MapPeriod.story(trip))).called(1);
    });

    testWidgets('잠겨 있어도 도구 › 지도로 옮겨 가고 PIN 을 묻는다', (tester) async {
      await enableDiaryLock();
      await pump(tester);

      getIt<MapOpenRequests>().open(trip);
      await tester.pumpAndSettle();

      expect(find.byType(PinPad).hitTestable(), findsOneWidget);
      verify(() => mapView.show(MapPeriod.story(trip))).called(1);
    });

    testWidgets('다른 상단 탭을 보던 중 복귀하면 지도는 읽지 않는다', (tester) async {
      await pump(tester);
      await tapTab(tester, '도구');
      await tapToolsTab(tester, '지도');
      await tapToolsTab(tester, '알람');
      clearInteractions(mapView);

      resume(tester);
      await tester.pumpAndSettle();

      verifyNever(mapView.refresh);
    });
  });

  group('날씨 상단 탭', () {
    testWidgets('도구 상단 탭은 알람 · 걷기 · 지도 · 날씨', (tester) async {
      await pump(tester);
      final labels = tester
          .widgetList<Tab>(find.byType(Tab))
          .map((t) => t.text)
          .toList();
      expect(labels, ['알람', '걷기', '지도', '날씨']);
    });

    testWidgets('날씨 상단 탭을 누르면 WeatherPage 가 보이고 shown 이 불린다', (tester) async {
      await pump(tester);
      verifyNever(weather.shown);

      await tapToolsTab(tester, '날씨');

      expect(onstage(WeatherPage), isTrue);
      expect(toolsSection(tester), ToolsSection.weather);
      verify(weather.shown).called(1);
    });

    testWidgets('날씨 탭 ⋮ 는 앱 설정만', (tester) async {
      await pump(tester);
      await tapToolsTab(tester, '날씨');

      await tester.tap(find.byIcon(Icons.more_vert).hitTestable());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
      expect(find.byKey(const Key('menu-settings-alarm')), findsNothing);
      expect(find.byKey(const Key('menu-settings-walk')), findsNothing);
      expect(find.byKey(const Key('menu-settings-map')), findsNothing);
    });

    testWidgets('날씨를 보던 중 복귀하면 resumed 를 부른다', (tester) async {
      await pump(tester);
      await tapToolsTab(tester, '날씨');

      resume(tester);
      await tester.pumpAndSettle();

      verify(weather.resumed).called(1);
    });

    testWidgets('다른 상단 탭을 보던 중 복귀하면 부르지 않는다', (tester) async {
      await pump(tester);
      await tapToolsTab(tester, '날씨');
      await tapToolsTab(tester, '알람');

      resume(tester);
      await tester.pumpAndSettle();

      verifyNever(weather.resumed);
    });
  });
}

class _MockMapView extends MockCubit<MapViewState> implements MapViewCubit {}

class _MockWeather extends MockCubit<WeatherState> implements WeatherCubit {}

class _MockRecorder extends Mock implements LocationRecorder {}

class _MockAlwaysAccess extends Mock implements BackgroundLocationAccess {}

class _MockLocationPrefs extends Mock implements LocationPreferences {}

class _MockLocationRepository extends Mock implements LocationRepository {}
