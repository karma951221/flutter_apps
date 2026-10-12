import 'dart:io';

import 'package:core/core.dart';

import '../entity/entry_media.dart';

/// 일기 미디어 파일 보관소. 경로는 모두 보관소 루트 기준 상대 경로다.
///
/// 새로 고른 미디어는 `tmp/` 에 압축 사본으로 만들고, 기록을 저장할 때
/// [promote] 로 `media/` 에 옮긴다.
abstract interface class MediaStore {
  /// 원본을 읽기만 하고 압축 사본을 `tmp/<id>.jpg` 에 만든다. `EntryMedia.path = 'tmp/<id>.jpg'`.
  Future<Result<EntryMedia>> importPhoto(String sourcePath);

  /// 길이 > 30초면 Err(videoTooLong) — 압축 전에 확인. path `'tmp/<id>.mp4'`, thumbPath `'tmp/<id>_thumb.jpg'`.
  /// 여러 영상을 동시에 불러도 압축은 차례로 하나씩 진행된다(`MediaProcessor.compressVideo`).
  Future<Result<EntryMedia>> importVideo(String sourcePath);

  /// tmp/ → media/ 로 옮긴 EntryMedia(경로만 바뀜). 이미 media/ 면 그대로.
  Future<EntryMedia> promote(EntryMedia media);

  /// promote 를 되돌린다(DB 저장 실패 시): media/ → tmp/.
  Future<void> demote(EntryMedia media);

  /// tmp 파일 삭제(path · thumbPath). `media/` 에 있는 파일은 건드리지 않는다.
  Future<void> discard(Iterable<EntryMedia> media);

  /// best-effort, 예외 삼킴.
  Future<void> deleteFiles(Iterable<String> relativePaths);

  File resolve(String relativePath);

  /// [now] 기준 24시간 넘게 바뀌지 않은 파일 중 media/ 아래 [keep] 에 없는 것과
  /// tmp/ 아래 전부를 지운다. 24시간 안의 media/ 파일은 저장이 진행 중일 수 있어 남긴다.
  Future<void> cleanOrphans(Set<String> keep, DateTime now);
}
