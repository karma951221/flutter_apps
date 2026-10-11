import 'dart:io';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/diary/diary_failure.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/media_limits.dart';
import '../../../domain/diary/media/media_processor.dart';
import '../../../domain/diary/media/media_store.dart';

const _tmp = 'tmp';
const _media = 'media';

/// tmp/ 에 남은 사본을 버려진 것으로 보는 시간.
const _tmpExpiry = Duration(hours: 24);

/// [root] 아래 `tmp/`(저장 전 사본) · `media/`(저장된 기록) 두 폴더로 나눠 둔다.
/// 바깥에는 루트 기준 상대 경로만 내보낸다.
@LazySingleton(as: MediaStore)
class FileMediaStore implements MediaStore {
  FileMediaStore(@Named('diaryRoot') this._root, this._ids, this._processor);

  final Directory _root;
  final IdGenerator _ids;
  final MediaProcessor _processor;

  @override
  File resolve(String relativePath) => File('${_root.path}/$relativePath');

  @override
  Future<Result<EntryMedia>> importPhoto(String sourcePath) async {
    final id = _ids.newId();
    final path = '$_tmp/$id.jpg';
    final target = await _prepare(path);
    try {
      final size = await _processor.compressPhoto(File(sourcePath), target);
      return Ok(
        EntryMedia(
          id: id,
          kind: MediaKind.photo,
          path: path,
          width: size.width,
          height: size.height,
          bytes: await target.length(),
        ),
      );
    } catch (_) {
      await deleteFiles([path]);
      return Err(DiaryFailure.mediaProcessing.toFailure());
    }
  }

  @override
  Future<Result<EntryMedia>> importVideo(String sourcePath) async {
    final source = File(sourcePath);
    final int lengthMs;
    try {
      lengthMs = await _processor.videoDurationMs(source);
    } catch (_) {
      return Err(DiaryFailure.mediaProcessing.toFailure());
    }
    if (!MediaLimits.videoAllowed(Duration(milliseconds: lengthMs))) {
      return Err(DiaryFailure.videoTooLong.toFailure());
    }

    final id = _ids.newId();
    final path = '$_tmp/$id.mp4';
    final thumbPath = '$_tmp/${id}_thumb.jpg';
    final target = await _prepare(path);
    try {
      final result = await _processor.compressVideo(
        source,
        target,
        resolve(thumbPath),
      );
      return Ok(
        EntryMedia(
          id: id,
          kind: MediaKind.video,
          path: path,
          thumbPath: thumbPath,
          width: result.width,
          height: result.height,
          durationMs: result.durationMs,
          bytes: await target.length(),
        ),
      );
    } catch (_) {
      await deleteFiles([path, thumbPath]);
      return Err(DiaryFailure.mediaProcessing.toFailure());
    }
  }

  @override
  Future<EntryMedia> promote(EntryMedia media) =>
      _moveBetween(media, from: _tmp, to: _media);

  @override
  Future<void> demote(EntryMedia media) =>
      _moveBetween(media, from: _media, to: _tmp);

  @override
  Future<void> discard(Iterable<EntryMedia> media) => deleteFiles([
    for (final m in media)
      for (final path in [m.path, ?m.thumbPath])
        if (_isUnder(path, _tmp)) path,
  ]);

  @override
  Future<void> deleteFiles(Iterable<String> relativePaths) async {
    for (final path in relativePaths) {
      try {
        final file = resolve(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // best-effort.
      }
    }
  }

  @override
  Future<void> cleanOrphans(Set<String> keep, DateTime now) async {
    for (final file in await _filesIn(_media)) {
      final path = '$_media/${file.uri.pathSegments.last}';
      if (!keep.contains(path)) await deleteFiles([path]);
    }
    for (final file in await _filesIn(_tmp)) {
      final modified = await file.lastModified();
      if (now.difference(modified) > _tmpExpiry) {
        await deleteFiles(['$_tmp/${file.uri.pathSegments.last}']);
      }
    }
  }

  /// [media] 의 본 파일 · 썸네일을 [from] 폴더에서 [to] 폴더로 옮긴다.
  /// 이미 [from] 밖이면 그대로 둔다. 썸네일 이동이 실패하면 본 파일을 되돌린다.
  Future<EntryMedia> _moveBetween(
    EntryMedia media, {
    required String from,
    required String to,
  }) async {
    if (!_isUnder(media.path, from)) return media;
    final path = _rebase(media.path, from, to);
    final thumbPath = switch (media.thumbPath) {
      final thumb? when _isUnder(thumb, from) => _rebase(thumb, from, to),
      final thumb => thumb,
    };

    await _move(media.path, path);
    if (thumbPath != media.thumbPath) {
      try {
        await _move(media.thumbPath!, thumbPath!);
      } catch (_) {
        await _move(path, media.path);
        rethrow;
      }
    }
    return media.copyWith(path: path, thumbPath: thumbPath);
  }

  Future<void> _move(String fromPath, String toPath) async {
    final target = await _prepare(toPath);
    await resolve(fromPath).rename(target.path);
  }

  /// [relativePath] 가 들어갈 폴더를 만들고 그 파일을 돌려준다.
  Future<File> _prepare(String relativePath) async {
    final file = resolve(relativePath);
    await file.parent.create(recursive: true);
    return file;
  }

  Future<List<File>> _filesIn(String dir) async {
    final directory = Directory('${_root.path}/$dir');
    if (!await directory.exists()) return const [];
    return directory.list().where((e) => e is File).cast<File>().toList();
  }

  static bool _isUnder(String path, String dir) => path.startsWith('$dir/');

  static String _rebase(String path, String from, String to) =>
      '$to/${path.substring(from.length + 1)}';
}
