import 'package:core/core.dart';

import '../../entity/dog.dart';
import '../../repository/dog_repository.dart';
import '../../repository/photo_storage.dart';

class DeleteDogScenario {
  const DeleteDogScenario(this._dogs, this._storage);

  final DogRepository _dogs;
  final PhotoStorage _storage;

  Future<Result<void>> call(String id) async {
    final found = await _dogs.findById(id);
    if (found case Err(:final failure)) return Err(failure);
    final dog = (found as Ok<Dog?>).value;
    if (dog == null) {
      return const Err(
        Failure.notFound(failureCode: FailureCode.targetNotFound),
      );
    }

    final deleted = await _dogs.delete(id);
    if (deleted case Err()) return deleted;

    final path = dog.photoPath;
    if (path != null) await _storage.remove(path);
    return deleted;
  }
}
