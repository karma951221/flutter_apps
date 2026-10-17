import 'dart:isolate';
import 'dart:typed_data';

import 'package:core/core.dart';

import '../../../dog/entity/dog.dart';
import '../../../dog/repository/dog_repository.dart';
import '../../../export/repository/walk_file_sharer.dart';
import '../../../photo/repository/photo_storage.dart';
import '../../../walk/entity/walk.dart';
import '../../../walk/entity/walk_track_point.dart';
import '../../../walk/repository/walk_repository.dart';
import '../../entity/backup_data.dart';
import '../../policy/backup_codec.dart';
import '../../repository/backup_archive_codec.dart';

/// 모든 반려견 · 산책 · 사진을 zip 하나로 묶어 공유 시트로 넘긴다.
class ExportBackupScenario {
  const ExportBackupScenario(
    this._dogs,
    this._walks,
    this._photos,
    this._archive,
    this._sharer,
    this._clock,
  );

  final DogRepository _dogs;
  final WalkRepository _walks;
  final PhotoStorage _photos;
  final BackupArchiveCodec _archive;
  final WalkFileSharer _sharer;
  final Clock _clock;

  static const mimeType = 'application/zip';

  Future<Result<void>> call() async {
    final dogsResult = await _dogs.getAll();
    if (dogsResult case Err(:final failure)) return Err(failure);
    final dogs = (dogsResult as Ok<List<Dog>>).value;

    final walksResult = await _walks.watchAll().first;
    if (walksResult case Err(:final failure)) return Err(failure);
    final walks = (walksResult as Ok<List<Walk>>).value;

    final backupWalks = <BackupWalk>[];
    for (final walk in walks) {
      final track = await _walks.getTrack(walk.id);
      if (track case Err(:final failure)) return Err(failure);
      final points = (track as Ok<List<WalkTrackPoint>>).value;
      backupWalks.add(BackupWalk(walk: walk, points: points));
    }

    final now = _clock.now();
    final data = BackupData(exportedAt: now, dogs: dogs, walks: backupWalks);

    final paths = <String>{
      for (final dog in dogs) ?dog.photoPath,
      for (final walk in walks)
        for (final photo in walk.photos) photo.path,
    };
    final photos = <String, Uint8List>{};
    try {
      for (final path in paths) {
        final file = _photos.resolve(path);
        if (!file.existsSync()) continue;
        photos[path] = await file.readAsBytes();
      }
    } on Exception catch (e) {
      return Err(Failure.unknown(message: '사진을 읽지 못했어요: $e'));
    }

    final json = await Isolate.run(() => BackupCodec.encode(data));
    final bytes = await _archive.pack(json: json, photos: photos);
    return _sharer.shareBytes(
      fileName: fileNameFor(now),
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  /// `pawlog-backup-yyyy-MM-dd.zip`(현지 날짜).
  static String fileNameFor(DateTime now) {
    final local = now.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'pawlog-backup-${local.year.toString().padLeft(4, '0')}-'
        '${two(local.month)}-${two(local.day)}.zip';
  }
}
