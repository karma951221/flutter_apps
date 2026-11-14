import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/diary/usecase/diary_use_case.dart';
import 'package:walk/domain/location/entity/map_period.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/presentation/diary/page/diary_tab.dart';
import 'package:walk/presentation/map/cubit/map_record_cubit.dart';
import 'package:walk/presentation/map/cubit/map_record_state.dart';
import 'package:walk/presentation/map/cubit/map_view_cubit.dart';
import 'package:walk/presentation/map/cubit/map_view_state.dart';
import 'package:walk/presentation/map/page/map_tab.dart';
import 'package:walk/presentation/shell/page/log_tab.dart';

import '../../../support/stub_tile_provider.dart';
import '../../settings/settings_harness.dart';

class _MockRecord extends MockCubit<MapRecordState> implements MapRecordCubit {}

class _MockView extends MockCubit<MapViewState> implements MapViewCubit {}

class _MockDiaryUseCase extends Mock implements DiaryUseCase {}

void main() {
  final h = SettingsHarness();
  late _MockRecord record;
  late _MockView view;

  setUpAll(() {
    SettingsHarness.registerFallbacks();
    registerFallbackValue(MapPeriod.day(DateTime(2026)));
    registerFallbackValue(const EntryFilter.all());
  });
  setUp(() async {
    await h.setUp();
    when(h.diaryRepo.watchStories).thenAnswer(
      (_) => Stream.value(const <Story>[]),
    );
    when(
      () => h.diaryRepo.watchEntries(any()),
    ).thenAnswer((_) => Stream.value(const []));
    final diary = _MockDiaryUseCase();
    when(diary.maintain).thenAnswer((_) async {});
    getIt
      ..registerSingleton<DiaryRepository>(h.diaryRepo)
      ..registerSingleton<DiaryUseCase>(diary)
      ..registerFactory<TileProvider>(StubTileProvider.new);
    record = _MockRecord();
    view = _MockView();
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
  });
  tearDown(h.tearDown);

  /// 셸처럼 [section] 을 밖에서 쥐고 기록 탭을 그린다. 바뀐 상단 탭은 [changes] 에 쌓인다.
  Future<({ValueNotifier<LogSection> section, List<LogSection> changes})> pump(
    WidgetTester tester, {
    bool selected = true,
    LogSection initial = LogSection.diary,
  }) async {
    final section = ValueNotifier(initial);
    addTearDown(section.dispose);
    final changes = <LogSection>[];
    await h.pump(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<MapRecordCubit>.value(value: record),
          BlocProvider<MapViewCubit>.value(value: view),
        ],
        child: ValueListenableBuilder(
          valueListenable: section,
          builder: (context, value, _) => LogTab(
            selected: selected,
            section: value,
            onSectionChanged: (next) {
              changes.add(next);
              section.value = next;
            },
          ),
        ),
      ),
    );
    return (section: section, changes: changes);
  }

  Finder appBarMenu() => find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.more_vert),
  );

  testWidgets('제목은 기록, 상단 탭은 일기 · 지도', (tester) async {
    await pump(tester);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('기록')),
      findsOneWidget,
    );
    final labels = tester
        .widgetList<Tab>(find.byType(Tab))
        .map((t) => t.text)
        .toList();
    expect(labels, ['일기', '지도']);
    expect(find.byType(DiaryTab), findsOneWidget);
  });

  testWidgets('일기 상단 탭: 🔍 와 ⋮(모든 스토리 · 휴지통 · 일기 설정 · 앱 설정)', (tester) async {
    await pump(tester);

    expect(find.byIcon(Icons.search), findsOneWidget);
    await tester.tap(appBarMenu());
    await tester.pumpAndSettle();
    expect(find.text('모든 스토리'), findsOneWidget);
    expect(find.text('휴지통'), findsOneWidget);
    expect(find.byKey(const Key('menu-settings-diary')), findsOneWidget);
    expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
  });

  testWidgets('잠긴 동안 일기 상단 탭은 🔍 없이 ⋮ 에 앱 설정만', (tester) async {
    await h.lockWithPin();
    await pump(tester);

    expect(find.byIcon(Icons.search), findsNothing);
    await tester.tap(appBarMenu());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-settings-diary')), findsNothing);
    expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
  });

  testWidgets('지도를 누르면 MapTab 이 보이고 ⋮ 에 지도 설정 · 앱 설정', (tester) async {
    final shell = await pump(tester);

    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();

    expect(shell.changes, [LogSection.map]);
    expect(find.byType(MapTab), findsOneWidget);
    expect(find.byIcon(Icons.search), findsNothing);
    await tester.tap(appBarMenu());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-settings-map')), findsOneWidget);
    expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
  });

  testWidgets('잠긴 동안 지도 ⋮ 는 앱 설정만', (tester) async {
    await h.lockWithPin();
    await pump(tester, initial: LogSection.map);

    await tester.tap(appBarMenu());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-settings-map')), findsNothing);
    expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
  });

  testWidgets('보이는 상단 탭만 active — 일기 ↔ 지도', (tester) async {
    await pump(tester, initial: LogSection.map);
    expect(tester.widget<MapTab>(find.byType(MapTab)).active, isTrue);

    await tester.tap(find.text('일기'));
    await tester.pumpAndSettle();
    expect(tester.widget<DiaryTab>(find.byType(DiaryTab)).active, isTrue);
    expect(
      tester.widget<MapTab>(find.byType(MapTab, skipOffstage: false)).active,
      isFalse,
    );
  });

  testWidgets('하단 탭이 기록이 아니면 어느 상단 탭도 active 가 아니다', (tester) async {
    await pump(tester, selected: false);
    expect(tester.widget<DiaryTab>(find.byType(DiaryTab)).active, isFalse);
  });

  testWidgets('셸이 지도로 바꾸면(스토리 → 지도로 보기) 지도 상단 탭으로 넘어간다', (tester) async {
    final shell = await pump(tester);

    shell.section.value = LogSection.map;
    await tester.pumpAndSettle();

    expect(find.byType(MapTab), findsOneWidget);
    expect(shell.changes, isEmpty);
  });

  testWidgets('지도를 가로로 밀어도 일기로 넘어가지 않는다', (tester) async {
    final shell = await pump(tester, initial: LogSection.map);

    await tester.fling(find.byType(MapTab), const Offset(600, 0), 2000);
    await tester.pumpAndSettle();

    expect(shell.changes, isEmpty);
    expect(find.byType(MapTab).hitTestable(), findsOneWidget);
  });
}
