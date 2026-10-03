import 'package:core/core.dart';

import '../../entity/walk_track_point.dart';
import '../../repository/walk_repository.dart';

class GetWalkTrackScenario {
  const GetWalkTrackScenario(this._repository);

  final WalkRepository _repository;

  Future<Result<List<WalkTrackPoint>>> call(String id) =>
      _repository.getTrack(id);
}
