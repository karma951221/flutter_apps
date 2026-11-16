import '../entity/location_point.dart';
import '../recorder/recorder_status.dart';

/// 켤 때 받은 첫 위치가 캐시라 [RecorderRunning.recordingSince] 보다 조금 앞설 수 있는 여유
/// (네이티브 `isFreshFallback` 과 같은 5분).
const _cachedFixTolerance = Duration(minutes: 5);

/// 마지막 머문 곳을 지금까지 이을 때만 지금(UTC) — 꺼져 있던 시간을 머문 곳으로 지어내지 않게.
/// 기록 중이고, 지금 서비스가 마지막 점 이전부터(캐시 첫 위치 5분 여유) 끊김 없이 살아 있고,
/// 마지막 점이 정지 감지 점이거나 정지 감지가 꺼져 있을 때(꺼져 있으면 가만히 있는 동안 점이 안 남는다).
/// [points] 는 시각 오름차순.
DateTime? stayOpenEnd(
  List<LocationPoint> points,
  RecorderStatus status,
  DateTime now,
) {
  if (points.isEmpty) return null;
  if (status case RecorderRunning(
    :final stillDetection,
    recordingSince: final since?,
  )) {
    final last = points.last;
    if (last.recordedAt.isBefore(since.subtract(_cachedFixTolerance))) {
      return null;
    }
    if (!last.stillStart && stillDetection) return null;
    return now.toUtc();
  }
  return null;
}
