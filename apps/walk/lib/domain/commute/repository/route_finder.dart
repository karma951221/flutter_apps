import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';

/// 집 ↔ 회사 지하철 경로를 찾는다. 실패는 `CommuteFailure` 로 던진다.
abstract interface class RouteFinder {
  Future<List<TransitRoute>> find({required Place from, required Place to});
}
