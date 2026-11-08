import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/map_period.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/repository/location_repository.dart';
import 'package:walk/domain/location/usecase/location_sync.dart';
import 'package:walk/domain/location/usecase/stay_namer.dart';
import 'package:walk/presentation/map/cubit/map_view_cubit.dart';
import 'package:walk/presentation/map/cubit/map_view_state.dart';

class _MockLocations extends Mock implements LocationRepository {}

class _MockDiary extends Mock implements DiaryRepository {}

class _MockSync extends Mock implements LocationSync {}

class _MockNamer extends Mock implements StayNamer {}

class _FixedClock extends Clock {
  const _FixedClock();
  @override
  DateTime now() => DateTime(2026, 11, 8, 12);
}

LocationPoint _p(DateTime at, double lat, double lng) =>
    LocationPoint(recordedAt: at, lat: lat, lng: lng, mode: RecordMode.normal);

DiaryEntry _entry(String id, DateTime at, {EntryLocation? location}) =>
    DiaryEntry(
      id: id,
      storyId: 'daily',
      body: '본문',
      occurredAt: at,
      createdAt: at,
      updatedAt: at,
      location: location,
      media: const [],
      tags: const [],
    );

void main() {
  late _MockLocations locations;
  late _MockDiary diary;
  late _MockSync sync;
  late _MockNamer namer;
  late MapViewCubit cubit;
  final day = MapPeriod.day(DateTime(2026, 11, 8));
  final at = DateTime(2026, 11, 8, 9);

  Future<List<DiaryEntry>> search() =>
      diary.locatedEntriesBetween(any(), any(), limit: any(named: 'limit'));

  /// [from] 부터 1분 간격으로 [count] 개, 직선으로 이동한 점(단순화 대상).
  List<LocationPoint> line(DateTime from, int count) => [
    for (var i = 0; i < count; i++)
      _p(from.add(Duration(minutes: i)), 37.5 + i * 0.0005, 127.0),
  ];

  int drawn(MapViewData data) =>
      data.track.segments.fold<int>(0, (a, s) => a + s.points.length);

  Story story(DateTime start, DateTime? end) => Story(
    id: 'trip',
    title: '여행',
    status: end == null ? StoryStatus.open : StoryStatus.closed,
    startedAt: start,
    endedAt: end,
    createdAt: start,
  );

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    locations = _MockLocations();
    diary = _MockDiary();
    sync = _MockSync();
    namer = _MockNamer();
    when(
      () => locations.pointsBetween(any(), any()),
    ).thenAnswer((_) async => []);
    when(search).thenAnswer((_) async => []);
    when(() => sync.run()).thenAnswer((_) async => 0);
    when(() => namer.nameFor(any(), any())).thenAnswer((_) async => '집');
    when(() => locations.placeName(any())).thenAnswer((_) async => null);
    cubit = MapViewCubit(locations, diary, sync, namer, const _FixedClock());
  });
  tearDown(() => cubit.close());

  test('show day loads points, stays and located entries', () async {
    when(() => locations.pointsBetween(any(), any())).thenAnswer(
      (_) async => [
        for (var i = 0; i < 6; i++)
          _p(at.add(Duration(minutes: 3 * i)), 37.5, 127.0),
      ],
    );
    when(search).thenAnswer(
      (_) async => [
        _entry('a', at, location: const EntryLocation(lat: 37.5, lng: 127.0)),
      ],
    );

    await cubit.show(day);

    final state = cubit.state as MapViewReady;
    expect(state.data.entries.map((e) => e.id), ['a']);
    expect(state.data.track.stays, hasLength(1));
    expect(state.data.stayNames, {'37.500,127.000': '집'});
  });

  test('month view simplifies points and never asks the network', () async {
    final start = DateTime(2026, 11, 3, 8);
    when(() => locations.pointsBetween(any(), any())).thenAnswer(
      (_) async => [
        for (var i = 0; i < 1000; i++)
          _p(start.add(Duration(minutes: i)), 37.5 + i * 0.0005, 127.0),
      ],
    );

    await cubit.show(const MapPeriod.month(2026, 11));

    final state = cubit.state as MapViewReady;
    final total = state.data.track.segments.fold<int>(
      0,
      (a, s) => a + s.points.length,
    );
    expect(total, lessThan(10));
    verifyNever(() => namer.nameFor(any(), any()));
  });

  test('day view does not simplify', () async {
    final start = DateTime(2026, 11, 8, 8);
    when(() => locations.pointsBetween(any(), any())).thenAnswer(
      (_) async => [
        for (var i = 0; i < 100; i++)
          _p(start.add(Duration(minutes: i)), 37.5 + i * 0.0005, 127.0),
      ],
    );

    await cubit.show(day);

    final state = cubit.state as MapViewReady;
    final total = state.data.track.segments.fold<int>(
      0,
      (a, s) => a + s.points.length,
    );
    expect(total, 100);
  });

  test('empty when no points and no entries', () async {
    await cubit.show(day);
    expect(cubit.state, MapViewState.empty(day));
  });

  test('pins come from located entries in the period bounds', () async {
    await cubit.show(day);
    verify(
      () => diary.locatedEntriesBetween(
        DateTime(2026, 11, 8),
        DateTime(2026, 11, 8, 23, 59, 59, 999),
      ),
    ).called(1);
  });

  test('long story (over 2 days) simplifies drawn points', () async {
    final start = DateTime(2026, 11, 1, 8);
    when(
      () => locations.pointsBetween(any(), any()),
    ).thenAnswer((_) async => line(start, 1000));

    await cubit.show(MapPeriod.story(story(start, DateTime(2026, 11, 4, 8))));

    expect(drawn((cubit.state as MapViewReady).data), lessThan(10));
  });

  test('open story counts its span up to now', () async {
    // 시계는 11-08 12시 — 11-01 에 시작한 진행 중 스토리는 이틀이 넘는다.
    final start = DateTime(2026, 11, 1, 8);
    when(
      () => locations.pointsBetween(any(), any()),
    ).thenAnswer((_) async => line(start, 1000));

    await cubit.show(MapPeriod.story(story(start, null)));

    expect(drawn((cubit.state as MapViewReady).data), lessThan(10));
  });

  test('short story (2 days or less) is not simplified', () async {
    final start = DateTime(2026, 11, 6, 8);
    when(
      () => locations.pointsBetween(any(), any()),
    ).thenAnswer((_) async => line(start, 100));

    await cubit.show(MapPeriod.story(story(start, DateTime(2026, 11, 8, 8))));

    expect(drawn((cubit.state as MapViewReady).data), 100);
  });

  /// 같은 곳에 이틀 머문 점(11-03 · 11-04, 각 6점).
  List<LocationPoint> twoStays() => [
    for (var d = 0; d < 2; d++)
      for (var i = 0; i < 6; i++)
        _p(DateTime(2026, 11, 3 + d, 8, 3 * i), 37.5, 127.0),
  ];

  test('month fills frequent and stay names from cache only', () async {
    when(
      () => locations.pointsBetween(any(), any()),
    ).thenAnswer((_) async => twoStays());
    when(
      () => locations.placeName('37.500,127.000'),
    ).thenAnswer((_) async => '집');

    await cubit.show(const MapPeriod.month(2026, 11));

    final data = (cubit.state as MapViewReady).data;
    expect(data.frequent.single.gridKey, '37.500,127.000');
    expect(data.stayNames, {'37.500,127.000': '집'});
    verifyNever(() => namer.nameFor(any(), any()));
    // 같은 격자는 한 번만 묻는다.
    verify(() => locations.placeName('37.500,127.000')).called(1);
  });

  test('story fills stay names from cache only', () async {
    when(
      () => locations.pointsBetween(any(), any()),
    ).thenAnswer((_) async => twoStays());
    when(
      () => locations.placeName('37.500,127.000'),
    ).thenAnswer((_) async => '숙소');

    await cubit.show(
      MapPeriod.story(story(DateTime(2026, 11, 3), DateTime(2026, 11, 5))),
    );

    final data = (cubit.state as MapViewReady).data;
    expect(data.stayNames, {'37.500,127.000': '숙소'});
    verifyNever(() => namer.nameFor(any(), any()));
  });

  test('cache miss leaves the name out', () async {
    when(
      () => locations.pointsBetween(any(), any()),
    ).thenAnswer((_) async => twoStays());

    await cubit.show(const MapPeriod.month(2026, 11));

    expect((cubit.state as MapViewReady).data.stayNames, isEmpty);
  });

  test('first show runs sync before read', () async {
    await cubit.show(day);
    verifyInOrder([
      () => sync.run(),
      () => locations.pointsBetween(any(), any()),
    ]);
  });

  test('show keeps loading while sync runs', () async {
    final gate = Completer<int>();
    when(() => sync.run()).thenAnswer((_) => gate.future);
    final showing = cubit.show(day);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, MapViewState.loading(day));
    verifyNever(() => locations.pointsBetween(any(), any()));
    gate.complete(0);
    await showing;
    expect(cubit.state, MapViewState.empty(day));
  });

  test('show still reads stored data when sync fails', () async {
    when(() => sync.run()).thenThrow(Exception('sync'));
    when(search).thenAnswer(
      (_) async => [
        _entry('a', at, location: const EntryLocation(lat: 37.5, lng: 127.0)),
      ],
    );
    await cubit.show(day);
    expect(cubit.state, isA<MapViewReady>());
  });

  test('refresh runs sync before reload', () async {
    await cubit.show(day);
    await cubit.refresh();
    verifyInOrder([
      () => locations.pointsBetween(any(), any()),
      () => sync.run(),
      () => locations.pointsBetween(any(), any()),
    ]);
  });

  test('month view keeps frequent from unsimplified stays', () async {
    final base = DateTime(2026, 11, 3, 8);
    // 이틀 같은 곳에 머묾 + 사이에 직선 이동(단순화 대상)
    final pts = <LocationPoint>[];
    for (var d = 0; d < 2; d++) {
      for (var i = 0; i < 6; i++) {
        pts.add(_p(base.add(Duration(days: d, minutes: 3 * i)), 37.5, 127.0));
      }
    }
    for (var i = 0; i < 50; i++) {
      pts.add(
        _p(base.add(Duration(days: 3, minutes: i)), 37.6 + i * 0.0005, 127.1),
      );
    }
    when(
      () => locations.pointsBetween(any(), any()),
    ).thenAnswer((_) async => pts);

    await cubit.show(const MapPeriod.month(2026, 11));

    final data = (cubit.state as MapViewReady).data;
    expect(data.frequent, isNotEmpty);
    expect(data.frequent.first.visits, 2);
    expect(data.track.stays, hasLength(2));
    final drawn = data.track.segments.fold<int>(
      0,
      (a, s) => a + s.points.length,
    );
    expect(drawn, lessThan(pts.length));
  });

  test('repository error becomes failure', () async {
    when(
      () => locations.pointsBetween(any(), any()),
    ).thenThrow(Exception('db'));
    await cubit.show(day);
    expect(cubit.state, MapViewState.failure(day));
  });

  test('sync error still loads stored data', () async {
    when(() => sync.run()).thenThrow(Exception('sync'));
    when(search).thenAnswer(
      (_) async => [
        _entry('a', at, location: const EntryLocation(lat: 37.5, lng: 127.0)),
      ],
    );
    await cubit.show(day);
    await cubit.refresh();
    expect(cubit.state, isA<MapViewReady>());
  });

  test('show during slow sync wins over refresh', () async {
    final other = MapPeriod.day(DateTime(2026, 11, 7));
    await cubit.show(day);
    final gate = Completer<int>();
    when(() => sync.run()).thenAnswer((_) => gate.future);
    final refreshing = cubit.refresh();
    final showing = cubit.show(other);
    gate.complete(0);
    await refreshing;
    await showing;
    expect(cubit.state, MapViewState.empty(other));
  });
}
