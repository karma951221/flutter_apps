import 'dart:convert';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../attachment/attachment_loader.dart';
import '../attachment/attachment_rules.dart';
import '../attachment/chat_attachment.dart';
import '../chat_model.dart';
import '../workspace/workspace.dart';
import 'tool_result.dart';
import 'tool_summary.dart';

/// 모델이 작업 폴더(inbox · out)의 파일을 찾고 읽는 도구 둘(list_files · read_file).
/// [run] 은 던지지 않는다 — 실패는 `{"error": 코드}` 결과로 돌려준다.
@lazySingleton
class WorkspaceTools {
  /// [clock] 은 DI 시그니처를 맞추려고 받는다 — 수정 시각은 파일이 가진 값을 쓴다.
  WorkspaceTools(this._workspace, this._loader, Clock clock);

  final Workspace _workspace;
  final AttachmentLoader _loader;

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
