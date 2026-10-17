import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../backup/entity/backup_import_result.dart';
import '../../backup/repository/backup_archive_codec.dart';
import '../../backup/repository/backup_file_picker.dart';
import '../../backup/usecase/scenario/export_backup_scenario.dart';
import '../../backup/usecase/scenario/import_backup_scenario.dart';
import '../../dog/entity/dog.dart';
import '../../dog/entity/dog_draft.dart';
import '../../dog/repository/dog_repository.dart';
import '../../dog/usecase/scenario/delete_dog_scenario.dart';
import '../../dog/usecase/scenario/get_dog_scenario.dart';
import '../../dog/usecase/scenario/get_dogs_scenario.dart';
import '../../dog/usecase/scenario/save_dog_scenario.dart';
import '../../dog/usecase/scenario/watch_dogs_scenario.dart';
import '../../export/repository/walk_file_sharer.dart';
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
  /// 모든 산책(통계 · 백업용). 피드는 [watchRecentWalks] 로 나눠 읽는다.
  Stream<Result<List<Walk>>> watchWalks();

  /// 피드 한 화면 분량 — 최근 [limit] 개 산책. [favoritesOnly] 면 즐겨찾기만.
  Stream<Result<List<Walk>>> watchRecentWalks({
    required int limit,
    bool favoritesOnly = false,
  });

  /// [from] 이후에 시작한 산책 — 피드의 이번 주 요약을 페이지와 무관하게 센다.
  Stream<Result<List<Walk>>> watchWalksSince(DateTime from);

  Future<Result<Walk?>> getWalk(String id);

  Future<Result<List<WalkTrackPoint>>> getWalkTrack(String id);

  Future<Result<Walk>> saveWalk(WalkDraft draft);

  Future<Result<Walk>> updateWalk(WalkUpdate update);

  Future<Result<void>> deleteWalk(String id);

  /// 즐겨찾기를 켜거나 끈다. 기록 수정이 아니라 updatedAt 은 그대로다.
  Future<Result<void>> setWalkFavorite(String id, bool value);

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

  /// 모든 기록과 사진을 zip 하나로 묶어 공유 시트로 넘긴다.
  Future<Result<void>> exportBackup();

  /// 백업 zip 을 골라 지금 기록에 합친다(있는 id 는 건너뜀).
  Future<BackupImportResult> importBackup();
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
    this._sharer,
    this._archive,
    this._picker,
  );

  final WalkRepository _walks;
  final DogRepository _dogs;
  final WalkTracker _tracker;
  final PhotoStorage _photos;
  final IdGenerator _idGenerator;
  final Clock _clock;
  final WalkFileSharer _sharer;
  final BackupArchiveCodec _archive;
  final BackupFilePicker _picker;

  @override
  Stream<Result<List<Walk>>> watchWalks() => WatchWalksScenario(_walks)();

  @override
  Stream<Result<List<Walk>>> watchRecentWalks({
    required int limit,
    bool favoritesOnly = false,
  }) => _walks.watchRecent(limit: limit, favoritesOnly: favoritesOnly);

  @override
  Stream<Result<List<Walk>>> watchWalksSince(DateTime from) =>
      _walks.watchStartedSince(from);

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
  Future<Result<void>> setWalkFavorite(String id, bool value) =>
      _walks.setFavorite(id, value);

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

  @override
  Future<Result<void>> exportBackup() =>
      ExportBackupScenario(_dogs, _walks, _photos, _archive, _sharer, _clock)();

  @override
  Future<BackupImportResult> importBackup() =>
      ImportBackupScenario(_dogs, _walks, _photos, _archive, _picker)();
}
