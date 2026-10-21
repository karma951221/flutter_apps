import 'package:walk/domain/commute/entity/place.dart';

/// 집 · 회사 위치를 기기에 둔다.
abstract interface class PlaceRepository {
  /// 저장한 적이 없거나 값이 깨졌으면 null.
  Place? load(PlaceKind kind);

  Future<void> save(Place place);
}
