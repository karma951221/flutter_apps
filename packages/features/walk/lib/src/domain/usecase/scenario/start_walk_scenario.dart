import 'package:core/core.dart';

import '../../entity/tracker_state.dart';
import '../../entity/tracking_notice.dart';
import '../../repository/walk_tracker.dart';

class StartWalkScenario {
  const StartWalkScenario(this._tracker);

  final WalkTracker _tracker;

  Future<Result<void>> call({
    required List<String> dogIds,
    required TrackingNotice notice,
  }) {
    if (dogIds.isEmpty) {
      return Future.value(
        const Err(Failure.validation(failureCode: FailureCode.walkDogRequired)),
      );
    }
    if (_tracker.current is TrackerTracking) {
      return Future.value(
        const Err(
          Failure.validation(
            failureCode: FailureCode.walkTrackingAlreadyActive,
          ),
        ),
      );
    }
    return _tracker.start(dogIds: dogIds, notice: notice);
  }
}
