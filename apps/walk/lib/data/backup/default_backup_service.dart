import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import '../../domain/backup/backup_area_id.dart';
import '../../domain/backup/backup_area_source.dart';
import '../../domain/backup/backup_failure.dart';
import '../../domain/backup/backup_manifest.dart';
import '../../domain/backup/backup_service.dart';
import '../../domain/backup/restore_notice.dart';
import 'archive/backup_archive.dart';
import 'crypto/backup_cipher.dart';

/// [BackupService] 구현. 영역([BackupAreaSource])을 [BackupAreaId] 순서로 돌린다 —
/// 대화가 위키보다 먼저여야 위키 출처가 남는다.
///
/// 문서 폴더(`app_flutter`) 아래 폴더:
/// - `restore_staging/` — 검사한 백업을 푼 작업 폴더. 영역의 `replace` 가 미디어를 옮겨 가므로
///   복원 한 번에만 쓴다.
/// - `restore_undo/` — 복원 전 데이터(되돌리기 지점, `undo.json` 이 다 쓴 표시).
///   `in_progress.json` 이 있으면 복원 · 되돌리기 도중이다 — 시작 때 되돌리기 지점으로 마저 되돌린다.
///   되돌리기 지점은 한 번 쓰면(되돌리기 · 실패 롤백 · 시작 복구) 없어진다.
/// - `restore_undo.tmp/` — 만드는 중인 되돌리기 지점, `restore_undo.trash/` — 버린 지점.
///   폴더 지우기는 원자적이지 않으므로 이름 바꾸기를 커밋 지점으로 쓴다.
///
/// 압축 · 해시 · 암호화는 [Isolate.run] 으로, DB 를 만지는 영역 일은 이 isolate 에서 한다.
class DefaultBackupService implements BackupService {
  DefaultBackupService({
    required List<BackupAreaSource> areas,
    required Directory appDocs,
    required Directory cache,
    required String appVersion,
    required Clock clock,
    BackupCipher? cipher,
    BackupArchive archive = const BackupArchive(),
    Future<int?> Function()? freeBytes,
    @visibleForTesting Future<void> Function(Directory dir)? deleteTree,
  }) : _areas = {for (final a in areas) a.id: a},
       _appVersion = appVersion,
       _clock = clock,
       _cipher = cipher ?? BackupCipher(),
       _archive = archive,
       _freeBytes = freeBytes,
       _deleteTree = deleteTree ?? _deleteRecursive,
       _staging = Directory('${appDocs.path}/restore_staging'),
       _undo = Directory('${appDocs.path}/restore_undo'),
       _exportDir = Directory('${cache.path}/backup_export');

  final Map<BackupAreaId, BackupAreaSource> _areas;
  final String _appVersion;
  final Clock _clock;
  final BackupCipher _cipher;
  final BackupArchive _archive;

  /// 저장 공간의 여유 바이트. null 이거나 null 을 돌려주면 검사를 건너뛴다.
  final Future<int?> Function()? _freeBytes;

  /// 폴더를 통째로 지운다. 테스트가 도중 종료(반쯤 지운 폴더)를 흉내 내려고 바꾼다.
  final Future<void> Function(Directory dir) _deleteTree;

  final Directory _staging;
  final Directory _undo;
  final Directory _exportDir;

  /// 버린 되돌리기 지점(지우는 중). 시작 때 남아 있으면 지운다.
  Directory get _undoTrash => Directory('${_undo.path}.trash');

  /// 만드는 중인 되돌리기 지점. 다 쓰면 `restore_undo` 로 이름을 바꾼다.
  Directory get _undoBuilding => Directory('${_undo.path}.tmp');

  File get _inProgress => File('${_undo.path}/in_progress.json');
  File get _undoIndex => File('${_undo.path}/undo.json');

  /// [ids] 중 이 앱에 있는 영역을 [BackupAreaId] 순서로.
  List<BackupAreaSource> _ordered(Iterable<BackupAreaId> ids) => [
    for (final id in BackupAreaId.values)
      if (ids.contains(id) && _areas[id] != null) _areas[id]!,
  ];

  @override
  Future<Map<BackupAreaId, AreaPreview>> preview() async => {
    for (final area in _ordered(_areas.keys))
      area.id: AreaPreview(
        counts: await area.counts(),
        bytes: await area.estimatedBytes(),
      ),
  };

  @override
  Future<Result<File>> export(
    Set<BackupAreaId> areas, {
    String? password,
  }) async {
    final ordered = _ordered(areas);
    final result = await _guard(() async {
      var estimated = 0;
      for (final area in ordered) {
        estimated += await area.estimatedBytes();
      }
      await _ensureSpace(estimated);

      await _deleteDir(_exportDir);
      final staging = Directory('${_exportDir.path}/staging');
      await staging.create(recursive: true);

      final manifestAreas = <BackupAreaId, AreaManifest>{};
      for (final area in ordered) {
        final counts = await area.export(staging);
        manifestAreas[area.id] = AreaManifest(
          schema: area.schema,
          counts: counts,
        );
      }
      final now = _clock.now();
      final manifest = BackupManifest(
        format: BackupManifest.formatName,
        formatVersion: BackupManifest.currentFormatVersion,
        appVersion: _appVersion,
        createdAt: now,
        areas: manifestAreas,
        files: const [],
      );

      final name = '${_exportDir.path}/${_fileStem(now)}';
      final zip = File('$name.zip');
      await _pack(_archive, staging, manifest, zip);
      await _deleteDir(staging);

      var out = zip;
      if (password != null) {
        out = File('$name.lifelog');
        await _encrypt(_cipher, zip, out, password);
        await zip.delete();
      }
      return out;
    });
    if (result is Err) await _deleteDirQuietly(_exportDir);
    return result;
  }

  @override
  Future<Result<InspectedBackup>> inspect(File file, {String? password}) async {
    final result = await _guard(() async {
      await _ensureSpace(await file.length() * 2);
      await _deleteDir(_staging);
      await _staging.create(recursive: true);
      final root = Directory('${_staging.path}/root');

      final BackupManifest manifest;
      switch (await sniffBackupFile(file)) {
        case BackupFileKind.zip:
          manifest = await _unpack(_archive, file, root);
        case BackupFileKind.encrypted:
          if (password == null) {
            throw const BackupException(BackupFailure.wrongPasswordOrCorrupt);
          }
          final zip = File('${_staging.path}/backup.zip');
          await _decrypt(_cipher, file, zip, password);
          manifest = await _unpack(_archive, zip, root);
          await zip.delete();
        case BackupFileKind.unknown:
          throw const BackupException(BackupFailure.notBackup);
      }

      final availability = <BackupAreaId, AreaAvailability>{};
      for (final MapEntry(key: id, value: entry) in manifest.areas.entries) {
        final area = _areas[id];
        // 이 앱에 없는 영역은 복원 목록에 내지 않는다.
        if (area == null) continue;
        final newer = entry.schema.entries.any(
          (s) => s.value > (area.schema[s.key] ?? -1),
        );
        availability[id] = newer
            ? AreaAvailability.newerSchema
            : AreaAvailability.ok;
      }
      for (final area in _ordered(availability.keys)) {
        if (availability[area.id] == AreaAvailability.ok) {
          await area.validate(root);
        }
      }
      return InspectedBackup(
        manifest: manifest,
        staging: root,
        areas: availability,
      );
    });
    if (result is Err) await _deleteDirQuietly(_staging);
    return result;
  }

  @override
  Future<Result<Set<RestoreNotice>>> restore(
    InspectedBackup b,
    Set<BackupAreaId> areas,
  ) async {
    // 고른 영역이 없으면 아무것도 바꾸지 않는다 — 되돌리기 지점 · 작업 폴더도 그대로.
    if (areas.isEmpty) return const Ok({});
    try {
      return await _guard(() async {
        for (final id in areas) {
          switch (b.areas[id]) {
            case AreaAvailability.ok:
              break;
            case AreaAvailability.newerSchema:
              throw const BackupException(BackupFailure.newerAreaSchema);
            case null:
              throw const BackupException(BackupFailure.integrity);
          }
        }
        // 지난번 도중 종료가 남았으면 그 되돌리기 지점을 덮어쓰기 전에 마저 되돌린다.
        await _finishInterrupted();

        final ordered = _ordered(areas);
        await _makeUndoPoint(ordered);
        await _writeIds(_inProgress, ordered);

        try {
          for (final area in ordered) {
            await area.validate(b.staging);
            await area.replace(b.staging);
          }
        } catch (e, s) {
          // 실패한 영역도 폴더 · DB 를 바꾼 뒤(prefs 쓰기 등)에 실패했을 수 있으므로 고른 영역
          // 모두를 되돌린다. 손대지 않은 영역은 같은 내용으로 다시 쓰일 뿐이다.
          await _rollBack(ordered);
          Error.throwWithStackTrace(e, s);
        }

        await _inProgress.delete();
        return _afterRestore(ordered);
      });
    } finally {
      await _deleteDirQuietly(_staging);
    }
  }

  /// 복원 실패 뒤 되돌리기 지점으로 되돌리고 지점을 지운다. 되돌리기마저 실패하면 표시 파일을
  /// 남겨 다음 시작 때 다시 하게 하고, 결과는 원래 실패로 둔다.
  Future<void> _rollBack(List<BackupAreaSource> ordered) async {
    try {
      await _replayUndo(ordered);
      await _discardUndo();
    } on Object catch (e, s) {
      debugPrint('backup rollback failed, will retry at startup: $e\n$s');
    }
  }

  @override
  Future<bool> needsRecovery() => _inProgress.exists();

  @override
  Future<bool> hasUndoPoint() async =>
      await _undoIndex.exists() && !await _inProgress.exists();

  @override
  Future<Result<Set<RestoreNotice>>> undo() async {
    if (!await hasUndoPoint()) return const Err(Failure.notFound());
    return _guard(() async {
      final ordered = _ordered(await _readIds(_undoIndex));
      // 되돌리기 도중 죽어도 시작 때 마저 되돌린다.
      await _writeIds(_inProgress, ordered);
      await _replayUndo(ordered);
      await _discardUndo();
      return _afterRestore(ordered);
    });
  }

  @override
  Future<void> recoverIfInterrupted() async {
    try {
      await _finishInterrupted();
    } on Object catch (e, s) {
      // 표시 파일이 남아 다음 시작 때 다시 한다. 앱 시작은 막지 않는다.
      debugPrint('backup recovery failed, will retry next start: $e\n$s');
    }
    await _deleteDirQuietly(_staging);
    // 지우다 죽어 남은 버린 지점 · 다 만들지 못한 지점.
    await _deleteDirQuietly(_undoTrash);
    await _deleteDirQuietly(_undoBuilding);
  }

  @override
  Future<void> discard(InspectedBackup b) => _deleteDirQuietly(_staging);

  /// `in_progress.json` 이 있으면 그 영역들을 되돌리기 지점으로 되돌리고 지점을 지운다.
  Future<void> _finishInterrupted() async {
    if (!await _inProgress.exists()) return;
    final ids = await _readIdsOrAll(_inProgress);
    await _replayUndo(_ordered(ids), skipUnreadable: true);
    await _discardUndo();
  }

  /// 되돌리기 지점을 통째로 버린다. `restore_undo` → `restore_undo.trash` 이름 바꾸기가 커밋
  /// 지점이다 — 지우다 죽어도 표시 파일(`in_progress.json` · `undo.json`)과 반쯤 지운 영역
  /// 폴더가 함께 남지 않고, 남은 `.trash` 는 다음 시작 때 지운다.
  Future<void> _discardUndo() async {
    if (!await _undo.exists()) return;
    if (await _undoTrash.exists()) await _deleteTree(_undoTrash);
    await _undo.rename(_undoTrash.path);
    await _deleteTrash(_undoTrash);
  }

  /// 이미 버린(이름을 바꾼) 폴더를 지운다. 실패해도 데이터는 끝난 상태이므로 남기고 넘어간다.
  Future<void> _deleteTrash(Directory trash) async {
    try {
      if (await trash.exists()) await _deleteTree(trash);
    } on Object catch (e, s) {
      debugPrint('backup trash cleanup failed: ${trash.path}: $e\n$s');
    }
  }

  /// 고른 영역의 지금 데이터로 새 되돌리기 지점을 만든다. `restore_undo.tmp` 에 다 쓴 뒤에야
  /// 이전 지점을 버리고 이름을 바꿔 넣는다 — `undo.json` 은 반쯤 쓴 영역 폴더와 함께 있지 않다.
  Future<void> _makeUndoPoint(List<BackupAreaSource> ordered) async {
    if (await _undoBuilding.exists()) await _deleteTree(_undoBuilding);
    await _undoBuilding.create(recursive: true);
    try {
      for (final area in ordered) {
        await area.export(_undoBuilding);
      }
      await _writeIds(File('${_undoBuilding.path}/undo.json'), ordered);
      await _discardUndo();
      await _undoBuilding.rename(_undo.path);
    } catch (_) {
      await _deleteDirQuietly(_undoBuilding);
      rethrow;
    }
  }

  /// [ordered] 를 `restore_undo/` 의 것으로 바꾼다. `replace` 가 영역 폴더의 미디어를 옮겨 가므로
  /// 바꾼 영역 폴더는 곧바로 버린다 — 다시 돌리면 빈 미디어로 덮어쓰게 된다. 버릴 때는 먼저
  /// `.trash-<id>` 로 이름을 바꾼다: 지우다 죽어도 반쯤 지운 폴더가 영역 폴더로 남아 다시
  /// 돌려지지 않는다(설정 `prefs.json` 이 빠진 폴더를 돌리면 설정을 모두 지운다). 폴더가 없는
  /// 영역(이미 되돌림)은 건너뛴다.
  ///
  /// [skipUnreadable] 이면(시작 복구) 읽을 수 없는 영역 폴더를 남기고 버린 뒤 나머지를 계속한다 —
  /// 그러지 않으면 시작할 때마다 실패해 다음 복원도 막힌다.
  Future<void> _replayUndo(
    List<BackupAreaSource> ordered, {
    bool skipUnreadable = false,
  }) async {
    for (final area in ordered) {
      final dir = Directory('${_undo.path}/${area.id.name}');
      if (!await dir.exists()) continue;
      try {
        await area.validate(_undo);
      } on BackupException catch (e, s) {
        if (!skipUnreadable) rethrow;
        debugPrint('undo area ${area.id.name} is unreadable, skipped: $e\n$s');
        await _trashArea(dir, area.id);
        continue;
      }
      await area.replace(_undo);
      await _trashArea(dir, area.id);
    }
  }

  Future<void> _trashArea(Directory dir, BackupAreaId id) async {
    final trash = Directory('${_undo.path}/.trash-${id.name}');
    if (await trash.exists()) await _deleteTree(trash);
    await dir.rename(trash.path);
    await _deleteTrash(trash);
  }

  /// 영역마다 복원 후 처리를 하고 안내를 모은다. 데이터는 이미 바뀌었으므로 한 영역의
  /// 실패가 결과를 실패로 만들지 않는다.
  Future<Set<RestoreNotice>> _afterRestore(
    List<BackupAreaSource> ordered,
  ) async {
    final notices = <RestoreNotice>{};
    for (final area in ordered) {
      try {
        notices.addAll(await area.afterRestore());
      } on Object catch (e, s) {
        // 데이터는 이미 바뀌었다. 영역이 알릴 실패(알람 다시 예약)는 안내로 돌려준다.
        debugPrint('afterRestore of ${area.id.name} failed: $e\n$s');
      }
    }
    return notices;
  }

  Future<void> _ensureSpace(int needed) async {
    final free = await _freeBytes?.call();
    if (free != null && free < needed) {
      throw const BackupException(BackupFailure.noSpace);
    }
  }
}

/// `lifelog-backup-YYYYMMDD-HHmm`.
String _fileStem(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'lifelog-backup-${t.year}${two(t.month)}${two(t.day)}-'
      '${two(t.hour)}${two(t.minute)}';
}

/// 예외를 [BackupFailure] 의 [Err] 로 바꾼다.
Future<Result<T>> _guard<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on BackupException catch (e) {
    return Err(e.failure.toFailure());
  } on BackupCipherException catch (e) {
    return Err(switch (e.error) {
      BackupCipherError.wrongPasswordOrCorrupt =>
        BackupFailure.wrongPasswordOrCorrupt.toFailure(),
      BackupCipherError.notEncrypted => BackupFailure.notBackup.toFailure(),
    });
  } on FileSystemException catch (e) {
    // ENOSPC(28) · Windows ERROR_DISK_FULL(112)
    final code = e.osError?.errorCode;
    return Err(
      (code == 28 || code == 112 ? BackupFailure.noSpace : BackupFailure.io)
          .toFailure(),
    );
  } on Object {
    return Err(BackupFailure.io.toFailure());
  }
}

Future<void> _writeIds(File file, List<BackupAreaSource> areas) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode({
      'areas': [for (final a in areas) a.id.name],
    }),
    flush: true,
  );
}

Future<Set<BackupAreaId>> _readIds(File file) async {
  final json = jsonDecode(await file.readAsString()) as Map<String, Object?>;
  final names = (json['areas']! as List<Object?>).cast<String>();
  final byName = BackupAreaId.values.asNameMap();
  return {for (final n in names) ?byName[n]};
}

/// 표시 파일이 깨졌으면 모든 영역으로 본다 — 되돌리기 폴더가 있는 영역만 되돌리므로 안전하다.
Future<Set<BackupAreaId>> _readIdsOrAll(File file) async {
  try {
    return await _readIds(file);
  } on Object {
    return BackupAreaId.values.toSet();
  }
}

Future<void> _deleteRecursive(Directory dir) => dir.delete(recursive: true);

Future<void> _deleteDir(Directory dir) async {
  if (await dir.exists()) await dir.delete(recursive: true);
}

Future<void> _deleteDirQuietly(Directory dir) async {
  try {
    await _deleteDir(dir);
  } on FileSystemException {
    // 정리 실패는 원래 결과를 가리지 않는다.
  }
}

// 아래는 순수 파일 · 암호 작업이라 다른 isolate 에서 돈다. 클로저가 이 함수의 인자만 잡도록
// 최상위 함수로 둔다(서비스 · DB 를 잡으면 보낼 수 없다).

Future<void> _pack(
  BackupArchive archive,
  Directory staging,
  BackupManifest manifest,
  File out,
) => Isolate.run(() => archive.pack(staging, manifest, out));

Future<BackupManifest> _unpack(
  BackupArchive archive,
  File zip,
  Directory into,
) => Isolate.run(() => archive.unpack(zip, into));

Future<void> _encrypt(BackupCipher cipher, File plain, File out, String pw) =>
    Isolate.run(() => cipher.encrypt(plain, out, pw));

Future<void> _decrypt(BackupCipher cipher, File sealed, File out, String pw) =>
    Isolate.run(() => cipher.decrypt(sealed, out, pw));
