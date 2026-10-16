import '../../walk/entity/walk_track_point.dart';
import '../entity/active_walk_snapshot.dart';
import '../entity/tracking_notice.dart';
import '../entity/walk_session.dart';

/// 진행 중 산책을 앱이 죽어도 남도록 써 두는 저장소. 한 번에 한 세션만 담는다.
abstract interface class ActiveWalkStore {
  /// 남은 세션. 없으면 null.
  Future<ActiveWalkSnapshot?> load();

  /// 이전 것을 지우고 새 세션 머리를 쓴다. 머리만 쓰고 점은 [appendPoint] 로 따로 쓴다.
  Future<void> begin(WalkSession session, TrackingNotice notice);

  /// 점 하나와 그 점까지의 누적 거리.
  Future<void> appendPoint(
    int seq,
    WalkTrackPoint point,
    double distanceMeters,
  );

  /// `pausedDuration` · `pausedAt` · `endedAt` 을 덮어쓴다.
  Future<void> updateTiming(WalkSession session);

  /// 모두 지운다.
  Future<void> clear();
}
