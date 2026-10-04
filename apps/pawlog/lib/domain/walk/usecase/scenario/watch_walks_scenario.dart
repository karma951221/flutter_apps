import 'package:core/core.dart';

import '../../entity/walk.dart';
import '../../repository/walk_repository.dart';

class WatchWalksScenario {
  const WatchWalksScenario(this._repository);

  final WalkRepository _repository;

  Stream<Result<List<Walk>>> call() => _repository.watchAll();
}
