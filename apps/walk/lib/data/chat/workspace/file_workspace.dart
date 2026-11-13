import 'dart:convert';
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
/// 보고, 그 항목(없으면 가장 가까운 있는 조상)의 `resolveSymbolicLinks()` 결과도 root
/// 안인지 한 번 더 본다.
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

  /// root 를 만들고 실경로(링크 해소)를 돌려준다. root 자체가 링크여도
  /// (예: macOS `/var` → `/private/var`) 비교가 맞는다.
  Future<String> _open() async {
    final dir = await _root();
    await dir.create(recursive: true);
    return dir.resolveSymbolicLinks();
  }

  /// 상대 경로를 접어 절대 경로로. 밖이면 예외(글자 수준 판정).
  String _check(String root, String path) {
    if (p.isAbsolute(path)) throw WorkspacePathException(path);
    final abs = p.normalize(p.join(root, path));
    if (!p.isWithin(root, abs)) throw WorkspacePathException(path);
    return abs;
  }

  /// 링크를 풀어 한 번 더 경계를 본다. 없는 항목이면 가장 가까운 있는 조상을 본다 —
  /// 밖을 가리키는 폴더 링크 아래(`inbox/<링크>/x`)는 x 가 있든 없든 밖이다(존재 여부를
  /// 흘리지 않는다). [_check] 를 지난 [abs] 라 조상은 늦어도 root 에서 멈춘다.
  Future<void> _checkReal(String root, String path, String abs) async {
    var target = abs;
    while (await FileSystemEntity.type(target, followLinks: false) ==
        FileSystemEntityType.notFound) {
      final parent = p.dirname(target);
      if (parent == target) return;
      target = parent;
    }
    final String real;
    try {
      real = await File(target).resolveSymbolicLinks();
    } on FileSystemException {
      throw WorkspacePathException(path); // 끊어진 링크
    }
    if (real != root && !p.isWithin(root, real)) {
      throw WorkspacePathException(path);
    }
  }

  Future<String> _safe(String path) async {
    final root = await _open();
    final abs = _check(root, path);
    await _checkReal(root, path, abs);
    return abs;
  }

  @override
  Future<String> absolutePath(String path) => _safe(path);

  @override
  Future<List<WorkspaceFile>> list(WorkspaceArea area) async {
    final root = await _open();
    final name = area == WorkspaceArea.inbox ? _inbox : _out;
    final dir = Directory(p.join(root, name));
    if (!await dir.exists()) return const [];
    // inbox/out 이 밖을 가리키는 링크면 밖의 파일을 보이게 된다 — 쓰기([_save])와 같은 판정.
    if (!p.isWithin(root, await dir.resolveSymbolicLinks())) {
      throw WorkspacePathException(name);
    }
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
    // inbox/out 이 밖을 가리키는 링크면 쓰기가 밖으로 샌다 — 실경로를 확인한다.
    if (!p.isWithin(root, await dir.resolveSymbolicLinks())) {
      throw WorkspacePathException(area);
    }
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

  /// [sanitizeName] 결과의 최대 바이트(UTF-8). inbox 시각 접두사(`yyyyMMdd-HHmmss-`, 16바이트)를
  /// 붙여도 200바이트 안 — 파일 시스템 이름 한도(255)에 겹침 번호(`-2`)까지 들어간다.
  static const maxNameBytes = 200 - 16;

  /// 이 바이트(점 포함)보다 긴 확장자는 확장자로 보지 않고 이름째 자른다.
  static const _maxExtensionBytes = 16;

  /// 파일 이름으로 못 쓰는 문자를 `_` 로 바꾸고 앞뒤 공백 · 점을 뗀다. 비면 `file`.
  /// [maxNameBytes] 를 넘으면 확장자를 남기고 이름 끝을 글자 단위로 자른다.
  static String sanitizeName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[/\\:*?"<>|\x00-\x1f\x7f]'), '_')
        .replaceAll(RegExp(r'^[\s.]+|[\s.]+$'), '');
    if (cleaned.isEmpty) return 'file';
    if (utf8.encode(cleaned).length <= maxNameBytes) return cleaned;
    var ext = p.extension(cleaned);
    if (utf8.encode(ext).length > _maxExtensionBytes) ext = '';
    final stem = cleaned.substring(0, cleaned.length - ext.length);
    final budget = maxNameBytes - utf8.encode(ext).length;
    final kept = StringBuffer();
    var used = 0;
    for (final rune in stem.runes) {
      final char = String.fromCharCode(rune);
      final size = utf8.encode(char).length;
      if (used + size > budget) break;
      kept.write(char);
      used += size;
    }
    final cut = kept.toString().replaceAll(RegExp(r'[\s.]+$'), '');
    return '${cut.isEmpty ? 'file' : cut}$ext';
  }
}
