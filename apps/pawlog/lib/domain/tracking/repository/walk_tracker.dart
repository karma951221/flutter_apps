import 'package:core/core.dart';

import '../entity/tracker_state.dart';
import '../entity/tracking_notice.dart';
import '../entity/walk_session.dart';

abstract interface class WalkTracker {
  TrackerState get current;

  /// 브로드캐스트 스트림.
  Stream<TrackerState> get states;

  Future<Result<void>> start({
    required List<String> dogIds,
    required TrackingNotice notice,
  });

  /// 위치 오류 뒤 세션을 지킨 채 위치 확인과 스트림 구독을 다시 한다.
  Future<Result<void>> resume();

  Future<Result<WalkSession>> stop();

  /// finished → idle.
  Future<void> clear();
}
