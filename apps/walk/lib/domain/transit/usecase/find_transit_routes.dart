import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entity/transit_path.dart';
import '../entity/transit_point.dart';
import '../repository/transit_cache.dart';
import '../repository/transit_key_store.dart';
import '../repository/transit_route_source.dart';
import '../transit_failure.dart';
import '../transit_sort.dart';
import 'transit_api_key.dart';

/// 경로 찾기 결과. [fromCache] 면 [fetchedAt] 은 그때 받아 둔 시각.
class TransitRoutesResult {
  const TransitRoutesResult({
    required this.paths,
    required this.fetchedAt,
    required this.fromCache,
  });

  final List<TransitPath> paths;
  final DateTime fetchedAt;
  final bool fromCache;
}

/// 출발 · 도착 사이 경로를 찾는다. 같은 쌍은 캐시(10분)를 먼저 쓰고,
/// 호출 결과에 따라 키 상태(connected · rejected)를 기록한다.
@injectable
class FindTransitRoutes {
  FindTransitRoutes(
    this._source,
    this._cache,
    this._apiKey,
    this._keyStore,
    this._clock,
  );

  final TransitRouteSource _source;
  final TransitCache _cache;
  final TransitApiKey _apiKey;
  final TransitKeyStore _keyStore;
  final Clock _clock;

  Future<TransitRoutesResult> call(
    TransitPoint from,
    TransitPoint to, {
    bool refresh = false,
  }) async {
    final cacheKey = '${from.cacheKey}|${to.cacheKey}';
    if (!refresh) {
      final hit = _cache.routes(cacheKey);
      if (hit != null) {
        return TransitRoutesResult(
          paths: hit.paths,
          fetchedAt: hit.fetchedAt,
          fromCache: true,
        );
      }
    }
    final key = await _apiKey.current();
    if (key == null) throw const TransitFailure.missingKey();
    final List<TransitPath> found;
    try {
      found = await _source.find(from: from, to: to, apiKey: key);
    } on TransitKeyRejected {
      await _keyStore.setStatus(TransitKeyStatus.rejected);
      rethrow;
    }
    await _keyStore.setStatus(TransitKeyStatus.connected);
    final paths = sortTransitPaths(found);
    _cache.putRoutes(cacheKey, paths);
    return TransitRoutesResult(
      paths: paths,
      fetchedAt: _clock.now(),
      fromCache: false,
    );
  }
}
