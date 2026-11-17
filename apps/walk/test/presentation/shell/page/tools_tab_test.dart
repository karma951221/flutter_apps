import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/location/entity/map_period.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/alarm/cubit/alarm_list_cubit.dart';
import 'package:walk/presentation/alarm/page/alarm_list_page.dart';
import 'package:walk/presentation/map/cubit/map_record_cubit.dart';
import 'package:walk/presentation/map/cubit/map_record_state.dart';
import 'package:walk/presentation/map/cubit/map_view_cubit.dart';
import 'package:walk/presentation/map/cubit/map_view_state.dart';
import 'package:walk/presentation/map/page/map_tab.dart';
import 'package:walk/presentation/shell/page/tools_tab.dart';
import 'package:walk/domain/transit/entity/transit_point.dart';
import 'package:walk/domain/transit/usecase/transit_point_suggestions.dart';
import 'package:walk/presentation/transit/cubit/transit_cubit.dart';
import 'package:walk/presentation/transit/cubit/transit_state.dart';
import 'package:walk/presentation/transit/page/transit_page.dart';
import 'package:walk/presentation/weather/cubit/weather_cubit.dart';
import 'package:walk/domain/weather/weather_problem.dart';
import 'package:walk/presentation/weather/cubit/weather_state.dart';
import 'package:walk/presentation/weather/page/weather_page.dart';
import 'package:walk/presentation/walk/page/walk_home_page.dart';

import '../../../support/stub_tile_provider.dart';
import '../../settings/settings_harness.dart';

class _MockAlarmUseCase extends Mock implements AlarmUseCase {}

class _MockRecord extends MockCubit<MapRecordState> implements MapRecordCubit {}

class _MockView extends MockCubit<MapViewState> implements MapViewCubit {}

class _MockTransit extends MockCubit<TransitState> implements TransitCubit {}

class _MockSuggestions extends Mock implements TransitPointSuggestions {}

class _MockWeather extends MockCubit<WeatherState> implements WeatherCubit {}

class _NoHolidays implements HolidayCalendar {
  @override
  String? nameOf(DateTime date) => null;

  @override
  HolidaySource get source =>
      const HolidaySource.bundled(firstYear: 2026, lastYear: 2027);
}

void main() {
  final h = SettingsHarness();
  late AlarmListCubit alarms;
  late _MockRecord record;
  late _MockView view;
  late _MockWeather weather;

  setUpAll(() {
    SettingsHarness.registerFallbacks();
    registerFallbackValue(
      const TransitPoint(
        lat: 37.5,
        lng: 126.9,
        label: '',
        source: TransitPointSource.currentLocation,
      ),
    );
    registerFallbackValue(MapPeriod.day(DateTime(2026)));
  });
  setUp(() async {
    await h.setUp();
    final useCase = _MockAlarmUseCase();
    when(useCase.list).thenAnswer((_) async => []);
    when(useCase.nextRings).thenAnswer((_) async => {});
    when(useCase.pause).thenAnswer((_) async => null);
    when(() => h.walk.permissionDeclinedThisSession).thenReturn(false);
    getIt
      ..registerSingleton<WalkUseCase>(h.walk)
      ..registerSingleton<SettingsRepository>(h.settings)
      ..registerFactory<TileProvider>(StubTileProvider.new);
    record = _MockRecord();
    view = _MockView();
    weather = _MockWeather();
    final transit = _MockTransit();
    whenListen(
      transit,
      const Stream<TransitState>.empty(),
      initialState: const TransitState(),
    );
    when(transit.start).thenAnswer((_) async {});
    when(() => transit.fillEmpty(any())).thenAnswer((_) async {});
    final suggestions = _MockSuggestions();
    when(suggestions.load).thenAnswer((_) async => const TransitSuggestions());
    getIt
      ..registerFactory<TransitCubit>(() => transit)
      ..registerSingleton<TransitPointSuggestions>(suggestions);
    whenListen(
      weather,
      const Stream<WeatherState>.empty(),
      initialState: const WeatherState.empty(WeatherProblem.offline),
    );
    when(weather.shown).thenAnswer((_) async {});
    when(weather.refresh).thenAnswer((_) async {});
    whenListen(
      record,
      const Stream<MapRecordState>.empty(),
      initialState: const MapRecordState(
        status: RecorderStatus.off(),
        busy: false,
      ),
    );
    whenListen(
      view,
      const Stream<MapViewState>.empty(),
      initialState: MapViewState.empty(MapPeriod.day(DateTime(2026, 10, 10))),
    );
    when(record.load).thenAnswer((_) async {});
    when(view.refresh).thenAnswer((_) async {});
    when(() => view.show(any())).thenAnswer((_) async {});
    alarms = AlarmListCubit(
      useCase,
      AlarmPermissions(
        notification: h.notification,
        exactAlarm: h.exactAlarm,
        fullScreenIntent: h.fullScreen,
      ),
      getIt<Clock>(),
      _NoHolidays(),
    );
    await alarms.load();
  });
  tearDown(() async {
    await alarms.close();
    await h.tearDown();
  });

  /// 셸처럼 [section] 을 밖에서 쥐고 도구 탭을 그린다. 바뀐 상단 탭은 [changes] 에 쌓인다.
  Future<({ValueNotifier<ToolsSection> section, List<ToolsSection> changes})>
  pump(
    WidgetTester tester, {
    bool active = true,
    ToolsSection initial = ToolsSection.alarm,
  }) async {
    final section = ValueNotifier(initial);
    addTearDown(section.dispose);
    final changes = <ToolsSection>[];
    await h.pump(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: alarms),
          BlocProvider<MapRecordCubit>.value(value: record),
          BlocProvider<MapViewCubit>.value(value: view),
          BlocProvider<WeatherCubit>.value(value: weather),
        ],
        child: ValueListenableBuilder(
          valueListenable: section,
          builder: (context, value, _) => ToolsTab(
            active: active,
            section: value,
            onSectionChanged: (next) {
              changes.add(next);
              section.value = next;
            },
            onOpenAlarmSettings: () {},
          ),
        ),
      ),
    );
    return (section: section, changes: changes);
  }

  /// 상단 탭을 넘겨도 살려 두므로 화면 밖(offstage)까지 찾는다.
  bool walkActive(WidgetTester tester) => tester
      .widget<WalkHomePage>(find.byType(WalkHomePage, skipOffstage: false))
      .active;

  testWidgets('처음엔 알람 목록과 쉬기 아이콘', (tester) async {
    await pump(tester);

    expect(find.text('도구'), findsOneWidget);
    expect(find.byType(AlarmListPage), findsOneWidget);
    expect(find.text('알람이 없어요'), findsOneWidget);
    expect(find.byIcon(Icons.bedtime_outlined), findsOneWidget);
  });

  testWidgets('걷기 상단 탭을 누르면 알리고, 쉬기 아이콘이 사라진다', (tester) async {
    final shell = await pump(tester);

    await tester.tap(find.text('걷기'));
    await tester.pumpAndSettle();

    expect(shell.changes, [ToolsSection.walk]);
    expect(find.byType(WalkHomePage), findsOneWidget);
    expect(find.byIcon(Icons.bedtime_outlined), findsNothing);
  });

  testWidgets('알람 화면을 가로로 밀어도 걷기로 넘어가지 않는다', (tester) async {
    final shell = await pump(tester);

    await tester.fling(find.text('알람이 없어요'), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();

    expect(shell.changes, isEmpty);
    expect(find.byIcon(Icons.bedtime_outlined), findsOneWidget);
    expect(find.byType(AlarmListPage).hitTestable(), findsOneWidget);
  });

  testWidgets('셸이 알람으로 다시 그리면 알람 상단 탭으로 돌아간다', (tester) async {
    final shell = await pump(tester, initial: ToolsSection.walk);
    expect(find.byIcon(Icons.bedtime_outlined), findsNothing);

    shell.section.value = ToolsSection.alarm;
    await tester.pumpAndSettle();

    expect(find.byType(AlarmListPage).hitTestable(), findsOneWidget);
    expect(find.byIcon(Icons.bedtime_outlined), findsOneWidget);
    expect(shell.changes, isEmpty);
  });

  testWidgets('알람 ⋮ 는 알람 기록 · 알람 설정 · 앱 설정, 걷기 ⋮ 는 걷기 설정 · 앱 설정', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('울림 기록'), findsOneWidget);
    expect(find.byKey(const Key('menu-settings-alarm')), findsOneWidget);
    expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('걷기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('울림 기록'), findsNothing);
    expect(find.byKey(const Key('menu-settings-walk')), findsOneWidget);
    expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
  });

  testWidgets('도구 탭이 보이고 걷기 상단 탭일 때만 WalkHomePage.active', (tester) async {
    await pump(tester, initial: ToolsSection.walk);
    expect(walkActive(tester), isTrue);
  });

  testWidgets('도구 탭이 가려져 있으면 걷기 상단 탭이어도 active 가 아니다', (tester) async {
    await pump(tester, active: false, initial: ToolsSection.walk);
    expect(walkActive(tester), isFalse);
  });

  testWidgets('걷기에서 알람으로 돌아가면 WalkHomePage.active 는 거짓', (tester) async {
    await pump(tester, initial: ToolsSection.walk);

    await tester.tap(find.text('알람'));
    await tester.pumpAndSettle();

    expect(walkActive(tester), isFalse);
  });

  testWidgets('도구 상단 탭은 아이콘이 있는 알람 · 걷기 · 날씨 · 길찾기 — 지도는 기록 탭에 있다', (
    tester,
  ) async {
    await pump(tester);
    final tabs = tester.widgetList<Tab>(find.byType(Tab)).toList();
    expect(tabs.map((t) => t.text), ['알람', '걷기', '날씨', '길찾기']);
    expect(tabs.every((t) => t.icon != null), isTrue);
    expect(find.byType(MapTab, skipOffstage: false), findsNothing);
  });

  testWidgets('길찾기 상단 탭을 누르면 TransitPage 가 보인다', (tester) async {
    final shell = await pump(tester);

    await tester.tap(find.text('길찾기'));
    await tester.pumpAndSettle();

    expect(shell.changes, [ToolsSection.transit]);
    expect(find.byType(TransitPage), findsOneWidget);
  });

  testWidgets('길찾기 ⋮ 는 길찾기 키 설정 · 앱 설정', (tester) async {
    await pump(tester, initial: ToolsSection.transit);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('길찾기 키 설정'), findsOneWidget);
    expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
    expect(find.byKey(const Key('menu-settings-walk')), findsNothing);
  });

  testWidgets('360dp · 글자 1.3배에서 상단 탭이 넘치지 않는다', (tester) async {
    await pump(tester);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('길찾기'), findsOneWidget);
  });

  testWidgets('360dp · 글자 1.3배에서 길찾기 본문이 넘치지 않는다', (tester) async {
    await pump(tester, initial: ToolsSection.transit);
    // 하네스가 800x1800 으로 그리므로 그다음에 좁힌다.
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TransitPage), findsOneWidget);
    expect(find.byType(TransitView), findsOneWidget);
  });

  testWidgets('날씨 상단 탭을 누르면 WeatherPage 가 보이고 shown 이 불린다', (tester) async {
    final shell = await pump(tester);

    await tester.tap(find.text('날씨'));
    await tester.pumpAndSettle();

    expect(shell.changes, [ToolsSection.weather]);
    expect(find.byType(WeatherPage), findsOneWidget);
    expect(tester.widget<WeatherPage>(find.byType(WeatherPage)).active, isTrue);
    verify(weather.shown).called(1);
  });

  testWidgets('날씨 탭 ⋮ 는 앱 설정만', (tester) async {
    await pump(tester, initial: ToolsSection.weather);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
    expect(find.byKey(const Key('menu-settings-alarm')), findsNothing);
    expect(find.byKey(const Key('menu-settings-walk')), findsNothing);
    expect(find.byKey(const Key('menu-settings-map')), findsNothing);
  });
}
