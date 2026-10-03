import 'package:core/core.dart';

import '../../entity/dog.dart';
import '../../repository/dog_repository.dart';

class GetDogScenario {
  const GetDogScenario(this._repository);

  final DogRepository _repository;

  Future<Result<Dog?>> call(String id) => _repository.findById(id);
}
