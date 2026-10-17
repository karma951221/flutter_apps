import 'dart:typed_data';

import 'package:core/core.dart';

import '../../../dog/entity/dog.dart';
import '../../../dog/repository/dog_repository.dart';
import '../../../photo/repository/photo_storage.dart';
import '../../../walk/entity/walk.dart';
import '../../../walk/repository/walk_repository.dart';
import '../../entity/backup_data.dart';
import '../../entity/backup_import_result.dart';
import '../../policy/backup_codec.dart';
import '../../repository/backup_archive_codec.dart';
import '../../repository/backup_file_picker.dart';

/// 고른 백업 zip 을 지금 기록에 합친다. 이미 있는 id 는 건너뛴다.
///
/// 풀기 · 디코딩 · 존재 확인을 모두 끝낸 뒤에만 쓴다(반쯤 쓰지 않기).
/// 쓰는 순서는 새로 가져올 항목의 사진 → 반려견 → 산책. 사진을 먼저 쓰는 까닭은
/// 사진 쓰기가 실패해도 다시 가져오면 처음부터 이어지게 하려는 것이다(행이 먼저
/// 들어가면 다시 가져올 때 nothingNew 라 사진에 닿지 못한다). `write` 는 있는 파일을
/// 건너뛰므로 여러 번 써도 된다.
class ImportBackupScenario {
  const ImportBackupScenario(
    this._dogs,
    this._walks,
    this._photos,
    this._archive,
    this._picker,
  );

  final DogRepository _dogs;
  final WalkRepository _walks;
  final PhotoStorage _photos;
  final BackupArchiveCodec _archive;
  final BackupFilePicker _picker;

  Future<BackupImportResult> call() async {
    final picked = await _picker.pick();
    final Uint8List bytes;
    switch (picked) {
      case Err(:final failure):
        return BackupImportResult.failed(failure);
      case Ok(value: null):
        return const BackupImportResult.cancelled();
      case Ok(:final value?):
        bytes = value;
    }

    final unpacked = _archive.unpack(bytes);
    if (unpacked case Err()) return const BackupImportResult.invalid();
    final archive =
        (unpacked as Ok<({String json, Map<String, Uint8List> photos})>).value;

    final decoded = BackupCodec.decode(archive.json);
    if (decoded case Err()) return const BackupImportResult.invalid();
    final data = (decoded as Ok<BackupData>).value;

    final newDogs = <Dog>[];
    for (final dog in data.dogs) {
      final found = await _dogs.findById(dog.id);
      switch (found) {
        case Err(:final failure):
          return BackupImportResult.failed(failure);
        case Ok(value: null):
          newDogs.add(dog);
        case Ok():
          break;
      }
    }

    final newWalks = <BackupWalk>[];
    for (final backupWalk in data.walks) {
      final found = await _walks.findById(backupWalk.walk.id);
      switch (found) {
        case Err(:final failure):
          return BackupImportResult.failed(failure);
        case Ok(value: null):
          newWalks.add(backupWalk);
        case Ok():
          break;
      }
    }

    if (newDogs.isEmpty && newWalks.isEmpty) {
      return const BackupImportResult.nothingNew();
    }

    for (final path in _photoPaths(newDogs, [
      for (final w in newWalks) w.walk,
    ])) {
      final photo = archive.photos[path];
      // zip 에 없는 사진은 건너뛴다. 항목은 경로를 그대로 갖고 들어간다.
      if (photo == null) continue;
      if (await _photos.write(path, photo) case Err(:final failure)) {
        return BackupImportResult.failed(failure);
      }
    }

    for (final dog in newDogs) {
      if (await _dogs.upsert(dog) case Err(:final failure)) {
        return BackupImportResult.failed(failure);
      }
    }
    for (final BackupWalk(:walk, :points) in newWalks) {
      if (await _walks.insert(walk, points) case Err(:final failure)) {
        return BackupImportResult.failed(failure);
      }
    }

    return BackupImportResult.imported(newDogs.length, newWalks.length);
  }

  static Set<String> _photoPaths(List<Dog> dogs, List<Walk> walks) => {
    for (final dog in dogs) ?dog.photoPath,
    for (final walk in walks)
      for (final photo in walk.photos) photo.path,
  };
}
