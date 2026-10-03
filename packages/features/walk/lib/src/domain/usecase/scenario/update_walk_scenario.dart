import 'package:core/core.dart';

import '../../entity/dog.dart';
import '../../entity/walk.dart';
import '../../entity/walk_photo.dart';
import '../../entity/walk_update.dart';
import '../../repository/dog_repository.dart';
import '../../repository/photo_storage.dart';
import '../../repository/walk_repository.dart';

class UpdateWalkScenario {
  const UpdateWalkScenario(
    this._walks,
    this._dogs,
    this._storage,
    this._idGenerator,
    this._now,
  );

  final WalkRepository _walks;
  final DogRepository _dogs;
  final PhotoStorage _storage;
  final IdGenerator _idGenerator;
  final DateTime Function() _now;

  Future<Result<Walk>> call(WalkUpdate update) async {
    if (update.dogIds.isEmpty) {
      return const Err(
        Failure.validation(failureCode: FailureCode.walkDogRequired),
      );
    }
    final found = await _walks.findById(update.id);
    if (found case Err(:final failure)) return Err(failure);
    final current = (found as Ok<Walk?>).value;
    if (current == null) {
      return const Err(Failure.notFound(failureCode: FailureCode.walkNotFound));
    }
    final dogs = await _dogs.getAll();
    if (dogs case Err(:final failure)) return Err(failure);

    // 남는 경로는 기존 id 를 유지하고, 새 경로만 새 id 를 받는다.
    final existingIdByPath = {for (final p in current.photos) p.path: p.id};
    final updated = Walk(
      id: current.id,
      startedAt: current.startedAt,
      endedAt: current.endedAt,
      duration: current.duration,
      distanceMeters: current.distanceMeters,
      memo: update.memo,
      dogs: [
        for (final dog in (dogs as Ok<List<Dog>>).value)
          if (update.dogIds.contains(dog.id)) dog,
      ],
      photos: [
        for (final (index, path) in update.photoPaths.indexed)
          WalkPhoto(
            id: existingIdByPath[path] ?? _idGenerator.newId(),
            path: path,
            position: index,
          ),
      ],
      previewPoints: current.previewPoints,
      createdAt: current.createdAt,
      updatedAt: _now(),
    );

    final saved = await _walks.update(updated);
    if (saved case Err(:final failure)) return Err(failure);

    for (final photo in current.photos) {
      if (!update.photoPaths.contains(photo.path)) {
        await _storage.remove(photo.path);
      }
    }
    return Ok(updated);
  }
}
