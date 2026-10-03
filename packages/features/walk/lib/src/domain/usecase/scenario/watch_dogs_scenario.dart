import 'package:core/core.dart';

import '../../entity/dog.dart';
import '../../repository/dog_repository.dart';

class WatchDogsScenario {
  const WatchDogsScenario(this._repository);

  final DogRepository _repository;

  Stream<Result<List<Dog>>> call() => _repository.watchAll();
}
