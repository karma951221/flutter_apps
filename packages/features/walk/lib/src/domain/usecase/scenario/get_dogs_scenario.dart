import 'package:core/core.dart';

import '../../entity/dog.dart';
import '../../repository/dog_repository.dart';

class GetDogsScenario {
  const GetDogsScenario(this._repository);

  final DogRepository _repository;

  Future<Result<List<Dog>>> call() => _repository.getAll();
}
