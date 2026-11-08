import 'package:injectable/injectable.dart';

import '../../diary/location/place_lookup.dart';
import '../../diary/location/place_source.dart';
import '../geo/geo_math.dart';
import '../repository/location_repository.dart';

/// 머문 곳의 이름. 격자 캐시를 먼저 보고, 없으면 [PlaceNamer] 에게 묻는다.
/// 이름을 못 받은 경우(오프라인 · 이름 없음)는 null 이고 캐시하지 않는다.
@injectable
class StayNamer {
  StayNamer(this._repository, this._namer);

  final LocationRepository _repository;
  final PlaceNamer _namer;

  Future<String?> nameFor(double lat, double lng) async {
    final key = gridKey(lat, lng);
    final cached = await _repository.placeName(key);
    if (cached != null) return cached;
    final lookup = await _namer.nameFor(lat, lng);
    switch (lookup) {
      case PlaceNamed(:final name):
        await _repository.savePlaceName(key, name);
        return name;
      case PlaceNoName() || PlaceOffline():
        return null;
    }
  }
}
