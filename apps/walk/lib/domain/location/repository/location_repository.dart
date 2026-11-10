import '../entity/location_point.dart';

/// 이 폰에만 쌓이는 위치 점 저장소.
abstract interface class LocationRepository {
  /// 같은 (시각, 위도, 경도) 점은 무시한다. 새로 들어간 개수를 돌려준다.
  Future<int> insertAll(List<LocationPoint> points);

  /// [from] ~ [to] 양끝 포함, 시각 오름차순.
  Future<List<LocationPoint>> pointsBetween(DateTime from, DateTime to);

  /// [pointsBetween] 에 [from] 직전 점 하나와 [to] 직후 점 하나(있으면)를 더한다. 시각 오름차순.
  /// 기간 경계를 넘거나 아직 이어지는 머문 곳을 그 기간에서도 보기 위해서다.
  Future<List<LocationPoint>> pointsAround(DateTime from, DateTime to);

  Future<bool> hasAnyPoint();

  /// [cutoff] 보다 이전 점을 지운다. 지운 개수.
  Future<int> purgeBefore(DateTime cutoff);

  /// 점과 장소 이름 캐시를 모두 지운다.
  Future<void> deleteAll();

  Future<String?> placeName(String gridKey);
  Future<void> savePlaceName(String gridKey, String name);
}
