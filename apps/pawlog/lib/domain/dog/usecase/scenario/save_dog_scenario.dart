import 'package:core/core.dart';

import '../../../photo/repository/photo_storage.dart';
import '../../entity/dog.dart';
import '../../entity/dog_draft.dart';
import '../../repository/dog_repository.dart';

class SaveDogScenario {
  const SaveDogScenario(
    this._dogs,
    this._storage,
    this._idGenerator,
    this._clock,
  );

  final DogRepository _dogs;
  final PhotoStorage _storage;
  final IdGenerator _idGenerator;
  final Clock _clock;

  Future<Result<Dog>> call(DogDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return const Err(
        Failure.validation(failureCode: FailureCode.dogNameRequired),
      );
    }

    final now = _clock.now();
    final id = draft.id;
    Dog? previous;
    if (id != null) {
      final found = await _dogs.findById(id);
      if (found case Err(:final failure)) return Err(failure);
      previous = (found as Ok<Dog?>).value;
      if (previous == null) {
        return const Err(
          Failure.notFound(failureCode: FailureCode.targetNotFound),
        );
      }
    }

    final dog = Dog(
      id: id ?? _idGenerator.newId(),
      name: name,
      breed: draft.breed,
      birthday: draft.birthday,
      photoPath: draft.photoPath,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );
    final saved = await _dogs.upsert(dog);
    if (saved case Err(:final failure)) return Err(failure);

    final oldPath = previous?.photoPath;
    if (oldPath != null && oldPath != dog.photoPath) {
      await _storage.remove(oldPath);
    }
    return Ok(dog);
  }
}
