import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/repository/place_repository.dart';
import 'package:walk/domain/location/entity/location_point.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/recorder/location_recorder.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';
import 'package:walk/domain/location/repository/location_repository.dart';
import 'package:walk/domain/location/usecase/stay_namer.dart';
import 'package:walk/domain/transit/entity/transit_point.dart';
import 'package:walk/domain/transit/repository/recent_points.dart';
import 'package:walk/domain/transit/usecase/transit_point_suggestions.dart';

import 'fakes.dart';

class _Repo extends Mock implements LocationRepository {}

class _Recorder extends Mock implements LocationRecorder {}

class _Namer extends Mock implements StayNamer {}

class _Places implements PlaceRepository {
  final Map<PlaceKind, Place> saved = {};
  @override
  Place? load(PlaceKind kind) => saved[kind];
  @override
  Future<void> save(Place place) async => saved[place.kind] = place;
}

class _Recent implements RecentPoints {
  List<TransitPoint> items = [];
  @override
  Future<List<TransitPoint>> load() async => items;
  @override
  Future<void> add(TransitPoint p) async => items = [p, ...items];
}

final _now = DateTime(2026, 11, 17, 12);

/// [at] 부터 [minutes] 분 동안 10분 간격 점(같은 자리).
List<LocationPoint> _stay(DateTime at, double lat, {int minutes = 30}) => [
  for (var m = 0; m <= minutes; m += 10)
    LocationPoint(
      recordedAt: at.add(Duration(minutes: m)).toUtc(),
      lat: lat,
      lng: 127.0,
      mode: RecordMode.normal,
    ),
];

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2000)));

  late _Repo repo;
  late _Recorder recorder;
  late _Namer namer;
  late _Places places;
  late _Recent recent;
  late TransitPointSuggestions suggestions;
  var points = <LocationPoint>[];
  DateTime? askedFrom;

  setUp(() {
    repo = _Repo();
    recorder = _Recorder();
    namer = _Namer();
    places = _Places();
    recent = _Recent();
    points = [];
    askedFrom = null;
    when(
      () => recorder.status(),
    ).thenAnswer((_) async => const RecorderStatus.off());
    when(() => repo.hasAnyPoint()).thenAnswer((_) async => points.isNotEmpty);
    when(() => repo.pointsAround(any(), any())).thenAnswer((inv) async {
      askedFrom = inv.positionalArguments[0] as DateTime;
      final from = askedFrom!;
      final to = inv.positionalArguments[1] as DateTime;
      return [
        for (final p in points)
          if (!p.recordedAt.isBefore(from) && !p.recordedAt.isAfter(to)) p,
      ];
    });
    when(() => repo.placeName(any())).thenAnswer((_) async => null);
    when(() => namer.nameFor(any(), any())).thenAnswer((inv) async {
      final lat = inv.positionalArguments[0] as double;
      return '곳 ${lat.toStringAsFixed(2)}';
    });
    suggestions = TransitPointSuggestions(
      places,
      recent,
      repo,
      namer,
      recorder,
      FixedClock(_now),
    );
  });

  test('home/work from commute PlaceRepository', () async {
    places.saved[PlaceKind.home] = const Place(
      kind: PlaceKind.home,
      lat: 37.1,
      lng: 127.1,
      label: '우리집',
    );
    final r = await suggestions.load();
    expect(r.home?.label, '우리집');
    expect(r.home?.source, TransitPointSource.home);
    expect(r.home?.lat, 37.1);
    expect(r.work, isNull);
  });

  test('recent comes from RecentPoints', () async {
    recent.items = const [
      TransitPoint(
        lat: 1,
        lng: 2,
        label: '서울역',
        source: TransitPointSource.recent,
      ),
    ];
    expect((await suggestions.load()).recent.single.label, '서울역');
  });

  test('frequent top 5 from last 30 days with names', () async {
    // 방문 횟수가 서로 다른 일곱 곳(위도 37.01..37.07 — 격자 구분되게).
    for (var i = 1; i <= 7; i++) {
      for (var v = 0; v < i; v++) {
        points.addAll(
          _stay(
            _now.subtract(Duration(days: 1 + v, hours: i)),
            37.0 + i * 0.01,
          ),
        );
      }
    }
    // 30일보다 오래된 곳은 세지 않는다.
    for (var v = 0; v < 20; v++) {
      points.addAll(_stay(_now.subtract(Duration(days: 40 + v)), 36.0));
    }
    final r = await suggestions.load();
    expect(r.frequent.length, 5);
    expect(r.frequent.first.label, '곳 37.07');
    expect(r.frequent.every((p) => p.source == TransitPointSource.frequent),
        isTrue);
    expect(r.frequent.any((p) => p.label == '곳 36.00'), isFalse);
    expect(askedFrom, _now.subtract(const Duration(days: 30)).toUtc());
  });

  test('recorder off or no points → empty frequent (no throw)', () async {
    expect((await suggestions.load()).frequent, isEmpty);
    points = _stay(_now.subtract(const Duration(days: 2)), 37.5);
    when(() => recorder.status()).thenThrow(Exception('boom'));
    expect((await suggestions.load()).frequent, hasLength(1));
  });

  test('location repo throws → empty frequent', () async {
    points = _stay(_now.subtract(const Duration(days: 2)), 37.5);
    when(() => repo.pointsAround(any(), any())).thenThrow(Exception('db'));
    places.saved[PlaceKind.work] = const Place(
      kind: PlaceKind.work,
      lat: 1,
      lng: 2,
      label: '회사',
    );
    final r = await suggestions.load();
    expect(r.frequent, isEmpty);
    expect(r.work?.label, '회사');
  });

  test('unnamed places are skipped', () async {
    points = _stay(_now.subtract(const Duration(days: 2)), 37.5);
    when(() => namer.nameFor(any(), any())).thenAnswer((_) async => null);
    expect((await suggestions.load()).frequent, isEmpty);
  });

  test('saveAs home persists via PlaceRepository', () async {
    await suggestions.saveAs(
      PlaceKind.home,
      const TransitPoint(
        lat: 37.5,
        lng: 127.0,
        label: '새집',
        source: TransitPointSource.address,
      ),
    );
    final p = places.saved[PlaceKind.home]!;
    expect((p.lat, p.lng, p.label), (37.5, 127.0, '새집'));
  });
}
