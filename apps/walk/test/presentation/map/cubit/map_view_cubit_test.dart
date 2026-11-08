import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
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

  Future<List<DiaryEntry>> search() => diary.searchEntries(
    from: any(named: 'from'),
    to: any(named: 'to'),
    limit: any(named: 'limit'),
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
    cubit = MapViewCubit(locations, diary, sync, namer, const _FixedClock());
  });
  tearDown(() => cubit.close());

  test('show day loads points, stays and entries with coordinates', () async {
    when(() => locations.pointsBetween(any(), any())).thenAnswer(
      (_) async => [
        for (var i = 0; i < 6; i++)
          _p(at.add(Duration(minutes: 3 * i)), 37.5, 127.0),
      ],
    );
    when(search).thenAnswer(
      (_) async => [
        _entry('a', at, location: const EntryLocation(lat: 37.5, lng: 127.0)),
        _entry('b', at, location: const EntryLocation(placeName: '이름만')),
        _entry('c', at),
      ],
    );

    await cubit.show(day);

    final state = cubit.state as MapViewReady;
    expect(state.data.entries.map((e) => e.id), ['a']);
    expect(state.data.track.stays, hasLength(1));
    expect(state.data.stayNames, {'37.500,127.000': '집'});
  });

  test('month view simplifies points and skips stay names', () async {
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

  test('entries limit is 300 per period', () async {
    await cubit.show(day);
    verify(
      () => diary.searchEntries(
        from: any(named: 'from'),
        to: any(named: 'to'),
        limit: 300,
      ),
    ).called(1);
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
