import '../../repository/photo_storage.dart';
import '../../repository/walk_tracker.dart';

class DiscardWalkScenario {
  const DiscardWalkScenario(this._tracker, this._storage);

  final WalkTracker _tracker;
  final PhotoStorage _storage;

  Future<void> call({required List<String> photoPaths}) async {
    for (final path in photoPaths) {
      await _storage.remove(path);
    }
    await _tracker.clear();
  }
}
