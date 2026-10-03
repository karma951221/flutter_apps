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

  Future<Result<WalkSession>> stop();

  /// finished → idle.
  Future<void> clear();
}
