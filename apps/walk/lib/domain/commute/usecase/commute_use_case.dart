import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:walk/core/config/commute_api_keys.dart';
import 'package:walk/domain/commute/subway_line_codes.dart';
import 'package:walk/domain/commute/commute_failure.dart';
import 'package:walk/domain/commute/commute_policy.dart';
import 'package:walk/domain/commute/entity/commute_direction.dart';
import 'package:walk/domain/commute/entity/commute_result.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/entity/train_arrival.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';
import 'package:walk/domain/commute/repository/place_repository.dart';
import 'package:walk/domain/commute/repository/route_finder.dart';
import 'package:walk/domain/commute/repository/route_preference_repository.dart';
import 'package:walk/domain/commute/repository/subway_arrival_source.dart';

/// 장소 · 경로 선호 · 경로 찾기 · 실시간 도착을 묶어 한 번의 통근 조회를 만든다.
/// 네트워크는 [query] · [selectRoute] 를 부를 때만 쓴다.
@lazySingleton
class CommuteUseCase {
  CommuteUseCase(
    this._places,
    this._prefs,
    this._routes,
    this._arrivals,
    this._keys,
    this._clock,
  );

  final PlaceRepository _places;
  final RoutePreferenceRepository _prefs;
  final RouteFinder _routes;
  final SubwayArrivalSource _arrivals;
  final CommuteApiKeys _keys;
  final Clock _clock;

  Place? place(PlaceKind kind) => _places.load(kind);

  Future<void> savePlace(Place place) => _places.save(place);

  /// 키 없음 → `missingKey`, 출발 · 도착 장소 없음 → `missingPlaces`, 경로 찾기 실패는
  /// 그대로 던진다. 실시간 실패는 던지지 않고 [RealtimeStatus.failed] 로 둔다.
  Future<CommuteResult> query(CommuteDirection direction) async {
    if (!_keys.isComplete) throw const CommuteFailure.missingKey();
    final from = _places.load(direction.origin);
    final to = _places.load(direction.destination);
    if (from == null || to == null) throw const CommuteFailure.missingPlaces();

    final found = await _routes.find(from: from, to: to);
    if (found.isEmpty) throw const CommuteFailure.noRoute();

    final saved = _prefs.load(direction);
    final chosen = found.firstWhere(
      (r) => r.signature == saved,
      orElse: () => found.first,
    );
    final now = _clock.now();
    final (status, trains) = await _realtime(chosen);
    return _assemble(
      direction: direction,
      route: chosen,
      all: found,
      arrivals: trains,
      realtime: status,
      now: now,
    );
  }

  /// [route] 를 이 방향의 선호로 저장한다. 첫 지하철 승차(역 · 노선 · 방향)가 같으면
  /// 받아 둔 열차로 다시 계산만 하고(호출 없음, 조회 시각 그대로), 다르면 실시간을 한 번 부른다.
  Future<CommuteResult> selectRoute(
    CommuteResult current,
    TransitRoute route,
  ) async {
    await _prefs.save(current.direction, route.signature);
    final all = [current.route, ...current.alternatives];

    if (_sameBoarding(current.route.firstSubway, route.firstSubway)) {
      return _assemble(
        direction: current.direction,
        route: route,
        all: all,
        arrivals: current.arrivals,
        realtime: current.realtime,
        now: current.queriedAt,
      );
    }
    final now = _clock.now();
    final (status, trains) = await _realtime(route);
    return _assemble(
      direction: current.direction,
      route: route,
      all: all,
      arrivals: trains,
      realtime: status,
      now: now,
    );
  }

  /// 둘 다 지하철이 없으면 부를 실시간이 없으므로 같은 승차로 본다.
  static bool _sameBoarding(SubwayLeg? a, SubwayLeg? b) =>
      (a == null && b == null) ||
      a != null &&
      b != null &&
      a.startStation == b.startStation &&
      a.odsayLaneCode == b.odsayLaneCode &&
      a.wayCode == b.wayCode;

  Future<(RealtimeStatus, List<TrainArrival>)> _realtime(
    TransitRoute route,
  ) async {
    final leg = route.firstSubway;
    if (leg == null || seoulSubwayIdFor(leg.odsayLaneCode) == null) {
      return (RealtimeStatus.unavailable, const <TrainArrival>[]);
    }
    final List<TrainArrival> trains;
    try {
      trains = await _arrivals.arrivals(
        station: leg.startStation,
        odsayLaneCode: leg.odsayLaneCode,
        wayCode: leg.wayCode,
      );
    } on Object {
      // 실시간만 실패했다 — 경로 · 시간표 기준 예상은 살린다.
      return (RealtimeStatus.failed, const <TrainArrival>[]);
    }
    if (trains.isEmpty) {
      return (RealtimeStatus.unavailable, const <TrainArrival>[]);
    }
    return (
      RealtimeStatus.ok,
      [for (final t in trains) withEstimatedMinutes(t, leg)],
    );
  }

  static CommuteResult _assemble({
    required CommuteDirection direction,
    required TransitRoute route,
    required List<TransitRoute> all,
    required List<TrainArrival> arrivals,
    required RealtimeStatus realtime,
    required DateTime now,
  }) {
    final verdict = judgeCatch(arrivals, route.walkToStationMinutes);
    final boarding = boardingTrain(arrivals, verdict);
    return CommuteResult(
      direction: direction,
      route: route,
      alternatives: [...all]..remove(route),
      arrivals: arrivals,
      realtime: realtime,
      verdict: verdict,
      eta: estimateEta(now: now, route: route, boarding: boarding),
      etaFromRealtime: boarding != null,
      queriedAt: now,
    );
  }
}
