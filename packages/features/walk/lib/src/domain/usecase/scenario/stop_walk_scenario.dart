import 'package:core/core.dart';

import '../../entity/walk_session.dart';
import '../../repository/walk_tracker.dart';

class StopWalkScenario {
  const StopWalkScenario(this._tracker);

  final WalkTracker _tracker;

  Future<Result<WalkSession>> call() => _tracker.stop();
}
