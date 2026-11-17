import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/core/config/commute_api_keys.dart';
import 'package:walk/domain/commute/commute_failure.dart';
import 'package:walk/domain/commute/entity/catch_verdict.dart';
import 'package:walk/domain/commute/entity/commute_direction.dart';
import 'package:walk/domain/commute/entity/commute_result.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/entity/train_arrival.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';
import 'package:walk/domain/commute/repository/place_repository.dart';
import 'package:walk/domain/commute/repository/route_finder.dart';
import 'package:walk/domain/commute/repository/route_preference_repository.dart';
import 'package:walk/domain/commute/repository/subway_arrival_source.dart';
import 'package:walk/domain/commute/usecase/commute_use_case.dart';

class _FixedClock extends Clock {
  _FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class _FakePlaces implements PlaceRepository {
  final Map<PlaceKind, Place> saved = {};

  @override
  Place? load(PlaceKind kind) => saved[kind];

  @override
  Future<void> save(Place place) async => saved[place.kind] = place;
}

class _FakePrefs implements RoutePreferenceRepository {
  final Map<CommuteDirection, String> saved = {};

  @override
  String? load(CommuteDirection d) => saved[d];

  @override
  Future<void> save(CommuteDirection d, String signature) async =>
      saved[d] = signature;
}

class _FakeRoutes implements RouteFinder {
  List<TransitRoute> routes = const [];
  int calls = 0;

  @override
  Future<List<TransitRoute>> find({
    required Place from,
    required Place to,
  }) async {
    calls++;
    return routes;
  }
}

class _FakeArrivals implements SubwayArrivalSource {
  List<TrainArrival> trains = const [];
  Object? error;
  final List<(String, int, int)> calls = [];

  @override
  Future<List<TrainArrival>> arrivals({
    required String station,
    required int odsayLaneCode,
    required int wayCode,
  }) async {
    calls.add((station, odsayLaneCode, wayCode));
    if (error case final e?) throw e;
    return trains;
  }
}

const _home = Place(kind: PlaceKind.home, lat: 37.5, lng: 127.0, label: '집');
const _work = Place(kind: PlaceKind.work, lat: 37.4, lng: 127.1, label: '회사');

const _keys = CommuteApiKeys(odsay: 'o', seoulSubway: 's');

TransitRoute _route({
  int walkBefore = 6,
  int subwayMinutes = 16,
  int stationCount = 8,
  int walkAfter = 12,
  String start = '신논현',
  String end = '판교',
  int lane = 109,
  int wayCode = 2,
}) => TransitRoute(
  totalMinutes: walkBefore + subwayMinutes + walkAfter,
  transferCount: 0,
  legs: [
    RouteLeg.walk(minutes: walkBefore),
    RouteLeg.subway(
      minutes: subwayMinutes,
      lineName: '노선$lane',
      odsayLaneCode: lane,
      startStation: start,
      endStation: end,
      wayCode: wayCode,
      wayName: '방면',
      stationCount: stationCount,
    ),
    RouteLeg.walk(minutes: walkAfter),
  ],
);

void main() {
  final t0 = DateTime(2026, 10, 21, 8);
  late _FixedClock clock;
  late _FakePlaces places;
  late _FakePrefs prefs;
  late _FakeRoutes routes;
  late _FakeArrivals arrivals;

  CommuteUseCase useCase({CommuteApiKeys keys = _keys}) =>
      CommuteUseCase(places, prefs, routes, arrivals, keys, clock);

  setUp(() {
    clock = _FixedClock(t0);
    places = _FakePlaces()
      ..saved[PlaceKind.home] = _home
      ..saved[PlaceKind.work] = _work;
    prefs = _FakePrefs();
    routes = _FakeRoutes();
    arrivals = _FakeArrivals();
  });

  test('place · savePlace 는 저장소를 거친다', () async {
    places.saved.clear();
    final uc = useCase();

    expect(uc.place(PlaceKind.home), isNull);
    await uc.savePlace(_home);
    expect(uc.place(PlaceKind.home), _home);
  });

  test('missing key throws before any call', () async {
    routes.routes = [_route()];
    places.saved.clear();
    final uc = useCase(
      keys: const CommuteApiKeys(odsay: 'o', seoulSubway: ' '),
    );

    await expectLater(
      uc.query(CommuteDirection.toWork),
      throwsA(const CommuteFailure.missingKey()),
    );
    expect(routes.calls, 0);
    expect(arrivals.calls, isEmpty);
  });

  test('missing work place throws missingPlaces', () async {
    places.saved.remove(PlaceKind.work);
    routes.routes = [_route()];

    await expectLater(
      useCase().query(CommuteDirection.toWork),
      throwsA(const CommuteFailure.missingPlaces()),
    );
    expect(routes.calls, 0);
  });

  test('경로 찾기 실패는 그대로 던진다', () async {
    final failing = _ThrowingRoutes(const CommuteFailure.noRoute());
    final uc = CommuteUseCase(places, prefs, failing, arrivals, _keys, clock);

    await expectLater(
      uc.query(CommuteDirection.toWork),
      throwsA(const CommuteFailure.noRoute()),
    );
  });

  test('첫 경로가 기본, 나머지는 대안', () async {
    final a = _route(start: '강남');
    final b = _route(start: '역삼');
    routes.routes = [a, b];
    arrivals.trains = const [TrainArrival(minutes: 9, message: '')];

    final result = await useCase().query(CommuteDirection.toWork);

    expect(result.direction, CommuteDirection.toWork);
    expect(result.route, a);
    expect(result.alternatives, [b]);
    expect(result.queriedAt, t0);
    expect(result.realtime, RealtimeStatus.ok);
    expect(arrivals.calls, [('강남', 109, 2)]);
  });

  test('prefers saved signature over first route', () async {
    final a = _route(start: '강남');
    final b = _route(start: '역삼');
    final c = _route(start: '선릉');
    routes.routes = [a, b, c];
    prefs.saved[CommuteDirection.toHome] = b.signature;

    final result = await useCase().query(CommuteDirection.toHome);

    expect(result.route, b);
    expect(result.alternatives, [a, c]);
  });

  test('realtime unavailable keeps route and eta', () async {
    // 6 + 16 + 19 = 41분, 노선 매핑 없음.
    final route = _route(walkAfter: 19, lane: 999);
    routes.routes = [route];

    final result = await useCase().query(CommuteDirection.toWork);

    expect(result.route, route);
    expect(result.realtime, RealtimeStatus.unavailable);
    expect(result.arrivals, isEmpty);
    expect(result.verdict, const CatchVerdict.unknown());
    expect(result.eta, DateTime(2026, 10, 21, 8, 41));
    expect(result.etaFromRealtime, isFalse);
    expect(arrivals.calls, isEmpty);
  });

  test('열차 0건이면 unavailable', () async {
    routes.routes = [_route()];
    arrivals.trains = const [];

    final result = await useCase().query(CommuteDirection.toWork);

    expect(result.realtime, RealtimeStatus.unavailable);
    expect(arrivals.calls, hasLength(1));
  });

  test('지하철이 없는 경로면 unavailable, 호출 없음', () async {
    routes.routes = [
      const TransitRoute(
        totalMinutes: 20,
        transferCount: 0,
        legs: [RouteLeg.walk(minutes: 20)],
      ),
    ];

    final result = await useCase().query(CommuteDirection.toWork);

    expect(result.realtime, RealtimeStatus.unavailable);
    expect(result.eta, DateTime(2026, 10, 21, 8, 20));
    expect(arrivals.calls, isEmpty);
  });

  test('realtime failure keeps route', () async {
    final route = _route();
    routes.routes = [route];
    arrivals.error = const CommuteFailure.network();

    final result = await useCase().query(CommuteDirection.toWork);

    expect(result.route, route);
    expect(result.realtime, RealtimeStatus.failed);
    expect(result.arrivals, isEmpty);
    expect(result.verdict, const CatchVerdict.unknown());
    expect(result.eta, t0.add(const Duration(minutes: 34)));
    expect(result.etaFromRealtime, isFalse);
  });

  test('estimates minutes from stations', () async {
    routes.routes = [_route()];
    arrivals.trains = const [
      TrainArrival(stationsAway: 3, message: '3전역'),
      TrainArrival(stationsAway: 7, message: '7전역'),
    ];

    final result = await useCase().query(CommuteDirection.toWork);

    expect(result.realtime, RealtimeStatus.ok);
    expect(result.arrivals.map((a) => a.minutes), [6, 14]);
    expect(result.arrivals.every((a) => a.estimated), isTrue);
    expect(result.verdict, const CatchVerdict.catchSecond());
    expect(result.eta, DateTime(2026, 10, 21, 8, 42));
    expect(result.etaFromRealtime, isTrue);
  });

  group('selectRoute', () {
    test('selectRoute same first station does not call arrivals', () async {
      final a = _route(walkAfter: 12);
      final b = _route(walkAfter: 2, end: '양재');
      routes.routes = [a, b];
      arrivals.trains = const [
        TrainArrival(minutes: 3, message: ''),
        TrainArrival(minutes: 10, message: ''),
      ];
      final uc = useCase();
      final first = await uc.query(CommuteDirection.toWork);
      clock.value = t0.add(const Duration(minutes: 1));

      final next = await uc.selectRoute(first, b);

      expect(arrivals.calls, hasLength(1));
      expect(next.route, b);
      expect(next.alternatives, [a]);
      expect(next.arrivals, first.arrivals);
      expect(next.realtime, RealtimeStatus.ok);
      expect(next.queriedAt, t0);
      expect(next.verdict, const CatchVerdict.catchSecond());
      // 조회 시각 기준: 08:00 + 10 + (16 + 2).
      expect(next.eta, DateTime(2026, 10, 21, 8, 28));
      expect(prefs.saved[CommuteDirection.toWork], b.signature);
    });

    test('selectRoute different station calls once and saves signature',
        () async {
      final a = _route(start: '강남', walkBefore: 6);
      final b = _route(start: '역삼', walkBefore: 2);
      routes.routes = [a, b];
      arrivals.trains = const [TrainArrival(minutes: 4, message: '')];
      final uc = useCase();
      final first = await uc.query(CommuteDirection.toWork);
      expect(first.verdict, const CatchVerdict.missBoth());
      final later = t0.add(const Duration(minutes: 1));
      clock.value = later;

      final next = await uc.selectRoute(first, b);

      expect(arrivals.calls, [('강남', 109, 2), ('역삼', 109, 2)]);
      expect(next.route, b);
      expect(next.alternatives, [a]);
      expect(next.queriedAt, later);
      expect(next.verdict, const CatchVerdict.catchFirst());
      expect(next.eta, later.add(const Duration(minutes: 4 + 16 + 12)));
      expect(prefs.saved[CommuteDirection.toWork], b.signature);
    });

    test('둘 다 지하철이 없으면 조회 시각을 바꾸지 않는다', () async {
      const a = TransitRoute(
        totalMinutes: 20,
        transferCount: 0,
        legs: [RouteLeg.walk(minutes: 20)],
      );
      const b = TransitRoute(
        totalMinutes: 25,
        transferCount: 0,
        legs: [RouteLeg.walk(minutes: 25)],
      );
      routes.routes = [a, b];
      final uc = useCase();
      final first = await uc.query(CommuteDirection.toWork);
      clock.value = t0.add(const Duration(minutes: 1));

      final next = await uc.selectRoute(first, b);

      expect(arrivals.calls, isEmpty);
      expect(next.route, b);
      expect(next.queriedAt, t0);
      expect(next.eta, DateTime(2026, 10, 21, 8, 25));
      expect(next.realtime, RealtimeStatus.unavailable);
    });

    test('다른 방향(wayCode)이면 다시 부른다', () async {
      final a = _route(wayCode: 1);
      final b = _route(wayCode: 2, end: '양재');
      routes.routes = [a, b];
      final uc = useCase();
      final first = await uc.query(CommuteDirection.toWork);

      await uc.selectRoute(first, b);

      expect(arrivals.calls, hasLength(2));
    });
  });
}

class _ThrowingRoutes implements RouteFinder {
  _ThrowingRoutes(this.failure);

  final CommuteFailure failure;

  @override
  Future<List<TransitRoute>> find({
    required Place from,
    required Place to,
  }) async => throw failure;
}
