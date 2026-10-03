import 'package:core/core.dart';

import '../../entity/dog.dart';
import '../../entity/walk.dart';
import '../../entity/walk_draft.dart';
import '../../entity/walk_photo.dart';
import '../../policy/route_preview.dart';
import '../../repository/dog_repository.dart';
import '../../repository/walk_repository.dart';
import '../../repository/walk_tracker.dart';

class SaveWalkScenario {
  const SaveWalkScenario(
    this._walks,
    this._dogs,
    this._tracker,
    this._idGenerator,
    this._now,
  );

  final WalkRepository _walks;
  final DogRepository _dogs;
  final WalkTracker _tracker;
  final IdGenerator _idGenerator;
  final DateTime Function() _now;

  Future<Result<Walk>> call(WalkDraft draft) async {
    if (draft.dogIds.isEmpty) {
      return const Err(
        Failure.validation(failureCode: FailureCode.walkDogRequired),
      );
    }
    final dogs = await _dogs.getAll();
    if (dogs case Err(:final failure)) return Err(failure);
    final selected = [
      for (final dog in (dogs as Ok<List<Dog>>).value)
        if (draft.dogIds.contains(dog.id)) dog,
    ];

    final now = _now();
    final walk = Walk(
      id: _idGenerator.newId(),
      startedAt: draft.startedAt,
      endedAt: draft.endedAt,
      duration: draft.endedAt.difference(draft.startedAt),
      distanceMeters: draft.distanceMeters,
      memo: draft.memo,
      dogs: selected,
      photos: [
        for (final (index, path) in draft.photoPaths.indexed)
          WalkPhoto(id: _idGenerator.newId(), path: path, position: index),
      ],
      previewPoints: RoutePreview.downsample(draft.points),
      createdAt: now,
      updatedAt: now,
    );

    final saved = await _walks.insert(walk, draft.points);
    return switch (saved) {
      Ok() => await _clearAndReturn(walk),
      Err(:final failure) => Err(failure),
    };
  }

  Future<Result<Walk>> _clearAndReturn(Walk walk) async {
    await _tracker.clear();
    return Ok(walk);
  }
}
