import 'package:core/core.dart';

import '../../entity/dog.dart';
import '../../entity/dog_draft.dart';
import '../../repository/dog_repository.dart';
import '../../repository/photo_storage.dart';

class SaveDogScenario {
  const SaveDogScenario(
    this._dogs,
    this._storage,
    this._idGenerator,
    this._now,
  );

  final DogRepository _dogs;
  final PhotoStorage _storage;
  final IdGenerator _idGenerator;
  final DateTime Function() _now;

  Future<Result<Dog>> call(DogDraft draft) async {
    final name = draft.name.trim();
    if (name.isEmpty) {
      return const Err(
        Failure.validation(failureCode: FailureCode.dogNameRequired),
      );
    }

    final now = _now();
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
