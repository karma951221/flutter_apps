import 'package:injectable/injectable.dart';

import '../entity/station_hit.dart';
import '../repository/station_search.dart';
import '../repository/transit_cache.dart';
import '../repository/transit_key_store.dart';
import '../transit_failure.dart';
import 'transit_api_key.dart';

/// 역 · 정류장 검색. 정규화한 검색어가 2글자 미만이면 호출 없이 빈 목록,
/// 캐시(7일)에 있으면 호출하지 않는다. 호출 결과에 따라 키 상태(connected · rejected)를 기록한다.
@injectable
class SearchStations {
  SearchStations(this._search, this._cache, this._apiKey, this._keyStore);

  final StationSearch _search;
  final TransitCache _cache;
  final TransitApiKey _apiKey;
  final TransitKeyStore _keyStore;

  static const minLength = 2;

  Future<List<StationHit>> call(String query) async {
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.length < minLength) return const [];
    final cached = await _cache.stations(query);
    if (cached != null) return cached;
    final key = await _apiKey.current();
    if (key == null) throw const TransitFailure.missingKey();
    final List<StationHit> hits;
    try {
      hits = await _search.search(query.trim(), apiKey: key);
    } on TransitKeyRejected {
      await _keyStore.setStatus(TransitKeyStatus.rejected);
      rethrow;
    }
    await _keyStore.setStatus(TransitKeyStatus.connected);
    await _cache.putStations(query, hits);
    return hits;
  }
}
