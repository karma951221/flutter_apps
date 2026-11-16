import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../domain/backup/backup_failure.dart';
import '../../../domain/backup/backup_manifest.dart';

const _manifestName = 'manifest.json';

/// 이미 압축된 형식. zip 에서 다시 deflate 하지 않고 저장(store)만 한다.
const _storedExtensions = {'.jpg', '.mp4', '.m4a', '.mp3', '.ogg', '.wav'};

/// 백업 zip 을 만들고 읽는다. 파일은 스트림으로 다뤄 큰 미디어도 메모리에 통째로 올리지 않는다.
class BackupArchive {
  const BackupArchive();

  /// [staging] 아래 모든 파일을 담은 zip 을 [out] 에 쓴다. `manifest.json` 이 맨 앞이고,
  /// 각 파일의 크기 · sha256 은 여기서 채운다([manifestWithoutFiles] 의 `files` 는 무시한다).
  Future<void> pack(
    Directory staging,
    BackupManifest manifestWithoutFiles,
    File out,
  ) async {
    try {
      final paths = <String>[
        for (final f in staging.listSync(recursive: true).whereType<File>())
          p.posix.joinAll(p.split(p.relative(f.path, from: staging.path))),
      ]..sort();
      paths.remove(_manifestName);

      final files = <ManifestFile>[];
      for (final rel in paths) {
        final file = File(p.joinAll([staging.path, ...rel.split('/')]));
        files.add(
          ManifestFile(
            path: rel,
            bytes: await file.length(),
            sha256: (await sha256.bind(file.openRead()).first).toString(),
          ),
        );
      }
      final manifest = BackupManifest(
        format: manifestWithoutFiles.format,
        formatVersion: manifestWithoutFiles.formatVersion,
        appVersion: manifestWithoutFiles.appVersion,
        createdAt: manifestWithoutFiles.createdAt,
        areas: manifestWithoutFiles.areas,
        files: files,
      );

      final encoder = ZipFileEncoder()..create(out.path);
      try {
        encoder.addArchiveFile(
          ArchiveFile.bytes(
            _manifestName,
            utf8.encode(jsonEncode(manifest.toJson())),
          ),
        );
        for (final rel in paths) {
          final entry = ArchiveFile.stream(
            rel,
            InputFileStream(p.joinAll([staging.path, ...rel.split('/')])),
          );
          if (_storedExtensions.contains(p.extension(rel).toLowerCase())) {
            entry.compression = CompressionType.none;
          }
          encoder.addArchiveFile(entry);
        }
      } finally {
        await encoder.close();
      }
    } on FileSystemException catch (e) {
      _deleteQuietly(out);
      throw BackupException(_ioFailure(e));
    } catch (_) {
      _deleteQuietly(out);
      rethrow;
    }
  }

  /// [zip] 을 검사하며 [into] 에 푼다. 실패하면 [into] 를 지우고 [BackupException] 을 던진다.
  Future<BackupManifest> unpack(File zip, Directory into) async {
    final input = InputFileStream(zip.path);
    try {
      final archive = _decode(input);
      final manifest = _readManifest(archive);

      final expected = <String, ManifestFile>{};
      for (final f in manifest.files) {
        if (!_isSafePath(f.path) || expected.containsKey(f.path)) {
          throw const BackupException(BackupFailure.integrity);
        }
        expected[f.path] = f;
      }
      for (final entry in archive) {
        if (entry.name == _manifestName) continue;
        if (!_isSafePath(entry.name)) {
          throw const BackupException(BackupFailure.integrity);
        }
        if (entry.isFile && !expected.containsKey(entry.name)) {
          throw const BackupException(BackupFailure.integrity);
        }
      }

      into.createSync(recursive: true);
      for (final f in manifest.files) {
        final entry = archive.find(f.path);
        if (entry == null || !entry.isFile) {
          throw const BackupException(BackupFailure.integrity);
        }
        final target = File(p.joinAll([into.path, ...f.path.split('/')]));
        if (!p.isWithin(into.path, target.path)) {
          throw const BackupException(BackupFailure.integrity);
        }
        target.parent.createSync(recursive: true);
        final output = OutputFileStream(target.path);
        try {
          entry.writeContent(output);
        } finally {
          await output.close();
        }
        if (await target.length() != f.bytes ||
            (await sha256.bind(target.openRead()).first).toString() !=
                f.sha256) {
          throw const BackupException(BackupFailure.integrity);
        }
      }
      return manifest;
    } on BackupException {
      _deleteDirQuietly(into);
      rethrow;
    } on FileSystemException catch (e) {
      _deleteDirQuietly(into);
      throw BackupException(_ioFailure(e));
    } on ArchiveException {
      // 본문이 깨졌거나 잘린 zip
      _deleteDirQuietly(into);
      throw const BackupException(BackupFailure.integrity);
    } catch (_) {
      _deleteDirQuietly(into);
      rethrow;
    } finally {
      await input.close();
    }
  }
}

Archive _decode(InputFileStream input) {
  try {
    return ZipDecoder().decodeStream(input);
  } on Object {
    // zip 이 아니다(머리글을 못 읽음).
    throw const BackupException(BackupFailure.notBackup);
  }
}

BackupManifest _readManifest(Archive archive) {
  final entry = archive.find(_manifestName);
  if (entry == null || !entry.isFile) {
    throw const BackupException(BackupFailure.notBackup);
  }
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(utf8.decode(entry.readBytes()!)) as Map<String, dynamic>;
  } on Object {
    throw const BackupException(BackupFailure.notBackup);
  }
  if (json['format'] != BackupManifest.formatName) {
    throw const BackupException(BackupFailure.notBackup);
  }
  final version = json['formatVersion'];
  if (version is! int) throw const BackupException(BackupFailure.notBackup);
  if (version > BackupManifest.currentFormatVersion) {
    throw const BackupException(BackupFailure.newerFormat);
  }
  try {
    return BackupManifest.fromJson(json);
  } on Object {
    throw const BackupException(BackupFailure.notBackup);
  }
}

/// 상대 경로이고 `..` · `.` 조각이 없고 역슬래시 · 드라이브 문자가 없어야 한다(zip-slip 방지).
bool _isSafePath(String name) {
  if (name.isEmpty || name.startsWith('/') || name.contains(r'\')) {
    return false;
  }
  if (name.contains(':') || name.contains('\u0000')) return false;
  final segments = name.split('/');
  if (segments.last.isEmpty) segments.removeLast(); // 디렉터리 항목의 끝 슬래시
  return segments.isNotEmpty &&
      segments.every((s) => s.isNotEmpty && s != '.' && s != '..');
}

BackupFailure _ioFailure(FileSystemException e) {
  // ENOSPC(28) · Windows ERROR_DISK_FULL(112)
  final code = e.osError?.errorCode;
  return code == 28 || code == 112 ? BackupFailure.noSpace : BackupFailure.io;
}

void _deleteQuietly(File f) {
  try {
    if (f.existsSync()) f.deleteSync();
  } on FileSystemException {
    // 정리 실패는 원래 오류를 가리지 않는다.
  }
}

void _deleteDirQuietly(Directory d) {
  try {
    if (d.existsSync()) d.deleteSync(recursive: true);
  } on FileSystemException {
    // 정리 실패는 원래 오류를 가리지 않는다.
  }
}
