import '../entity/walk_track_point.dart';

/// 위치 샘플을 경로에 넣을지 정한다.
///
/// 이동 거리는 호출부가 계산해 넘긴다. 정책이 geolocator 에 기대지 않게 하려는 것이다.
class WalkTrackingPolicy {
  const WalkTrackingPolicy();

  static const maxAccuracyMeters = 50.0;
  static const minStepMeters = 2.0;

  bool accept({
    required WalkTrackPoint? previous,
    required WalkTrackPoint next,
    required double stepMeters,
  }) {
    final accuracy = next.accuracy;
    if (accuracy != null && accuracy > maxAccuracyMeters) return false;
    if (previous == null) return true;
    return stepMeters >= minStepMeters;
  }
}
