import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../dog/entity/dog.dart';
import '../../dog/entity/dog_draft.dart';
import '../../dog/repository/dog_repository.dart';
import '../../dog/usecase/scenario/delete_dog_scenario.dart';
import '../../dog/usecase/scenario/get_dog_scenario.dart';
import '../../dog/usecase/scenario/get_dogs_scenario.dart';
import '../../dog/usecase/scenario/save_dog_scenario.dart';
import '../../dog/usecase/scenario/watch_dogs_scenario.dart';
import '../../photo/repository/photo_storage.dart';
import '../../photo/usecase/scenario/store_photo_scenario.dart';
import '../../tracking/entity/tracker_state.dart';
import '../../tracking/entity/tracking_notice.dart';
import '../../tracking/entity/walk_session.dart';
import '../../tracking/repository/walk_tracker.dart';
import '../../tracking/usecase/scenario/discard_walk_scenario.dart';
import '../../tracking/usecase/scenario/start_walk_scenario.dart';
import '../../tracking/usecase/scenario/stop_walk_scenario.dart';
import '../entity/walk.dart';
import '../entity/walk_draft.dart';
import '../entity/walk_track_point.dart';
import '../entity/walk_update.dart';
import '../repository/walk_repository.dart';
import 'scenario/delete_walk_scenario.dart';
import 'scenario/get_walk_scenario.dart';
import 'scenario/get_walk_track_scenario.dart';
import 'scenario/save_walk_scenario.dart';
import 'scenario/update_walk_scenario.dart';
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

  /// 추적 중 위치 오류 뒤 다시 받기.
  Future<Result<void>> resumeTracking();

  /// 산책 일시정지. 멈춘 시간은 걸은 시간에서 빠진다.
  Future<Result<void>> pauseWalk();

  Future<Result<void>> unpauseWalk();

  Future<Result<WalkSession>> stopWalk();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();

  Future<void> discardWalk({required List<String> photoPaths});
}

@LazySingleton(as: WalkUseCase)
class DefaultWalkUseCase implements WalkUseCase {
  DefaultWalkUseCase(
    this._walks,
    this._dogs,
    this._tracker,
    this._photos,
    this._idGenerator,
    this._clock,
  );

  final WalkRepository _walks;
  final DogRepository _dogs;
  final WalkTracker _tracker;
  final PhotoStorage _photos;
  final IdGenerator _idGenerator;
  final Clock _clock;

  @override
  Stream<Result<List<Walk>>> watchWalks() => WatchWalksScenario(_walks)();

  @override
  Future<Result<Walk?>> getWalk(String id) => GetWalkScenario(_walks)(id);

  @override
  Future<Result<List<WalkTrackPoint>>> getWalkTrack(String id) =>
      GetWalkTrackScenario(_walks)(id);

  @override
  Future<Result<Walk>> saveWalk(WalkDraft draft) =>
      SaveWalkScenario(_walks, _dogs, _tracker, _idGenerator, _clock)(draft);

  @override
  Future<Result<Walk>> updateWalk(WalkUpdate update) =>
      UpdateWalkScenario(_walks, _dogs, _photos, _idGenerator, _clock)(update);

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
      SaveDogScenario(_dogs, _photos, _idGenerator, _clock)(draft);

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
  Future<Result<void>> resumeTracking() => _tracker.resume();

  @override
  Future<Result<void>> pauseWalk() => _tracker.pause();

  @override
  Future<Result<void>> unpauseWalk() => _tracker.unpause();

  @override
  Future<Result<WalkSession>> stopWalk() => StopWalkScenario(_tracker)();

  @override
  Future<void> openAppSettings() => _tracker.openAppSettings();

  @override
  Future<void> openLocationSettings() => _tracker.openLocationSettings();

  @override
  Future<void> discardWalk({required List<String> photoPaths}) =>
      DiscardWalkScenario(_tracker, _photos)(photoPaths: photoPaths);
}
