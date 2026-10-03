import 'package:core/core.dart';

import '../../entity/walk.dart';
import '../../repository/walk_repository.dart';

class GetWalkScenario {
  const GetWalkScenario(this._repository);

  final WalkRepository _repository;

  Future<Result<Walk?>> call(String id) => _repository.findById(id);
}
