import 'package:core/core.dart';

import '../../entity/walk.dart';
import '../../repository/photo_storage.dart';
import '../../repository/walk_repository.dart';

class DeleteWalkScenario {
  const DeleteWalkScenario(this._walks, this._storage);

  final WalkRepository _walks;
  final PhotoStorage _storage;

  Future<Result<void>> call(String id) async {
    final found = await _walks.findById(id);
    if (found case Err(:final failure)) return Err(failure);
    final walk = (found as Ok<Walk?>).value;
    if (walk == null) {
      return const Err(Failure.notFound(failureCode: FailureCode.walkNotFound));
    }

    final deleted = await _walks.delete(id);
    if (deleted case Err()) return deleted;

    for (final photo in walk.photos) {
      await _storage.remove(photo.path);
    }
    return deleted;
  }
}
