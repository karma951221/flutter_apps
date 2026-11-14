import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../attachment/attachment_loader.dart';
import '../attachment/attachment_rules.dart';
import '../attachment/chat_attachment.dart';
import '../chat_model.dart';
import '../workspace/workspace.dart';
import '../workspace/workspace_changes.dart';
import 'tool_result.dart';
import 'tool_summary.dart';
import 'write_plan.dart';

/// 모델이 작업 폴더(inbox · out)의 파일을 찾고 읽는 도구 둘(list_files · read_file)과
/// out 에 글 파일을 만들고 · 고치고 · 지우는 쓰기 도구 셋(write_file · edit_file · delete_file).
/// 쓰기는 [prepareWrite](검증, 디스크 그대로) → 사용자 승인 → [apply] 두 단계다.
/// [run] · [prepareWrite] · [apply] 는 던지지 않는다 — 실패는 `{"error": 코드}` 결과로 돌려준다.
/// [apply] 가 쓰거나 지우면 [WorkspaceChanges] 로 알린다(열린 작업 폴더 화면이 다시 읽게).
@lazySingleton
class WorkspaceTools {
  WorkspaceTools(this._workspace, this._loader, {WorkspaceChanges? changes})
    : _changes = changes;

  final Workspace _workspace;
  final AttachmentLoader _loader;
  final WorkspaceChanges? _changes;

  static const listFilesName = 'list_files';
  static const readFileName = 'read_file';

  /// list_files 가 돌려주는 최대 개수.
  static const maxListed = 100;

  /// read_file 이 글 파일에서 한 번에 돌려주는 최대 글자(코드 포인트) 수.
  static const maxChars = 20000;

  static const _listSpec = ToolSpec(
    name: listFilesName,
    description:
        '작업 폴더의 파일 목록을 최신순으로 본다(최대 100개). inbox 는 사용자가 첨부한 파일, '
        'out 은 저장한 답이다. 결과의 path 를 read_file 에 그대로 쓴다.',
    parameters: {
      'type': 'object',
      'properties': {
        'area': {
          'type': 'string',
          'enum': ['inbox', 'out', 'all'],
          'description': '볼 구역. 생략하면 all',
        },
      },
    },
  );

  static const _readSpec = ToolSpec(
    name: readFileName,
    description:
        '작업 폴더의 파일 하나를 읽는다. 글 파일(txt · md · csv · json · log)은 한 번에 '
        '20,000자까지 주고 next_offset 이 있으면 offset 에 넣어 이어 읽는다. '
        '사진과 PDF 는 그대로 보여 준다.',
    parameters: {
      'type': 'object',
      'properties': {
        'path': {
          'type': 'string',
          'description': 'list_files 결과의 path(예: inbox/메모.md)',
        },
        'offset': {
          'type': 'integer',
          'description': '글 파일에서 읽기 시작할 글자 위치. 생략하면 0',
        },
      },
      'required': ['path'],
    },
  );

  List<ToolSpec> get definitions => const [_listSpec, _readSpec];

  static const writeFileName = 'write_file';
  static const editFileName = 'edit_file';
  static const deleteFileName = 'delete_file';
  static const writeNames = {writeFileName, editFileName, deleteFileName};

  /// 쓰는 내용 · 고친 결과의 최대 글자(코드 포인트) 수.
  static const maxWriteChars = 100000;

  /// 쓰기 파일 이름의 최대 글자(코드 포인트) 수.
  static const maxWriteNameChars = 120;

  static const _writableExtensions = {'md', 'txt', 'csv', 'json'};

  /// AnswerFile 과 같은 금지 글자 + DEL.
  static final _forbiddenName = RegExp(r'[\\/:*?"<>|\x00-\x1f\x7f]');

  static const _pathDescription =
      'out/<이름> 만(하위 폴더 · . 으로 시작하는 이름 없음, 확장자 md · txt · csv · json)';

  static const _writeSpec = ToolSpec(
    name: writeFileName,
    description:
        '작업 폴더 out 에 글 파일을 만든다(최대 100,000자). 이미 있으면 exists 오류 — '
        '덮어쓰려면 overwrite 를 true 로. 사용자가 승인해야 저장된다.',
    parameters: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string', 'description': _pathDescription},
        'content': {'type': 'string', 'description': '파일 내용 전체'},
        'overwrite': {
          'type': 'boolean',
          'description': '이미 있는 파일을 덮어쓸지. 생략하면 false',
        },
      },
      'required': ['path', 'content'],
    },
  );

  static const _editSpec = ToolSpec(
    name: editFileName,
    description:
        'out 의 글 파일에서 old_text 를 new_text 로 바꾼다. old_text 는 파일에 정확히 '
        '한 번 나와야 한다(없으면 no_match, 여럿이면 not_unique — 앞뒤를 더 넣어 하나로). '
        '사용자가 승인해야 고쳐진다.',
    parameters: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string', 'description': _pathDescription},
        'old_text': {'type': 'string', 'description': '바꿀 부분(비지 않게)'},
        'new_text': {'type': 'string', 'description': '넣을 부분(비우면 지운다)'},
      },
      'required': ['path', 'old_text', 'new_text'],
    },
  );

  static const _deleteSpec = ToolSpec(
    name: deleteFileName,
    description: 'out 의 글 파일 하나를 지운다. 사용자가 승인해야 지워진다.',
    parameters: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string', 'description': _pathDescription},
      },
      'required': ['path'],
    },
  );

  List<ToolSpec> get writeDefinitions => const [
    _writeSpec,
    _editSpec,
    _deleteSpec,
  ];

  /// 쓰기 호출을 검증해 [WritePlan] 을 주거나, 오류면 [ToolResult](isError)를 준다.
  /// 디스크를 바꾸지 않는다. 던지지 않는다.
  Future<Object> prepareWrite(String name, Map<String, Object?> input) async {
    final kind = chatToolKindOf(name);
    try {
      if (!writeNames.contains(name)) return _error(kind, 'tool_failed');
      final checked = await _checkWritePath(input['path']);
      if (checked case final String code) return _error(kind, code);
      final path = checked as _WritePath;
      return switch (name) {
        writeFileName => await _prepareWriteFile(path, input),
        editFileName => await _prepareEdit(path, input),
        _ => await _prepareDelete(path),
      };
    } catch (_) {
      return _error(kind, 'tool_failed');
    }
  }

  /// 승인된 [plan] 을 실행한다. 지금 내용을 다시 읽어 준비 때와 다르면 쓰지 않고
  /// `changed`(만들기는 그 사이 생겼으면 `exists`). 던지지 않는다. 성공하면 바뀜을 알린다.
  Future<ToolResult> apply(WritePlan plan) async {
    final result = await _apply(plan);
    if (!result.isError) _changes?.notify();
    return result;
  }

  Future<ToolResult> _apply(WritePlan plan) async {
    final kind = switch (plan) {
      WriteCreate() || WriteOverwrite() => ChatToolKind.writeFile,
      WriteEdit() => ChatToolKind.editFile,
      WriteDelete() => ChatToolKind.deleteFile,
    };
    try {
      switch (plan) {
        case WriteCreate(:final path, :final name, :final content):
          if (await _workspace.exists(path)) return _error(kind, 'exists');
          await _workspace.writeText(path, content, overwrite: false);
          return _writeOk(kind, path, name, content, created: true);
        case WriteOverwrite(
          :final path,
          :final name,
          :final content,
          :final previous,
        ):
          if (!await _unchanged(path, previous)) {
            return _error(kind, 'changed');
          }
          await _workspace.writeText(path, content, overwrite: true);
          return _writeOk(kind, path, name, content, created: false);
        case WriteEdit(
          :final path,
          :final name,
          :final content,
          :final previous,
        ):
          if (!await _unchanged(path, previous)) {
            return _error(kind, 'changed');
          }
          await _workspace.writeText(path, content, overwrite: true);
          return _writeOk(kind, path, name, content);
        case WriteDelete(:final path, :final name, :final previous):
          if (!await _unchanged(path, previous)) {
            return _error(kind, 'changed');
          }
          if (!await _workspace.delete(path)) return _error(kind, 'changed');
          return ToolResult(
            json: jsonEncode({'path': path, 'name': name, 'deleted': true}),
            summary: ToolSummary(kind: kind, count: 1),
          );
      }
    } on WorkspaceFileExistsException {
      return _error(kind, 'exists');
    } on WorkspacePathException {
      return _error(kind, 'outside_workspace');
    } catch (_) {
      return _error(kind, 'tool_failed');
    }
  }

  /// 사용자가 쓰기 [name] 을 거절했다.
  ToolResult declined(String name) => ToolResult(
    json: jsonEncode({'error': 'user_declined'}),
    isError: true,
    summary: ToolSummary(
      kind: chatToolKindOf(name),
      count: 0,
      isError: true,
      declined: true,
    ),
  );

  /// 경로 검증. 통과하면 [_WritePath], 아니면 오류 코드. 경계 판정이 먼저 —
  /// 밖의 경로는 다른 규칙도 알려 주지 않는다.
  Future<Object> _checkWritePath(Object? raw) async {
    final path = raw is String ? raw.trim() : '';
    if (path.isEmpty) return 'invalid_path';
    try {
      await _workspace.absolutePath(path);
    } on WorkspacePathException {
      return 'outside_workspace';
    }
    final segments = path.split('/');
    if (segments.first == 'inbox') return 'read_only';
    if (segments.length != 2 || segments.first != 'out') return 'invalid_path';
    final name = segments[1];
    final dot = name.lastIndexOf('.');
    if (name.isEmpty ||
        name.startsWith('.') ||
        name.runes.length > maxWriteNameChars ||
        _forbiddenName.hasMatch(name) ||
        dot < 0 ||
        !_writableExtensions.contains(name.substring(dot + 1).toLowerCase())) {
      return 'invalid_path';
    }
    return _WritePath(path, name);
  }

  Future<Object> _prepareWriteFile(
    _WritePath at,
    Map<String, Object?> input,
  ) async {
    const kind = ChatToolKind.writeFile;
    final content = input['content'];
    if (content is! String) return _error(kind, 'invalid_input');
    if (content.runes.length > maxWriteChars) return _error(kind, 'too_large');
    final bytes = await _workspace.readBytes(at.path);
    if (bytes == null) {
      return WritePlan.create(path: at.path, name: at.name, content: content);
    }
    if (input['overwrite'] != true) return _error(kind, 'exists');
    final previous = _decode(bytes);
    if (previous == null) return _error(kind, 'not_text');
    return WritePlan.overwrite(
      path: at.path,
      name: at.name,
      content: content,
      previous: previous,
    );
  }

  Future<Object> _prepareEdit(_WritePath at, Map<String, Object?> input) async {
    const kind = ChatToolKind.editFile;
    final oldText = input['old_text'];
    final newText = input['new_text'];
    if (oldText is! String || oldText.isEmpty || newText is! String) {
      return _error(kind, 'invalid_input');
    }
    final bytes = await _workspace.readBytes(at.path);
    if (bytes == null) return _error(kind, 'not_found');
    final previous = _decode(bytes);
    if (previous == null) return _error(kind, 'not_text');
    final first = previous.indexOf(oldText);
    if (first < 0) return _error(kind, 'no_match');
    // 겹쳐 나오는 것도 센다("aa" 는 "aaa" 에 두 번).
    if (previous.indexOf(oldText, first + 1) >= 0) {
      return _error(kind, 'not_unique');
    }
    final content = previous.replaceRange(
      first,
      first + oldText.length,
      newText,
    );
    if (content.runes.length > maxWriteChars) return _error(kind, 'too_large');
    return WritePlan.edit(
      path: at.path,
      name: at.name,
      oldText: oldText,
      newText: newText,
      previous: previous,
      content: content,
    );
  }

  Future<Object> _prepareDelete(_WritePath at) async {
    const kind = ChatToolKind.deleteFile;
    final bytes = await _workspace.readBytes(at.path);
    if (bytes == null) return _error(kind, 'not_found');
    final previous = _decode(bytes);
    if (previous == null) return _error(kind, 'not_text');
    return WritePlan.delete(
      path: at.path,
      name: at.name,
      previous: previous,
      sizeBytes: bytes.length,
    );
  }

  /// 지금 내용이 [previous] 와 같은가. 없어졌거나 글이 아니게 됐으면 false.
  Future<bool> _unchanged(String path, String previous) async {
    final bytes = await _workspace.readBytes(path);
    return bytes != null && _decode(bytes) == previous;
  }

  /// UTF-8 이 아니면 null.
  static String? _decode(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }

  static ToolResult _writeOk(
    ChatToolKind kind,
    String path,
    String name,
    String content, {
    bool? created,
  }) => ToolResult(
    json: jsonEncode({
      'path': path,
      'name': name,
      'chars': content.runes.length,
      'created': ?created,
    }),
    summary: ToolSummary(kind: kind, count: 1),
  );

  Future<ToolResult> run(String name, Map<String, Object?> input) async {
    try {
      return switch (name) {
        listFilesName => await _listFiles(input),
        readFileName => await _readFile(input),
        _ => _error(ChatToolKind.other, 'tool_failed'),
      };
    } catch (_) {
      return _error(chatToolKindOf(name), 'tool_failed');
    }
  }

  Future<ToolResult> _listFiles(Map<String, Object?> input) async {
    final areas = switch (input['area']) {
      'inbox' => [WorkspaceArea.inbox],
      'out' => [WorkspaceArea.out],
      _ => WorkspaceArea.values,
    };
    final all = <WorkspaceFile>[
      for (final area in areas) ...await _workspace.list(area),
    ]..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    final shown = all.take(maxListed).toList();
    return ToolResult(
      json: jsonEncode({
        'files': [
          for (final f in shown)
            {
              'path': f.path,
              'name': f.name,
              'area': f.area.name,
              'kind': _kindName(f.name),
              'size': f.sizeBytes,
              'modified': _local(f.modifiedAt),
            },
        ],
        'truncated': all.length > maxListed,
      }),
      summary: ToolSummary(kind: ChatToolKind.listFiles, count: shown.length),
    );
  }

  Future<ToolResult> _readFile(Map<String, Object?> input) async {
    final raw = input['path'];
    final path = raw is String ? raw.trim() : '';
    if (path.isEmpty) return _readError('invalid_path');

    // 경계 판정이 먼저 — 밖의 경로는 존재 여부도 알려 주지 않는다.
    final String absolute;
    try {
      absolute = await _workspace.absolutePath(path);
    } on WorkspacePathException {
      return _readError('outside_workspace');
    }
    // 존재 여부보다 먼저 — 구역 밖 · 숨김 경로는 있는지도 알려 주지 않는다.
    if (!isReadablePath(path)) return _readError('invalid_path');
    if (!await _workspace.exists(path)) return _readError('not_found');

    final name = path.substring(path.lastIndexOf('/') + 1);
    if (AttachmentRules.kindOf(name) == null) {
      return _readError('unsupported_type');
    }

    // 크기는 목록을 다시 훑지 않고 0 으로 넘긴다 — 로더가 실제 파일 길이로 다시 잰다.
    final load = await _loader.load(
      PickedFile(name: name, path: absolute, sizeBytes: 0, workspacePath: path),
    );
    switch (load) {
      case AttachmentRejected(:final why):
        return _readError(switch (why) {
          AttachmentRejection.tooLarge => 'too_large',
          AttachmentRejection.notUtf8 => 'not_text',
          _ => 'unsupported_type',
        });
      case AttachmentLoaded(:final attachment):
        const summary = ToolSummary(kind: ChatToolKind.readFile, count: 1);
        switch (attachment) {
          case ImageAttachment(:final mediaType, :final bytes):
            return ToolResult(
              json: jsonEncode({'path': path, 'name': name, 'kind': 'image'}),
              images: [ToolImage(mediaType: mediaType, bytes: bytes)],
              summary: summary,
            );
          case PdfAttachment(:final bytes):
            return ToolResult(
              json: jsonEncode({'path': path, 'name': name, 'kind': 'pdf'}),
              documents: [ToolDocument(name: name, bytes: bytes)],
              summary: summary,
            );
          case TextAttachment(:final text):
            final offset = switch (input['offset']) {
              int v when v > 0 => v,
              double v when v.isFinite && v > 0 && v == v.truncateToDouble() =>
                v.toInt(),
              _ => 0,
            };
            // 코드 포인트 단위로 자른다 — 서로게이트 쌍이 갈라지지 않는다.
            final runes = text.runes.toList();
            final total = runes.length;
            final start = offset > total ? total : offset;
            final end = start + maxChars > total ? total : start + maxChars;
            return ToolResult(
              json: jsonEncode({
                'path': path,
                'name': name,
                'text': String.fromCharCodes(runes.sublist(start, end)),
                'offset': offset,
                'next_offset': end < total ? end : null,
                'total_chars': total,
              }),
              summary: summary,
            );
        }
    }
  }

  /// 도구가 다룰 수 있는 경로 — `inbox/` 또는 `out/` 아래이고 어느 부분도 `.` 으로
  /// 시작하지 않는다(숨김 · `.` · `..` 없음). 구역 이름만(`inbox`)은 아니다.
  static bool isReadablePath(String path) {
    final segments = path.split('/');
    if (segments.length < 2) return false;
    if (segments.first != 'inbox' && segments.first != 'out') return false;
    return segments.every((s) => s.isNotEmpty && !s.startsWith('.'));
  }

  static String _kindName(String fileName) =>
      switch (AttachmentRules.kindOf(fileName)) {
        AttachmentKind.image => 'image',
        AttachmentKind.pdf => 'pdf',
        AttachmentKind.text => 'text',
        null => 'other',
      };

  static ToolResult _readError(String code) =>
      _error(ChatToolKind.readFile, code);

  static ToolResult _error(ChatToolKind kind, String code) => ToolResult(
    json: jsonEncode({'error': code}),
    isError: true,
    summary: ToolSummary(kind: kind, count: 0, isError: true),
  );

  /// 로컬 `yyyy-MM-ddTHH:mm`.
  static String _local(DateTime time) {
    final d = time.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}'
        'T${two(d.hour)}:${two(d.minute)}';
  }
}

/// 검증을 지난 쓰기 경로(`out/<이름>`)와 이름.
class _WritePath {
  const _WritePath(this.path, this.name);

  final String path;
  final String name;
}
