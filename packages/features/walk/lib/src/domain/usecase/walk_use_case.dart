import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entity/dog.dart';
import '../entity/dog_draft.dart';
import '../entity/tracker_state.dart';
import '../entity/tracking_notice.dart';
import '../entity/walk.dart';
import '../entity/walk_draft.dart';
import '../entity/walk_session.dart';
import '../entity/walk_track_point.dart';
import '../entity/walk_update.dart';
import '../repository/dog_repository.dart';
import '../repository/photo_storage.dart';
import '../repository/walk_repository.dart';
import '../repository/walk_tracker.dart';
import 'scenario/delete_dog_scenario.dart';
import 'scenario/delete_walk_scenario.dart';
import 'scenario/discard_walk_scenario.dart';
import 'scenario/get_dog_scenario.dart';
import 'scenario/get_dogs_scenario.dart';
import 'scenario/get_walk_scenario.dart';
import 'scenario/get_walk_track_scenario.dart';
import 'scenario/save_dog_scenario.dart';
import 'scenario/save_walk_scenario.dart';
import 'scenario/start_walk_scenario.dart';
import 'scenario/stop_walk_scenario.dart';
import 'scenario/store_photo_scenario.dart';
import 'scenario/update_walk_scenario.dart';
import 'scenario/watch_dogs_scenario.dart';
import 'scenario/watch_walks_scenario.dart';

abstract interface class WalkUseCase {
  Stream<Result<List<Walk>>> watchWalks();

  Future<Result<Walk?>> getWalk(String id);

  Future<Result<List<WalkTrackPoint>>> getWalkTrack(String id);

  Future<Result<Walk>> saveWalk(WalkDraft draft);

  Future<Result<Walk>> updateWalk(WalkUpdate update);

  Future<Result<void>> deleteWalk(String id);

  Stream<Result<List<Dog>>> watchDogs();

  Future<Result<List<Dog>>> getDogs();

  Future<Result<Dog?>> getDog(String id);

  Future<Result<Dog>> saveDog(DogDraft draft);

  Future<Result<void>> deleteDog(String id);

  Future<Result<String>> storePhoto({
    required Uint8List bytes,
    required String extension,
  });

  Future<void> removePhoto(String relativePath);

  File photoFile(String relativePath);

  TrackerState get trackerState;

  Stream<TrackerState> get trackerStates;

  Future<Result<void>> startWalk({
    required List<String> dogIds,
    required TrackingNotice notice,
  });

  Future<Result<WalkSession>> stopWalk();

  Future<void> discardWalk({required List<String> photoPaths});
}

@LazySingleton(as: WalkUseCase)
class DefaultWalkUseCase implements WalkUseCase {
  DefaultWalkUseCase(
    WalkRepository walkRepository,
    DogRepository dogRepository,
    WalkTracker tracker,
    PhotoStorage photoStorage,
    IdGenerator idGenerator,
  ) : this.withClock(
        walkRepository,
        dogRepository,
        tracker,
        photoStorage,
        idGenerator,
        DateTime.now,
      );

  /// 테스트에서 시각을 고정하려고 둔 생성자. DI 는 위 생성자를 쓴다.
  DefaultWalkUseCase.withClock(
    this._walks,
    this._dogs,
    this._tracker,
    this._photos,
    this._idGenerator,
    this._now,
  );

  final WalkRepository _walks;
  final DogRepository _dogs;
  final WalkTracker _tracker;
  final PhotoStorage _photos;
  final IdGenerator _idGenerator;
  final DateTime Function() _now;

  @override
  Stream<Result<List<Walk>>> watchWalks() => WatchWalksScenario(_walks)();

  @override
  Future<Result<Walk?>> getWalk(String id) => GetWalkScenario(_walks)(id);

  @override
  Future<Result<List<WalkTrackPoint>>> getWalkTrack(String id) =>
      GetWalkTrackScenario(_walks)(id);

  @override
  Future<Result<Walk>> saveWalk(WalkDraft draft) =>
      SaveWalkScenario(_walks, _dogs, _tracker, _idGenerator, _now)(draft);

  @override
  Future<Result<Walk>> updateWalk(WalkUpdate update) =>
      UpdateWalkScenario(_walks, _dogs, _photos, _idGenerator, _now)(update);

  @override
  Future<Result<void>> deleteWalk(String id) =>
      DeleteWalkScenario(_walks, _photos)(id);

  @override
  Stream<Result<List<Dog>>> watchDogs() => WatchDogsScenario(_dogs)();

  @override
  Future<Result<List<Dog>>> getDogs() => GetDogsScenario(_dogs)();

  @override
  Future<Result<Dog?>> getDog(String id) => GetDogScenario(_dogs)(id);

  @override
  Future<Result<Dog>> saveDog(DogDraft draft) =>
      SaveDogScenario(_dogs, _photos, _idGenerator, _now)(draft);

  @override
  Future<Result<void>> deleteDog(String id) =>
      DeleteDogScenario(_dogs, _photos)(id);

  @override
  Future<Result<String>> storePhoto({
    required Uint8List bytes,
    required String extension,
  }) => StorePhotoScenario(_photos)(bytes: bytes, extension: extension);

  @override
  Future<void> removePhoto(String relativePath) => _photos.remove(relativePath);

  @override
  File photoFile(String relativePath) => _photos.resolve(relativePath);

  @override
  TrackerState get trackerState => _tracker.current;

  @override
  Stream<TrackerState> get trackerStates => _tracker.states;

  @override
  Future<Result<void>> startWalk({
    required List<String> dogIds,
    required TrackingNotice notice,
  }) => StartWalkScenario(_tracker)(dogIds: dogIds, notice: notice);

  @override
  Future<Result<WalkSession>> stopWalk() => StopWalkScenario(_tracker)();

  @override
  Future<void> discardWalk({required List<String> photoPaths}) =>
      DiscardWalkScenario(_tracker, _photos)(photoPaths: photoPaths);
}
