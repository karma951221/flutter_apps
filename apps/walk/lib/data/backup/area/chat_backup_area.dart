import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
import '../../../domain/backup/restore_notice.dart';
import '../../../domain/backup/backup_failure.dart';
import '../../../domain/chat/chat_settings.dart';
import '../../chat/database/chat_database.dart';
import '../../chat/prefs_chat_history_settings.dart';
import 'area_io.dart';
import 'dir_swap.dart';
import 'drift_rows.dart';
import 'prefs_snapshot.dart';

const _dataFile = 'conversations.json';
const _prefsFile = 'prefs.json';
const _wikiLinksFile = 'wiki_links.json';
const _workspace = 'workspace';

/// 대화 설정 중 백업에 담는 키. 동의 · 키 상태 · 모델 캐시(`chat.*`)와 위키 설정은 담지 않는다.
const _prefKeys = {
  PrefsChatHistorySettings.retentionKey,
  PrefsChatHistorySettings.useRecordsKey,
};

/// 물어보기 대화 영역. `chat/conversations.json`(대화 · 턴 · 사용량 행) ·
/// `chat/workspace/`(첨부 · 작업 폴더 파일) · `chat/prefs.json`(대화 설정)을 쓴다.
///
/// 같은 DB 의 `wiki_notes` 는 위키 영역 몫이라 건드리지 않는다. 다만 바꾼 뒤 없어진
/// 대화를 가리키던 위키 출처는 지금 삭제 규칙(set null)대로 null 이 된다.
///
/// 그래서 `chat/wiki_links.json` 에 위키 메모 → 출처 대화 연결을 함께 담고, `replace` 가 메모와
/// 대화가 둘 다 있으면 다시 잇는다 — 대화만 복원했다가 되돌려도 출처가 돌아온다. 메모는 id 와
/// 만든 시각이 모두 같을 때만 같은 메모로 본다(다른 기기의 같은 id 메모에 붙지 않게).
class ChatBackupArea implements BackupAreaSource {
  /// [_workspaceRoot] 는 문서 폴더의 `workspace/`.
  ChatBackupArea(this._db, this._workspaceRoot, this._prefs, this._settings);

  final ChatDatabase _db;
  final Directory _workspaceRoot;
  final SharedPreferences _prefs;

  /// API 키는 백업에 담지 않으므로 복원 뒤 키가 있는지만 본다.
  final ChatSettings _settings;

  /// 지울 때 순서(자식 → 부모). 넣을 때는 거꾸로.
  List<TableInfo<Table, dynamic>> get _deleteOrder => [
    _db.chatTurns,
    _db.chatUsageRows,
    _db.conversations,
  ];

  Directory _areaDir(Directory root) => Directory('${root.path}/${id.name}');

  @override
  BackupAreaId get id => BackupAreaId.chat;

  @override
  Map<String, int> get schema => {'chat': _db.schemaVersion};

  @override
  Future<Map<String, int>> counts() async => {
    'conversations': await countRows(_db, _db.conversations),
    'files': (await _workspaceFiles()).length,
  };

  /// 작업 폴더의 파일들. 링크는 따라가지 않는다 — 폴더 밖을 가리킬 수 있다.
  Future<List<File>> _workspaceFiles() async {
    if (!await _workspaceRoot.exists()) return const [];
    return [
      await for (final f in _workspaceRoot.list(
        recursive: true,
        followLinks: false,
      ))
        if (f is File) f,
    ];
  }

  /// 작업 폴더 파일 크기의 합. DB 행 · 설정은 그에 비해 작아 넣지 않는다.
  @override
  Future<int> estimatedBytes() async {
    var total = 0;
    for (final f in await _workspaceFiles()) {
      total += await f.length();
    }
    return total;
  }

  @override
  Future<Map<String, int>> export(Directory root) async {
    final out = _areaDir(root);
    await createFilesFolder(Directory('${out.path}/$_workspace'));

    final data = await dumpTables(_db, _deleteOrder.reversed);
    await writeAreaJson(out, _dataFile, data);

    final files = await _workspaceFiles();
    for (final f in files) {
      final relative = f.path.substring(_workspaceRoot.path.length + 1);
      final target = File('${out.path}/$_workspace/$relative');
      await target.parent.create(recursive: true);
      await f.copy(target.path);
    }

    await writeAreaJson(out, _prefsFile, await dumpPrefs(_prefs, _prefKeys));
    await writeAreaJson(out, _wikiLinksFile, {
      'links': [
        for (final n in await _linkedNotes())
          {
            'note': n.id,
            'createdAtMs': n.createdAt.millisecondsSinceEpoch,
            'conversation': n.sourceConversationId,
          },
      ],
    });

    return {
      'conversations': data[_db.conversations.actualTableName]!.length,
      'files': files.length,
    };
  }

  @override
  Future<void> validate(Directory root) async {
    await _readWikiLinks(root);
    final data = await _readData(root);
    final conversationIds = {
      for (final c in data[_db.conversations.actualTableName]!) c['id'],
    };
    for (final t in data[_db.chatTurns.actualTableName]!) {
      if (!conversationIds.contains(t['conversation_id']) ||
          !_attachmentPathsContained(t['attachments'])) {
        throw const BackupException(BackupFailure.integrity);
      }
    }
  }

  /// 턴의 첨부 ref JSON 의 작업 폴더 경로가 모두 작업 폴더 안의 상대 경로인가. 읽을 수 없는
  /// JSON 은 앱이 첨부 없음으로 읽으므로 막지 않는다.
  static bool _attachmentPathsContained(Object? raw) {
    if (raw is! String) return true;
    final Object? refs;
    try {
      refs = jsonDecode(raw);
    } on FormatException {
      return true;
    }
    if (refs is! List) return true;
    return refs.every(
      (r) => r is! Map || isContainedRelativePath(r['workspacePath']),
    );
  }

  @override
  Future<void> replace(Directory root) async {
    final data = await _readData(root);
    final prefs = await readPrefsSnapshot(
      _areaDir(root),
      _prefsFile,
      _prefKeys,
    );
    final links = await _readWikiLinks(root);
    final incoming = Directory('${_areaDir(root).path}/$_workspace');
    // 폴더가 없으면 이미 옮겨 간 것이다 — 작업 폴더는 그대로 두고 DB 만 바꾼다.
    await replaceFilesFolder(_workspaceRoot, incoming, () async {
      await _db.transaction(() async {
        // 대화를 지우면 위키 출처가 set null 된다. 백업에도 있는 대화를 가리키던
        // 출처는 다시 넣은 뒤 되돌린다.
        final sources = await _wikiSources();
        for (final t in _deleteOrder) {
          await deleteAllRows(_db, t);
        }
        for (final t in _deleteOrder.reversed) {
          await insertRows(_db, t, data[t.actualTableName]!);
        }
        final kept = {
          for (final c in data[_db.conversations.actualTableName]!) c['id'],
        };
        for (final MapEntry(key: noteId, value: source) in sources.entries) {
          if (!kept.contains(source)) continue;
          await (_db.update(_db.wikiNotes)..where((n) => n.id.equals(noteId)))
              .write(WikiNotesCompanion(sourceConversationId: Value(source)));
        }
        // 백업이 담은 연결 중 출처가 빈 같은 메모를 다시 잇는다.
        for (final link in links) {
          if (!kept.contains(link.conversation)) continue;
          await (_db.update(_db.wikiNotes)..where(
                (n) =>
                    n.id.equals(link.note) &
                    n.createdAt.equals(
                      DateTime.fromMillisecondsSinceEpoch(link.createdAtMs),
                    ) &
                    n.sourceConversationId.isNull(),
              ))
              .write(
                WikiNotesCompanion(
                  sourceConversationId: Value(link.conversation),
                ),
              );
        }
      });
    });

    await restorePrefs(_prefs, _prefKeys, prefs);
  }

  /// 출처가 있는 위키 메모의 id → 출처 대화 id.
  Future<Map<int, String>> _wikiSources() async => {
    for (final n in await _linkedNotes()) n.id: n.sourceConversationId!,
  };

  /// 출처가 있는 위키 메모.
  Future<List<WikiNoteRow>> _linkedNotes() => (_db.select(
    _db.wikiNotes,
  )..where((n) => n.sourceConversationId.isNotNull())).get();

  /// `wiki_links.json`(예전 백업에는 없다). 모양이 다르면 integrity.
  Future<List<({int note, int createdAtMs, String conversation})>>
  _readWikiLinks(Directory root) async {
    final json = await readAreaJson(
      _areaDir(root),
      _wikiLinksFile,
      optional: true,
    );
    try {
      return [
        for (final l in (json['links'] ?? const <Object?>[]) as List<Object?>)
          if (l! as Map<String, Object?> case final m)
            (
              note: m['note']! as int,
              createdAtMs: m['createdAtMs']! as int,
              conversation: m['conversation']! as String,
            ),
      ];
    } catch (_) {
      throw const BackupException(BackupFailure.integrity);
    }
  }

  /// API 키가 없으면 다시 넣으라고 알린다.
  @override
  Future<Set<RestoreNotice>> afterRestore() async => {
    if (!await _settings.hasApiKey()) RestoreNotice.apiKeyNeeded,
  };

  Future<TableRows> _readData(Directory root) =>
      readTableRows(_areaDir(root), _dataFile, _deleteOrder);
}
