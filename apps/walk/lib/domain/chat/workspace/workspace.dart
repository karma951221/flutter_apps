import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace.freezed.dart';

/// 작업 폴더의 두 구역. inbox 는 사용자가 올린 파일, out 은 Claude 가 만든 파일.
enum WorkspaceArea { inbox, out }

/// 작업 폴더 안 파일 하나. [path] 는 작업 폴더 기준 상대 경로(`inbox/…`).
@freezed
class WorkspaceFile with _$WorkspaceFile {
  @override
  final String path;
  @override
  final String name;
  @override
  final WorkspaceArea area;
  @override
  final int sizeBytes;
  @override
  final DateTime modifiedAt;

  const WorkspaceFile({
    required this.path,
    required this.name,
    required this.area,
    required this.sizeBytes,
    required this.modifiedAt,
  });
}

/// 경로가 작업 폴더 밖을 가리킨다(`..` · 절대 경로 · 밖으로 나가는 심볼릭 링크).
class WorkspacePathException implements Exception {
  const WorkspacePathException(this.path);

  final String path;

  @override
  String toString() => 'WorkspacePathException: $path';
}

/// 앱이 관리하는 작업 폴더. 모든 경로는 작업 폴더 상대 경로이고,
/// 경계를 벗어나면 [WorkspacePathException] 을 던진다.
abstract interface class Workspace {
  /// 최신순. 숨김 파일(`.` 로 시작)은 뺀다.
  Future<List<WorkspaceFile>> list(WorkspaceArea area);

  /// inbox 에 저장하고 상대 경로를 돌려준다. 이름이 겹치면 `-2` 를 붙인다.
  Future<String> importToInbox(String name, Uint8List bytes);

  /// out 에 UTF-8 로 저장하고 상대 경로를 돌려준다. 이름이 겹치면 `-2` 를 붙인다.
  Future<String> writeOut(String fileName, String content);

  /// 없으면 null.
  Future<Uint8List?> readBytes(String path);

  Future<bool> exists(String path);

  /// 지웠으면 true, 없었으면 false.
  Future<bool> delete(String path);

  /// 공유 · 로더용 절대 경로. 경계 밖이면 [WorkspacePathException].
  ///
  /// 동기라서, 작업 폴더가 한 번이라도 열린 뒤(list · import · read 등)에만
  /// 안쪽 경로를 돌려준다. 경계 밖 판정은 언제나 먼저 한다.
  String absolutePath(String path);
}
