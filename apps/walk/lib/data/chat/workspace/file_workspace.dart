import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../domain/chat/workspace/workspace.dart';

/// 문서 폴더 아래 `workspace/` 를 작업 폴더로 쓴다.
///
/// 경계 판정은 두 단계다. 먼저 `p.normalize` 로 `..` 를 접은 경로가 root 안인지
/// 보고, 이미 있는 항목은 `resolveSymbolicLinks()` 결과도 root 안인지 한 번 더 본다.
@LazySingleton(as: Workspace)
class FileWorkspace implements Workspace {
  /// 테스트는 임시 폴더 · 고정 시계를 넘긴다.
  FileWorkspace(this._root, this._clock);

  /// DI 용 — 기본 root 는 문서 폴더 + `workspace`.
  @factoryMethod
  factory FileWorkspace.standard(Clock clock) => FileWorkspace(() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'workspace'));
  }, clock);

  final Future<Directory> Function() _root;
  final Clock _clock;

  static const _inbox = 'inbox';
  static const _out = 'out';

  /// 마지막으로 연 root 의 실경로. 동기 [absolutePath] 가 쓴다.
  String? _knownRoot;

  /// root 를 만들고 실경로(링크 해소)를 돌려준다. root 자체가 링크여도
  /// (예: macOS `/var` → `/private/var`) 비교가 맞는다.
  Future<String> _open() async {
    final dir = await _root();
    await dir.create(recursive: true);
    return _knownRoot = await dir.resolveSymbolicLinks();
  }

  /// 상대 경로를 접어 절대 경로로. 밖이면 예외(글자 수준 판정).
  String _check(String root, String path) {
    if (p.isAbsolute(path)) throw WorkspacePathException(path);
    final abs = p.normalize(p.join(root, path));
    if (!p.isWithin(root, abs)) throw WorkspacePathException(path);
    return abs;
  }

  /// 이미 있는 항목이면 링크를 풀어 한 번 더 경계를 본다.
  Future<void> _checkReal(String root, String path, String abs) async {
    final type = await FileSystemEntity.type(abs, followLinks: false);
    if (type == FileSystemEntityType.notFound) return;
    final String real;
    try {
      real = await File(abs).resolveSymbolicLinks();
    } on FileSystemException {
      throw WorkspacePathException(path); // 끊어진 링크
    }
    if (!p.isWithin(root, real)) throw WorkspacePathException(path);
  }

  Future<String> _safe(String path) async {
    final root = await _open();
    final abs = _check(root, path);
    await _checkReal(root, path, abs);
    return abs;
  }

  @override
  String absolutePath(String path) {
    if (p.isAbsolute(path)) throw WorkspacePathException(path);
    final root = _knownRoot;
    if (root == null) {
      // root 를 모르면 글자 수준으로만 밖 여부를 가린다.
      if (p.isWithin('/w', p.normalize(p.join('/w', path)))) {
        throw StateError('작업 폴더가 아직 열리지 않았다');
      }
      throw WorkspacePathException(path);
    }
    return _check(root, path);
  }

  @override
  Future<List<WorkspaceFile>> list(WorkspaceArea area) async {
    final root = await _open();
    final name = area == WorkspaceArea.inbox ? _inbox : _out;
    final dir = Directory(p.join(root, name));
    if (!await dir.exists()) return const [];
    final files = <WorkspaceFile>[];
    await for (final e in dir.list(followLinks: false)) {
      if (e is! File) continue;
      final base = p.basename(e.path);
      if (base.startsWith('.')) continue;
      final stat = await e.stat();
      files.add(
        WorkspaceFile(
          path: '$name/$base',
          name: base,
          area: area,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
        ),
      );
    }
    files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return files;
  }

  @override
  Future<String> importToInbox(String name, Uint8List bytes) {
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(_clock.now());
    return _save(
      _inbox,
      '$stamp-${sanitizeName(name)}',
      (f) => f.writeAsBytes(bytes),
    );
  }

  @override
  Future<String> writeOut(String fileName, String content) =>
      _save(_out, sanitizeName(fileName), (f) => f.writeAsString(content));

  /// 겹치지 않는 이름(`a.md` → `a-2.md`)으로 만들어 쓴다.
  Future<String> _save(
    String area,
    String fileName,
    Future<void> Function(File) write,
  ) async {
    final root = await _open();
    final dir = Directory(p.join(root, area));
    await dir.create(recursive: true);
    final stem = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName);
    var candidate = fileName;
    var n = 1;
    while (await FileSystemEntity.type(
          p.join(dir.path, candidate),
          followLinks: false,
        ) !=
        FileSystemEntityType.notFound) {
      n++;
      candidate = '$stem-$n$ext';
    }
    await write(File(p.join(dir.path, candidate)));
    return '$area/$candidate';
  }

  @override
  Future<Uint8List?> readBytes(String path) async {
    final file = File(await _safe(path));
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<bool> exists(String path) async => File(await _safe(path)).exists();

  @override
  Future<bool> delete(String path) async {
    final file = File(await _safe(path));
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  /// 파일 이름으로 못 쓰는 문자를 `_` 로 바꾸고 앞뒤 공백 · 점을 뗀다. 비면 `file`.
  static String sanitizeName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1f\x7f]'), '_')
        .replaceAll(RegExp(r'^[\s.]+|[\s.]+$'), '');
    return cleaned.isEmpty ? 'file' : cleaned;
  }
}
