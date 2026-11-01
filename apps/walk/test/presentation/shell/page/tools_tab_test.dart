import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';
import 'package:walk/presentation/alarm/cubit/alarm_list_cubit.dart';
import 'package:walk/presentation/alarm/page/alarm_list_page.dart';
import 'package:walk/presentation/shell/page/tools_tab.dart';
import 'package:walk/presentation/walk/page/walk_home_page.dart';

import '../../settings/settings_harness.dart';

class _MockAlarmUseCase extends Mock implements AlarmUseCase {}

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

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(() async {
    await h.setUp();
    final useCase = _MockAlarmUseCase();
    when(useCase.list).thenAnswer((_) async => []);
    when(useCase.nextRings).thenAnswer((_) async => {});
    when(useCase.pause).thenAnswer((_) async => null);
    when(() => h.walk.permissionDeclinedThisSession).thenReturn(false);
    getIt
      ..registerSingleton<WalkUseCase>(h.walk)
      ..registerSingleton<SettingsRepository>(h.settings);
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
      BlocProvider.value(
        value: alarms,
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
}
