import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/location/background_location_access.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/location/entity/day_track.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/map_period.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/entity/stay.dart';
import 'package:walk/domain/location/entity/track_segment.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/diary/viewer/story_viewer_page.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/lock/widget/pin_pad.dart';
import 'package:walk/presentation/map/cubit/map_record_cubit.dart';
import 'package:walk/presentation/map/cubit/map_record_state.dart';
import 'package:walk/presentation/map/cubit/map_view_cubit.dart';
import 'package:walk/presentation/map/cubit/map_view_state.dart';
import 'package:walk/presentation/map/page/map_tab.dart';
import 'package:walk/presentation/map/widget/record_chip.dart';
import 'package:walk/presentation/map/widget/story_picker_sheet.dart';
import 'package:walk/presentation/map/widget/timeline_sheet.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';
import '../../../support/stub_tile_provider.dart';

class _MockRecord extends MockCubit<MapRecordState> implements MapRecordCubit {}

class _MockView extends MockCubit<MapViewState> implements MapViewCubit {}

class _MockRepo extends Mock implements DiaryRepository {}

class _MockStore extends Mock implements MediaStore {}

/// diaryT0(2026-10-10 09:00) 하루.
final _today = MapPeriod.day(DateTime(2026, 10, 10));

const _off = MapRecordState(status: RecorderStatus.off(), busy: false);
const _running = MapRecordState(
  status: RecorderStatus.running(RecordMode.normal, stillDetection: true),
  busy: false,
);

Story _story(String id, String title, {bool open = true, int day = 1}) => Story(
  id: id,
  title: title,
  status: open ? StoryStatus.open : StoryStatus.closed,
  startedAt: DateTime(2026, 9, day),
  endedAt: open ? null : DateTime(2026, 9, day + 2),
  createdAt: DateTime(2026, 9, day),
);

DiaryEntry _entry(String id, {bool photo = true}) => DiaryEntry(
  id: id,
  storyId: Story.dailyId,
  body: '본문 $id',
  occurredAt: DateTime(2026, 10, 10, 12),
  createdAt: DateTime(2026, 10, 10, 12),
  updatedAt: DateTime(2026, 10, 10, 12),
  location: const EntryLocation(lat: 37.5, lng: 127.0),
  media: [if (photo) photoMedia('m-$id')],
  tags: const [],
);

LocationPoint _point(int minute, double lat, {RecordMode? mode}) =>
    LocationPoint(
      recordedAt: DateTime(2026, 10, 10, 9, minute).toUtc(),
      lat: lat,
      lng: 127.0,
      mode: mode ?? RecordMode.normal,
    );

MapViewData _data({MapPeriod? period, List<DiaryEntry> entries = const []}) =>
    MapViewData(
      period: period ?? _today,
      track: DayTrack(
        segments: [
          TrackSegment(
            points: [_point(0, 37.49), _point(30, 37.5)],
            mode: RecordMode.normal,
          ),
        ],
        stays: [
          Stay(
            start: DateTime(2026, 10, 10, 9, 40).toUtc(),
            end: DateTime(2026, 10, 10, 17, 40).toUtc(),
            lat: 37.5,
            lng: 127.0,
            pointCount: 3,
          ),
        ],
      ),
      frequent: const [],
      entries: entries,
      stayNames: const {'37.500,127.000': '회사'},
    );

void main() {
  late PrefsLockRepository lockRepo;
  late MutableClock clock;
  late DiaryLockCubit lock;
  late _MockRecord record;
  late _MockView view;
  late _MockRepo repo;
  late StreamController<MapViewState> views;
  late StreamController<MapRecordState> records;

  setUpAll(() {
    registerFallbackValue(_today);
    registerFallbackValue(const EntryFilter.all());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    lockRepo = PrefsLockRepository(await SharedPreferences.getInstance());
    clock = MutableClock(diaryT0);
    lock = DiaryLockCubit(lockRepo, FakeDeviceAuth(), clock, MediaPickGuard());
    record = _MockRecord();
    view = _MockView();
    repo = _MockRepo();
    views = StreamController<MapViewState>.broadcast();
    records = StreamController<MapRecordState>.broadcast();
    final store = _MockStore();
    when(() => store.resolve(any())).thenReturn(File('/missing.jpg'));
    when(repo.watchStories).thenAnswer(
      (_) => Stream.value([
        _story(Story.dailyId, ''),
        _story('old', '지난 여행', open: false, day: 1),
        _story('jeju', '제주 여행', day: 20),
      ]),
    );
    when(
      () => repo.watchEntries(any()),
    ).thenAnswer((_) => Stream.value([_entry('a')]));
    when(record.load).thenAnswer((_) async {});
    when(record.enable).thenAnswer((_) async {});
    when(() => record.setDense(any())).thenAnswer((_) async {});
    when(() => view.show(any())).thenAnswer((_) async {});
    when(view.refresh).thenAnswer((_) async {});
    getIt
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth())
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<MediaStore>(store)
      ..registerFactory<TileProvider>(StubTileProvider.new);
  });

  tearDown(() async {
    await views.close();
    await records.close();
    await lock.close();
    await getIt.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    required MapViewState state,
    MapRecordState recordState = _running,
    bool settle = true,
  }) async {
    whenListen(view, views.stream, initialState: state);
    whenListen(record, records.stream, initialState: recordState);
    lock.start();
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<DiaryLockCubit>.value(value: lock),
            BlocProvider<MapRecordCubit>.value(value: record),
            BlocProvider<MapViewCubit>.value(value: view),
          ],
          child: const Scaffold(body: MapTab(active: true)),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Future<void> enableLock() async {
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
  }

  Future<void> relock(WidgetTester tester) async {
    await enableLock();
    lock.onPaused();
    clock.advance(const Duration(minutes: 5));
    lock.onResumed();
    await tester.pumpAndSettle();
  }

  testWidgets('locked shows lock input, not map', (tester) async {
    await enableLock();
    await pump(tester, state: MapViewState.ready(_data()));

    expect(find.byType(PinPad), findsOneWidget);
    expect(find.byType(FlutterMap, skipOffstage: false), findsNothing);
    expect(find.byType(RecordChip, skipOffstage: false), findsNothing);
  });

  testWidgets('opening loads record status and shows the current period', (
    tester,
  ) async {
    // 로딩 표시가 돌고 있으니 settle 하지 않는다.
    // cubit 의 첫 상태처럼 시각이 붙은 하루 — 날짜만 남겨 읽는다.
    await pump(
      tester,
      state: MapViewState.loading(MapPeriod.day(diaryT0)),
      settle: false,
    );

    verify(record.load).called(1);
    verify(() => view.show(_today)).called(1);
  });

  testWidgets('relocking closes open timeline sheet', (tester) async {
    await pump(tester, state: MapViewState.ready(_data()));
    expect(find.byType(TimelineSheet), findsOneWidget);
    expect(find.text('회사'), findsOneWidget);

    await relock(tester);

    expect(find.byType(TimelineSheet, skipOffstage: false), findsNothing);
    expect(find.text('회사', skipOffstage: false), findsNothing);
    expect(find.byType(PinPad), findsOneWidget);
  });

  testWidgets('relocking closes the story picker', (tester) async {
    await pump(tester, state: MapViewState.ready(_data()));
    await tester.tap(find.text('스토리'));
    await tester.pumpAndSettle();
    expect(find.byType(StoryPickerSheet), findsOneWidget);

    await relock(tester);

    expect(find.byType(StoryPickerSheet, skipOffstage: false), findsNothing);
  });

  testWidgets('first run shows placeholder with enable button', (tester) async {
    await pump(tester, state: MapViewState.empty(_today), recordState: _off);

    expect(
      find.widgetWithText(AppPlaceholder, '다닌 길을 지도에 남겨요'),
      findsOneWidget,
    );
    // 칩 대신 안내의 버튼으로 켠다.
    expect(find.byType(RecordChip), findsNothing);

    await tester.tap(find.text('위치 기록 켜기'));
    await tester.pumpAndSettle();

    verify(record.enable).called(1);
  });

  testWidgets('segment switches period', (tester) async {
    await pump(tester, state: MapViewState.ready(_data()));

    await tester.tap(find.text('한 달'));
    await tester.pumpAndSettle();
    verify(() => view.show(const MapPeriod.month(2026, 10))).called(1);

    views.add(const MapViewState.empty(MapPeriod.month(2026, 10)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘'));
    await tester.pumpAndSettle();
    verify(() => view.show(_today)).called(1);
  });

  testWidgets('story segment opens picker: open first, daily excluded', (
    tester,
  ) async {
    await pump(tester, state: MapViewState.ready(_data()));

    await tester.tap(find.text('스토리'));
    await tester.pumpAndSettle();

    final sheet = find.byType(StoryPickerSheet);
    expect(sheet, findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('일상')), findsNothing);
    final jeju = tester.getTopLeft(find.text('제주 여행'));
    final old = tester.getTopLeft(find.text('지난 여행'));
    expect(jeju.dy, lessThan(old.dy));
    expect(find.text('진행 중'), findsOneWidget);

    await tester.tap(find.text('지난 여행'));
    await tester.pumpAndSettle();

    verify(
      () => view.show(MapPeriod.story(_story('old', '지난 여행', open: false))),
    ).called(1);
  });

  testWidgets('period header cannot go to future', (tester) async {
    await pump(tester, state: MapViewState.ready(_data()));

    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(next.onPressed, isNull);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
    await tester.pumpAndSettle();
    verify(() => view.show(MapPeriod.day(DateTime(2026, 10, 9)))).called(1);
  });

  testWidgets('past day can go forward', (tester) async {
    await pump(
      tester,
      state: MapViewState.empty(MapPeriod.day(DateTime(2026, 10, 9))),
    );

    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right));
    await tester.pumpAndSettle();
    verify(() => view.show(_today)).called(1);
  });

  testWidgets('record chip toggles dense', (tester) async {
    await pump(tester, state: MapViewState.ready(_data()));

    await tester.tap(find.text('촘촘 기록'));
    await tester.pumpAndSettle();
    verify(() => record.setDense(true)).called(1);

    records.add(
      const MapRecordState(
        status: RecorderStatus.running(RecordMode.dense, stillDetection: true),
        busy: false,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('촘촘 기록 중'));
    await tester.pumpAndSettle();
    verify(() => record.setDense(false)).called(1);
  });

  testWidgets('blocked shows record-off chip', (tester) async {
    await pump(
      tester,
      state: MapViewState.ready(_data()),
      recordState: const MapRecordState(
        status: RecorderStatus.blocked(RecordMode.normal),
        busy: false,
        access: AlwaysAccess.denied,
      ),
    );

    expect(find.text('기록 꺼짐 · 권한 필요'), findsOneWidget);
    expect(find.text('촘촘 기록'), findsNothing);

    await tester.tap(find.text('기록 꺼짐 · 권한 필요'));
    await tester.pumpAndSettle();
    verify(record.enable).called(1);
  });

  testWidgets('off with records shows record-off chip', (tester) async {
    await pump(tester, state: MapViewState.ready(_data()), recordState: _off);

    expect(find.text('기록 꺼짐'), findsOneWidget);
  });

  testWidgets('entry pin opens viewer', (tester) async {
    await pump(
      tester,
      state: MapViewState.ready(_data(entries: [_entry('a')])),
    );

    await tester.tap(find.byKey(const ValueKey('map-pin-a')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final viewer = tester.widget<StoryViewerPage>(find.byType(StoryViewerPage));
    expect(viewer.entryId, 'a');
    expect(viewer.source, isA<EntriesSource>());
    expect((viewer.source as EntriesSource).entryIds, ['a']);
  });

  testWidgets('pins at the same place are grouped with a count', (
    tester,
  ) async {
    await pump(
      tester,
      state: MapViewState.ready(
        _data(entries: [_entry('a'), _entry('b', photo: false)]),
      ),
    );

    expect(find.byKey(const ValueKey('map-pin-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-pin-b')), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('empty period shows placeholder over map', (tester) async {
    await pump(tester, state: MapViewState.empty(_today));

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.widgetWithText(AppPlaceholder, '이 날은 기록이 없어요'), findsOneWidget);
  });

  testWidgets('failure shows retry that refreshes', (tester) async {
    await pump(tester, state: MapViewState.failure(_today));

    expect(
      find.widgetWithText(AppPlaceholder, '지도 기록을 불러오지 못했어요'),
      findsOneWidget,
    );
    clearInteractions(view);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    verify(view.refresh).called(1);
  });
}
