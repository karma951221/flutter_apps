import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:latlong2/latlong.dart';
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
import 'package:walk/domain/location/entity/map_style.dart';
import 'package:walk/domain/location/entity/record_interval.dart';
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
import 'package:walk/presentation/map/cubit/map_style_cubit.dart';
import 'package:walk/presentation/map/cubit/map_view_cubit.dart';
import 'package:walk/presentation/map/cubit/map_view_state.dart';
import 'package:walk/presentation/map/page/fullscreen_map_page.dart';
import 'package:walk/presentation/map/page/map_tab.dart';
import 'package:walk/presentation/map/widget/record_chip.dart';
import 'package:walk/presentation/map/widget/story_picker_sheet.dart';
import 'package:walk/presentation/map/widget/timeline_sheet.dart';
import 'package:walk/presentation/map/widget/track_map.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';
import '../../../support/fake_map_style_preferences.dart';
import '../../../support/stub_tile_provider.dart';

class _MockRecord extends MockCubit<MapRecordState> implements MapRecordCubit {}

class _MockView extends MockCubit<MapViewState> implements MapViewCubit {}

class _MockRepo extends Mock implements DiaryRepository {}

class _MockStore extends Mock implements MediaStore {}

/// diaryT0(2026-10-10 09:00) 하루.
final _today = MapPeriod.day(DateTime(2026, 10, 10));

/// 꺼져 있고 저장된 점도 없다 — 처음.
const _firstRun = MapRecordState(
  status: RecorderStatus.off(),
  busy: false,
  hasPoints: false,
  loaded: true,
);

/// 꺼져 있지만 예전 점이 있다.
const _off = MapRecordState(
  status: RecorderStatus.off(),
  busy: false,
  hasPoints: true,
  loaded: true,
);
const _running = MapRecordState(
  status: RecorderStatus.running(RecordMode.normal, stillDetection: true),
  busy: false,
  hasPoints: true,
  loaded: true,
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
  late FakeMapStylePreferences mapStyle;

  setUpAll(() {
    registerFallbackValue(_today);
    registerFallbackValue(const EntryFilter.all());
    registerFallbackValue(RecordInterval.normal);
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
    mapStyle = FakeMapStylePreferences();
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
    when(() => record.setInterval(any())).thenAnswer((_) async {});
    when(() => view.show(any())).thenAnswer((_) async {});
    when(view.refresh).thenAnswer((_) async {});
    getIt
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth())
      ..registerSingleton<DiaryRepository>(repo)
      ..registerSingleton<MediaStore>(store)
      ..registerFactory<TileProvider>(StubTileProvider.new)
      // 펌프할 때 만든다 — 테스트가 저장값을 먼저 바꿀 수 있게.
      ..registerLazySingleton<MapStyleCubit>(
        () => MapStyleCubit(mapStyle),
        dispose: (c) => c.close(),
      );
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
    await pump(
      tester,
      state: MapViewState.empty(_today),
      recordState: _firstRun,
    );

    expect(
      find.widgetWithText(AppPlaceholder, '다닌 길을 지도에 남겨요'),
      findsOneWidget,
    );
    // 칩 대신 안내의 버튼으로 켠다.
    expect(find.byType(RecordChip), findsNothing);

    await tester.tap(find.text('위치 기록 켜기'));
    await tester.pumpAndSettle();
    // 항상 허용이 아직 없으면 이유 설명이 먼저 뜬다.
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();

    verify(record.enable).called(1);
  });

  testWidgets('enable failure shows an error snackbar', (tester) async {
    when(record.enable).thenThrow(PlatformException(code: 'failed'));
    await pump(
      tester,
      state: MapViewState.empty(_today),
      recordState: _firstRun,
    );

    await tester.tap(find.text('위치 기록 켜기'));
    await tester.pumpAndSettle();
    // 항상 허용이 아직 없으면 이유 설명이 먼저 뜬다.
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('위치 기록을 켜지 못했어요. 잠시 뒤 다시 시도해 주세요'), findsOneWidget);
  });

  testWidgets('recording turning on refreshes the map', (tester) async {
    await pump(tester, state: MapViewState.empty(_today), recordState: _off);
    clearInteractions(view);

    records.add(_running);
    await tester.pumpAndSettle();

    verify(view.refresh).called(1);
  });

  testWidgets('first record load does not refresh the map', (tester) async {
    await pump(
      tester,
      state: MapViewState.empty(_today),
      recordState: const MapRecordState(
        status: RecorderStatus.off(),
        busy: false,
      ),
    );
    clearInteractions(view);

    records.add(_running);
    await tester.pumpAndSettle();

    verifyNever(view.refresh);
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
    // 진행 중은 기간 끝으로 보인다(StoryRow 부제).
    expect(
      find.descendant(of: sheet, matching: find.textContaining('진행 중')),
      findsOneWidget,
    );

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

  const denseRunning = MapRecordState(
    status: RecorderStatus.running(
      RecordMode.dense,
      stillDetection: false,
      intervalSec: 10,
    ),
    busy: false,
    hasPoints: true,
    loaded: true,
  );

  Finder intervalTile(RecordInterval interval) =>
      find.byKey(Key('record-interval-${interval.name}'));

  bool checked(WidgetTester tester, RecordInterval interval) => find
      .descendant(
        of: intervalTile(interval),
        matching: find.byIcon(Icons.check),
      )
      .evaluate()
      .isNotEmpty;

  testWidgets('map overlay buttons all carry tooltips', (tester) async {
    await pump(tester, state: MapViewState.ready(_data()));

    for (final key in [
      'map-fullscreen-button',
      'map-style-button',
      'map-record-chip',
    ]) {
      final button = tester.widget<IconButton>(find.byKey(Key(key)));
      expect(button.tooltip, isNotEmpty, reason: key);
    }
    expect(find.byTooltip('전체화면으로 보기'), findsOneWidget);
    expect(find.byTooltip('지도 종류'), findsOneWidget);
  });

  testWidgets('running record is a compact round button, not a card', (
    tester,
  ) async {
    await pump(tester, state: MapViewState.ready(_data()));

    final chip = find.byKey(const Key('map-record-chip'));
    expect(chip, findsOneWidget);
    expect(tester.widget(chip), isA<IconButton>());
    expect(tester.widget<IconButton>(chip).tooltip, '위치 기록 중 · 평소');
    expect(
      find.widgetWithIcon(IconButton, Icons.radio_button_checked),
      findsOneWidget,
    );
    // 접힌 상태 — 주기 목록은 시트를 열어야 보인다.
    expect(find.text('기록 주기'), findsNothing);
    expect(intervalTile(RecordInterval.s5), findsNothing);
    // 전체화면 · 지도 종류 버튼과 같은 왼쪽 열, 그 아래에 쌓인다.
    final style = tester.getRect(find.byKey(const Key('map-style-button')));
    final record = tester.getRect(chip);
    expect(record.left, style.left);
    expect(record.top, greaterThan(style.bottom - 1));
  });

  testWidgets('fixed interval shows a different icon and the interval', (
    tester,
  ) async {
    await pump(
      tester,
      state: MapViewState.ready(_data()),
      recordState: denseRunning,
    );

    final chip = find.byKey(const Key('map-record-chip'));
    expect(
      find.widgetWithIcon(IconButton, Icons.timer_outlined),
      findsOneWidget,
    );
    expect(
      find.widgetWithIcon(IconButton, Icons.radio_button_checked),
      findsNothing,
    );
    expect(tester.widget<IconButton>(chip).tooltip, '위치 기록 중 · 10초마다');
  });

  testWidgets('tapping record button opens the interval sheet', (tester) async {
    await pump(tester, state: MapViewState.ready(_data()));

    await tester.tap(find.byKey(const Key('map-record-chip')));
    await tester.pumpAndSettle();

    expect(find.text('기록 주기'), findsOneWidget);
    expect(find.textContaining('배터리를 더 써요'), findsOneWidget);
    expect(find.text('평소'), findsOneWidget);
    expect(find.text('5초마다'), findsOneWidget);
    expect(find.text('10초마다'), findsOneWidget);
    expect(find.text('30초마다'), findsOneWidget);
    expect(find.text('1분마다'), findsOneWidget);
    expect(checked(tester, RecordInterval.normal), isTrue);
    expect(checked(tester, RecordInterval.s5), isFalse);

    await tester.tap(intervalTile(RecordInterval.s10));
    await tester.pumpAndSettle();
    verify(() => record.setInterval(RecordInterval.s10)).called(1);
    // 고르면 닫힌다.
    expect(find.text('기록 주기'), findsNothing);

    records.add(denseRunning);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map-record-chip')));
    await tester.pumpAndSettle();
    expect(checked(tester, RecordInterval.s10), isTrue);
    expect(checked(tester, RecordInterval.normal), isFalse);

    // 이미 고른 주기는 다시 보내지 않는다.
    await tester.tap(intervalTile(RecordInterval.s10));
    await tester.pumpAndSettle();
    verifyNever(() => record.setInterval(any()));
  });

  testWidgets('interval sheet is disabled while busy', (tester) async {
    await pump(
      tester,
      state: MapViewState.ready(_data()),
      recordState: _running.copyWith(busy: true),
    );

    await tester.tap(find.byKey(const Key('map-record-chip')));
    await tester.pumpAndSettle();

    await tester.tap(intervalTile(RecordInterval.s5));
    await tester.pump();
    verifyNever(() => record.setInterval(any()));
    expect(find.text('기록 주기'), findsOneWidget);
  });

  testWidgets('relocking closes the record sheet', (tester) async {
    await pump(tester, state: MapViewState.ready(_data()));
    await tester.tap(find.byKey(const Key('map-record-chip')));
    await tester.pumpAndSettle();
    expect(find.text('기록 주기'), findsOneWidget);

    await relock(tester);

    expect(find.text('기록 주기', skipOffstage: false), findsNothing);
  });

  testWidgets('blocked shows record-off chip', (tester) async {
    await pump(
      tester,
      state: MapViewState.ready(_data()),
      recordState: const MapRecordState(
        status: RecorderStatus.blocked(RecordMode.normal),
        busy: false,
        access: AlwaysAccess.denied,
        hasPoints: true,
        loaded: true,
      ),
    );

    expect(find.text('권한 필요'), findsOneWidget);
    expect(find.byKey(const Key('map-record-chip')), findsOneWidget);
    expect(
      tester
          .widget<ActionChip>(find.byKey(const Key('map-record-chip')))
          .tooltip,
      '기록 꺼짐 · 위치 권한 필요',
    );

    await tester.tap(find.text('권한 필요'));
    await tester.pumpAndSettle();
    // 항상 허용이 아직 없으면 이유 설명이 먼저 뜬다.
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();
    verify(record.enable).called(1);
  });

  testWidgets('off with stored points and empty period is not first run', (
    tester,
  ) async {
    await pump(tester, state: MapViewState.empty(_today), recordState: _off);

    expect(find.widgetWithText(AppPlaceholder, '이 날은 기록이 없어요'), findsOneWidget);
    expect(find.text('다닌 길을 지도에 남겨요'), findsNothing);
    expect(find.text('기록 꺼짐'), findsOneWidget);
  });

  testWidgets('before record status loads: no first-run card, no chip', (
    tester,
  ) async {
    await pump(
      tester,
      state: MapViewState.empty(_today),
      recordState: const MapRecordState(
        status: RecorderStatus.off(),
        busy: false,
      ),
    );

    expect(find.text('다닌 길을 지도에 남겨요'), findsNothing);
    expect(find.byType(RecordChip), findsNothing);
    expect(find.widgetWithText(AppPlaceholder, '이 날은 기록이 없어요'), findsOneWidget);

    records.add(_firstRun);
    await tester.pumpAndSettle();
    expect(find.text('다닌 길을 지도에 남겨요'), findsOneWidget);
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

    // 핀을 누르면 미리보기만, 미리보기를 누르면 뷰어.
    await tester.tap(find.byKey(const ValueKey('map-pin-a')));
    await tester.pump();
    expect(find.byType(StoryViewerPage), findsNothing);
    await tester.tap(find.byKey(const ValueKey('map-pin-preview-a')));
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

  testWidgets('a grouped pin lists its entries; the picked one opens first', (
    tester,
  ) async {
    await pump(
      tester,
      state: MapViewState.ready(
        _data(entries: [_entry('a'), _entry('b', photo: false)]),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('map-pin-a')));
    await tester.pump();
    expect(find.byKey(const ValueKey('map-pin-preview-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-pin-preview-b')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-pin-preview-b')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final viewer = tester.widget<StoryViewerPage>(find.byType(StoryViewerPage));
    expect(viewer.entryId, 'b');
    expect((viewer.source as EntriesSource).entryIds, ['a', 'b']);
  });

  testWidgets('style button switches tiles and saves the choice', (
    tester,
  ) async {
    await pump(tester, state: MapViewState.ready(_data()));
    TileLayer layer() => tester.widget<TileLayer>(find.byType(TileLayer));
    // 저장한 적이 없으면 단순 — OSM 타일에 색 필터.
    expect(layer().urlTemplate, contains('tile.openstreetmap.org'));
    expect(layer().tileBuilder, isNotNull);

    await tester.tap(find.byKey(const Key('map-style-button')));
    await tester.pumpAndSettle();
    expect(find.text('지도 종류'), findsOneWidget);
    // 단순(기본값) · 기본 · 지형 · 위성 · 어둡게
    for (final style in MapStyle.values) {
      expect(find.byKey(Key('map-style-${style.name}')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('map-style-standard')));
    await tester.pumpAndSettle();

    expect(layer().urlTemplate, contains('tile.openstreetmap.org'));
    expect(layer().tileBuilder, isNull);
    expect(mapStyle.style, MapStyle.standard);
    expect(find.textContaining('CARTO'), findsNothing);
  });

  group('fullscreen', () {
    late List<String> uiModes;

    setUp(() => uiModes = []);

    Future<void> pumpFull(WidgetTester tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
            uiModes.add(call.arguments as String);
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
      await pump(tester, state: MapViewState.ready(_data()));
    }

    TrackMapState mapState(WidgetTester tester) =>
        tester.state<TrackMapState>(find.byType(TrackMap));

    testWidgets('button hides chrome, exit brings it back', (tester) async {
      await pumpFull(tester);
      expect(find.byType(TimelineSheet), findsOneWidget);

      await tester.tap(find.byKey(const Key('map-fullscreen-button')));
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMapPage), findsOneWidget);
      // 기간 머리 · 시트 · 기록 표시 · 지도 종류는 없고 지도와 나가기 버튼만.
      expect(find.byType(TimelineSheet), findsNothing);
      expect(find.text('스토리'), findsNothing);
      expect(find.byKey(const Key('map-record-chip')), findsNothing);
      expect(find.byKey(const Key('map-style-button')), findsNothing);
      expect(find.byType(TrackMap), findsOneWidget);
      expect(uiModes, ['SystemUiMode.immersiveSticky']);

      await tester.tap(find.byKey(const Key('map-fullscreen-exit')));
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMapPage), findsNothing);
      expect(find.byType(TimelineSheet), findsOneWidget);
      expect(find.byKey(const Key('map-record-chip')), findsOneWidget);
      expect(uiModes.last, 'SystemUiMode.edgeToEdge');
    });

    testWidgets('back returns and keeps the camera', (tester) async {
      await pumpFull(tester);
      final before = mapState(tester).camera;

      await tester.tap(find.byKey(const Key('map-fullscreen-button')));
      await tester.pumpAndSettle();
      // 전체화면은 지도 탭 카메라 자리에서 열린다.
      expect(mapState(tester).camera.center, before.center);
      expect(mapState(tester).camera.zoom, before.zoom);

      // 전체화면에서 다른 곳으로 옮긴다.
      mapState(tester).jumpTo((center: const LatLng(35.1, 129.0), zoom: 13));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(FullscreenMapPage), findsNothing);
      expect(find.byType(TimelineSheet), findsOneWidget);
      final after = mapState(tester).camera;
      expect(after.center.latitude, closeTo(35.1, 1e-6));
      expect(after.center.longitude, closeTo(129.0, 1e-6));
      expect(after.zoom, 13);
    });
  });

  testWidgets('saved style is used when the map opens', (tester) async {
    mapStyle.style = MapStyle.standard;
    await pump(tester, state: MapViewState.ready(_data()));

    expect(
      tester.widget<TileLayer>(find.byType(TileLayer)).tileBuilder,
      isNull,
    );
  });

  testWidgets('style changed elsewhere (settings) updates the map', (
    tester,
  ) async {
    await pump(tester, state: MapViewState.ready(_data()));

    final simple = tester.widget<TileLayer>(find.byType(TileLayer)).tileBuilder;
    await getIt<MapStyleCubit>().select(MapStyle.dark);
    await tester.pumpAndSettle();

    final layer = tester.widget<TileLayer>(find.byType(TileLayer));
    // 타일 주소는 그대로, 필터만 바뀐다.
    expect(layer.urlTemplate, contains('tile.openstreetmap.org'));
    expect(layer.tileBuilder, isNotNull);
    expect(layer.tileBuilder, isNot(same(simple)));
  });

  testWidgets('terrain uses OpenTopoMap without an attribution label', (
    tester,
  ) async {
    mapStyle.style = MapStyle.terrain;
    await pump(tester, state: MapViewState.ready(_data()));

    final layer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(layer.urlTemplate, contains('opentopomap.org'));
    expect(layer.subdomains, isNotEmpty);
    expect(layer.maxNativeZoom, 17);
    expect(layer.tileBuilder, isNull);
    expect(find.textContaining('OpenTopoMap'), findsNothing);
  });

  testWidgets(
    'satellite uses Esri World Imagery (z/y/x) without an attribution label',
    (tester) async {
      mapStyle.style = MapStyle.satellite;
      await pump(tester, state: MapViewState.ready(_data()));

      final layer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(
        layer.urlTemplate,
        contains('World_Imagery/MapServer/tile/{z}/{y}/{x}'),
      );
      expect(layer.maxNativeZoom, 18);
      expect(layer.tileBuilder, isNull);
      expect(find.textContaining('Esri'), findsNothing);
    },
  );

  testWidgets('no tile server needs a key', (tester) async {
    for (final style in MapStyle.values) {
      mapStyle.style = style;
      await pump(tester, state: MapViewState.ready(_data()));
      final url = tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate!;
      expect(url, isNot(contains('cartocdn')), reason: style.name);
      expect(url, isNot(contains('key')), reason: style.name);
    }
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
    // 로딩 표시가 보이도록 show 로 다시 읽는다.
    verify(() => view.show(_today)).called(1);
    verifyNever(view.refresh);
  });
}
