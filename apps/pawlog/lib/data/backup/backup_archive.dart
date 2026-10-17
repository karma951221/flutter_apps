import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../domain/backup/repository/backup_archive_codec.dart';
import '../../domain/photo/repository/photo_storage.dart';

/// 항목은 `backup.json` 과 `photos/<상대 경로>`. 그 밖의 항목은 무시한다.
@LazySingleton(as: BackupArchiveCodec)
class BackupArchive implements BackupArchiveCodec {
  const BackupArchive();

  static const _jsonName = 'backup.json';
  static const _photoPrefix = 'photos/';

  @override
  Future<Uint8List> pack({
    required String json,
    required Map<String, Uint8List> photos,
  }) => Isolate.run(() => _pack(json, photos));

  static Uint8List _pack(String json, Map<String, Uint8List> photos) {
    final archive = Archive()
      ..addFile(ArchiveFile.bytes(_jsonName, utf8.encode(json)));
    for (final MapEntry(key: path, value: bytes) in photos.entries) {
      archive.addFile(ArchiveFile.bytes('$_photoPrefix$path', bytes));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  @override
  Future<Result<({String json, Map<String, Uint8List> photos})>> unpack(
    Uint8List bytes,
  ) async {
    try {
      return await Isolate.run(() => _unpack(bytes));
    } on Object catch (e) {
      // isolate 를 띄우거나 결과를 넘기지 못한 경우도 던지지 않고 Err.
      return _invalid(e.toString());
    }
  }

  static Result<({String json, Map<String, Uint8List> photos})> _unpack(
    Uint8List bytes,
  ) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      String? json;
      final photos = <String, Uint8List>{};
      for (final file in archive.files) {
        if (!file.isFile) continue;
        if (file.name == _jsonName) {
          json = utf8.decode(file.content);
        } else if (file.name.startsWith(_photoPrefix)) {
          final path = file.name.substring(_photoPrefix.length);
          if (!isSafePhotoPath(path)) {
            return _invalid('unsafe path ${file.name}');
          }
          photos[path] = file.content;
        }
      }
      if (json == null) return _invalid('missing $_jsonName');
      return Ok((json: json, photos: photos));
    } on Object catch (e) {
      // 깨지거나 잘린 zip 은 ArchiveException(FormatException) 말고도
      // RangeError 등을 던질 수 있다. utf8 디코딩 실패도 여기로 온다.
      return _invalid(e.toString());
    }
  }

  static Err<({String json, Map<String, Uint8List> photos})> _invalid(
    String reason,
  ) => Err(
    Failure.validation(
      failureCode: FailureCode.invalidData,
      message: 'backup archive: $reason',
    ),
  );
}
