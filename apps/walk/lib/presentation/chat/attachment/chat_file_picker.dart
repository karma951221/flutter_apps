import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../domain/chat/attachment/attachment_loader.dart';
import '../../lock/media_pick_guard.dart';

/// 물어보기 [📎] 의 시스템 파일 선택기(여러 개). 나가 있는 동안 [MediaPickGuard] 를 켜
/// 돌아왔을 때 일기가 다시 잠기지 않는다.
///
/// 형식은 거르지 않는다 — 받지 않는 형식은 로더가 거절하고 화면이 이유를 알린다.
/// 로컬 경로가 없는 항목(드문 content URI)은 뺀다.
///
/// 안드로이드 선택기는 고른 문서를 앱 캐시 `file_picker/<uuid>/<이름>` 에 복사한다 —
/// 그 사본의 수명([PickedFileCache])도 여기서 맡는다. 선택 자체는 플러그인이라 단위
/// 테스트하지 않고, 지우기는 캐시 폴더를 바꿔 끼워 테스트한다.
@injectable
class ChatFilePicker implements PickedFileCache {
  ChatFilePicker(MediaPickGuard guard)
    : this.withCacheRoot(guard, _pickerCacheRoot);

  @visibleForTesting
  ChatFilePicker.withCacheRoot(this._guard, this._cacheRoot);

  final MediaPickGuard _guard;

  /// 선택기가 사본을 두는 폴더(`<캐시>/file_picker`).
  final Future<Directory> Function() _cacheRoot;

  static Future<Directory> _pickerCacheRoot() async =>
      Directory(p.join((await getTemporaryDirectory()).path, 'file_picker'));

  /// 취소하면 빈 목록.
  Future<List<PickedFile>> pick() async {
    final files = await _guard.run(FilePicker.pickFiles);
    final picked = <PickedFile>[];
    for (final f in files) {
      final path = f.path;
      if (path == null) continue;
      picked.add(
        PickedFile(
          name: f.name,
          path: path,
          sizeBytes: f.lengthSync() ?? await f.length() ?? 0,
        ),
      );
    }
    return picked;
  }

  /// 링크를 푼 실경로가 캐시 폴더 안일 때만 지운다. 그 뒤 비게 된 상위 폴더를 캐시 폴더
  /// 바로 아래까지 지운다.
  @override
  Future<void> release(String path) async {
    try {
      final root = await _cacheRoot();
      if (!await root.exists()) return;
      final rootReal = await root.resolveSymbolicLinks();
      final file = File(path);
      if (!await file.exists()) return;
      final real = await file.resolveSymbolicLinks();
      if (!p.isWithin(rootReal, real)) return;
      await File(real).delete();
      var dir = Directory(p.dirname(real));
      while (p.isWithin(rootReal, dir.path) && await dir.list().isEmpty) {
        await dir.delete();
        dir = dir.parent;
      }
    } on Object {
      // 지우지 못한 사본은 다음 clearAll 이 비운다.
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } on Object {
      // 플러그인이 없거나(테스트) 지우지 못하면 다음에 다시.
    }
  }
}
