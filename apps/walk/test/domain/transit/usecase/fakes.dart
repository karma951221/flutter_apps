import 'dart:async';

import 'package:core/core.dart';
import 'package:walk/domain/transit/entity/station_hit.dart';
import 'package:walk/domain/transit/entity/transit_path.dart';
import 'package:walk/domain/transit/entity/transit_point.dart';
import 'package:walk/domain/transit/repository/station_search.dart';
import 'package:walk/domain/transit/repository/transit_cache.dart';
import 'package:walk/domain/transit/repository/transit_key_store.dart';
import 'package:walk/domain/transit/repository/transit_route_source.dart';

class FixedClock extends Clock {
  FixedClock(this.value);
  DateTime value;
  @override
  DateTime now() => value;
}

class FakeKeyStore implements TransitKeyStore {
  FakeKeyStore({this.key});
  String? key;
  TransitKeyStatus? savedStatus;
  int saveCalls = 0;

  /// 있으면 save 가 이걸 던진다(저장소 실패 흉내).
  Object? saveError;

  @override
  Future<String?> read() async => key;
  @override
  Future<void> save(String k, TransitKeyStatus status) async {
    saveCalls++;
    if (saveError != null) throw saveError!;
    key = k;
    savedStatus = status;
  }

  final changeController = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => changeController.stream;

  @override
  Future<void> delete() async => key = null;
  @override
  Future<TransitKeyStatus?> status() async => savedStatus;
  @override
  Future<void> setStatus(TransitKeyStatus s) async => savedStatus = s;
}

class FakeRouteSource implements TransitRouteSource {
  FakeRouteSource(this.paths);
  List<TransitPath> paths;
  Object? error;
  int calls = 0;
  String? lastKey;

  @override
  Future<List<TransitPath>> find({
    required TransitPoint from,
    required TransitPoint to,
    required String apiKey,
  }) async {
    calls++;
    lastKey = apiKey;
    if (error != null) throw error!;
    return paths;
  }
}

class FakeStationSearch implements StationSearch {
  FakeStationSearch([this.hits = const []]);
  List<StationHit> hits;
  Object? error;
  int calls = 0;
  String? lastKey;

  @override
  Future<List<StationHit>> search(
    String query, {
    required String apiKey,
  }) async {
    calls++;
    lastKey = apiKey;
    if (error != null) throw error!;
    return hits;
  }
}

class FakeCache implements TransitCache {
  FakeCache(this.clock);
  final FixedClock clock;
  final _routes = <String, ({List<TransitPath> paths, DateTime fetchedAt})>{};
  final _stations = <String, List<StationHit>>{};

  @override
  ({List<TransitPath> paths, DateTime fetchedAt})? routes(String key) =>
      _routes[key];
  @override
  void putRoutes(String key, List<TransitPath> paths) =>
      _routes[key] = (paths: paths, fetchedAt: clock.now());
  @override
  Future<List<StationHit>?> stations(String query) async => _stations[query];
  @override
  Future<void> putStations(String query, List<StationHit> hits) async =>
      _stations[query] = hits;
}
