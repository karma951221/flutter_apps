import 'dart:convert';
import 'dart:typed_data';

import 'package:walk/domain/chat/workspace/workspace.dart';
import 'package:walk/presentation/chat/workspace/workspace_share.dart';

/// 메모리 위의 작업 폴더. 목록 · 읽기 · 지우기 · 절대 경로만 쓴다.
/// 절대 경로는 `/ws/<상대 경로>`.
class MemoryWorkspace implements Workspace {
  MemoryWorkspace([Iterable<(WorkspaceFile, Uint8List)> files = const []]) {
    for (final (f, bytes) in files) {
      _files[f.path] = (f, bytes);
    }
  }

  final _files = <String, (WorkspaceFile, Uint8List)>{};
  final deleted = <String>[];

  /// 설정하면 list 가 던진다.
  bool failList = false;

  /// 설정하면 delete 가 던진다.
  bool failDelete = false;

  void add(WorkspaceFile f, Uint8List bytes) => _files[f.path] = (f, bytes);

  @override
  Future<List<WorkspaceFile>> list(WorkspaceArea area) async {
    if (failList) throw StateError('io');
    return [
      for (final (f, _) in _files.values)
        if (f.area == area) f,
    ]..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  }

  @override
  Future<Uint8List?> readBytes(String path) async => _files[path]?.$2;

  @override
  Future<bool> exists(String path) async => _files.containsKey(path);

  @override
  Future<bool> delete(String path) async {
    if (failDelete) throw StateError('io');
    deleted.add(path);
    return _files.remove(path) != null;
  }

  /// 설정하면 absolutePath 가 던진다.
  bool failAbsolute = false;

  @override
  Future<String> absolutePath(String path) async {
    if (failAbsolute) throw WorkspacePathException(path);
    return '/ws/$path';
  }

  /// out 에 UTF-8 로 넣는다(이름 겹침은 다루지 않는다).
  @override
  Future<String> writeOut(String fileName, String content) async {
    final path = 'out/$fileName';
    final bytes = Uint8List.fromList(utf8.encode(content));
    add(workspaceFile(path, sizeBytes: bytes.length), bytes);
    return path;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 공유 시트 대신 (절대 경로, 이름)을 적는다.
class FakeWorkspaceShare implements WorkspaceShare {
  final shared = <(String, String)>[];

  @override
  Future<void> share(String absolutePath, String name) async =>
      shared.add((absolutePath, name));
}

WorkspaceFile workspaceFile(
  String path, {
  int sizeBytes = 10,
  DateTime? modifiedAt,
}) {
  final slash = path.indexOf('/');
  return WorkspaceFile(
    path: path,
    name: path.substring(slash + 1),
    area: path.startsWith('out/') ? WorkspaceArea.out : WorkspaceArea.inbox,
    sizeBytes: sizeBytes,
    modifiedAt: modifiedAt ?? DateTime(2026, 11, 13, 14, 5),
  );
}
