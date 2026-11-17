import 'package:injectable/injectable.dart';

import '../entity/station_hit.dart';
import '../repository/station_search.dart';
import '../repository/transit_cache.dart';
import '../transit_failure.dart';
import 'transit_api_key.dart';

/// 역 · 정류장 검색. 정규화한 검색어가 2글자 미만이면 호출 없이 빈 목록,
/// 캐시(7일)에 있으면 호출하지 않는다.
@injectable
class SearchStations {
  SearchStations(this._search, this._cache, this._apiKey);

  final StationSearch _search;
  final TransitCache _cache;
  final TransitApiKey _apiKey;

  static const minLength = 2;

  Future<List<StationHit>> call(String query) async {
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.length < minLength) return const [];
    final cached = await _cache.stations(query);
    if (cached != null) return cached;
    final key = await _apiKey.current();
    if (key == null) throw const TransitFailure.missingKey();
    final hits = await _search.search(query.trim(), apiKey: key);
    await _cache.putStations(query, hits);
    return hits;
  }
}
