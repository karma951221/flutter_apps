import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
import '../../../domain/backup/backup_failure.dart';
import '../../chat/database/chat_database.dart';
import '../../chat/prefs_chat_history_settings.dart';
import 'dir_swap.dart';
import 'drift_rows.dart';

const _dataFile = 'conversations.json';
const _prefsFile = 'prefs.json';
const _workspace = 'workspace';

/// 대화 설정 중 백업에 담는 키. 동의 · 키 상태 · 모델 캐시(`chat.*`)와 위키 설정은 담지 않는다.
const _prefKeys = [
  PrefsChatHistorySettings.retentionKey,
  PrefsChatHistorySettings.useRecordsKey,
];

/// 물어보기 대화 영역. `chat/conversations.json`(대화 · 턴 · 사용량 행) ·
/// `chat/workspace/`(첨부 · 작업 폴더 파일) · `chat/prefs.json`(대화 설정)을 쓴다.
///
/// 같은 DB 의 `wiki_notes` 는 위키 영역 몫이라 건드리지 않는다. 다만 바꾼 뒤 없어진
/// 대화를 가리키던 위키 출처는 지금 삭제 규칙(set null)대로 null 이 된다.
class ChatBackupArea implements BackupAreaSource {
  /// [_workspaceRoot] 는 문서 폴더의 `workspace/`.
  ChatBackupArea(this._db, this._workspaceRoot, this._prefs);

  final ChatDatabase _db;
  final Directory _workspaceRoot;
  final SharedPreferences _prefs;

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
    'conversations': await _count(_db.conversations),
    'files': (await _workspaceFiles()).length,
  };

  Future<int> _count(TableInfo<Table, dynamic> table) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM "${table.actualTableName}"',
          readsFrom: {table},
        )
        .getSingle();
    return row.read<int>('c');
  }

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
    await Directory('${out.path}/$_workspace').create(recursive: true);

    final data = await _db.transaction(
      () async => {
        for (final t in _deleteOrder.reversed)
          t.actualTableName: await dumpTable(_db, t),
      },
    );
    await File('${out.path}/$_dataFile').writeAsString(jsonEncode(data));

    final files = await _workspaceFiles();
    for (final f in files) {
      final relative = f.path.substring(_workspaceRoot.path.length + 1);
      final target = File('${out.path}/$_workspace/$relative');
      await target.parent.create(recursive: true);
      await f.copy(target.path);
    }

    await File('${out.path}/$_prefsFile').writeAsString(
      jsonEncode({
        for (final key in _prefKeys)
          if (_prefs.get(key) case final Object value) key: value,
      }),
    );

    return {
      'conversations': data[_db.conversations.actualTableName]!.length,
      'files': files.length,
    };
  }

  @override
  Future<void> validate(Directory root) async {
    final data = await _readData(root);
    final conversationIds = {
      for (final c in data[_db.conversations.actualTableName]!) c['id'],
    };
    for (final t in data[_db.chatTurns.actualTableName]!) {
      if (!conversationIds.contains(t['conversation_id'])) {
        throw const BackupException(BackupFailure.integrity);
      }
    }
  }

  @override
  Future<void> replace(Directory root) async {
    final data = await _readData(root);
    final prefs = await _readPrefs(root);
    final incoming = Directory('${_areaDir(root).path}/$_workspace');
    // 작업 폴더가 비어 있던 백업이면 빈 폴더로 바꿔 넣는다.
    await incoming.create(recursive: true);
    await _workspaceRoot.parent.create(recursive: true);

    await swapDirectory(_workspaceRoot, incoming, () async {
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
      });
    });

    for (final key in _prefKeys) {
      switch (prefs[key]) {
        case final String v:
          await _prefs.setString(key, v);
        case final bool v:
          await _prefs.setBool(key, v);
        default:
          await _prefs.remove(key);
      }
    }
  }

  /// 출처가 있는 위키 메모의 id → 출처 대화 id.
  Future<Map<int, String>> _wikiSources() async {
    final rows = await (_db.select(
      _db.wikiNotes,
    )..where((n) => n.sourceConversationId.isNotNull())).get();
    return {for (final n in rows) n.id: n.sourceConversationId!};
  }

  @override
  Future<void> afterRestore() async {}

  /// `conversations.json` 을 테이블 이름 → 행 목록으로 읽는다. 없거나 모양이 다르면 integrity.
  Future<Map<String, List<Map<String, Object?>>>> _readData(
    Directory root,
  ) async {
    try {
      final file = File('${_areaDir(root).path}/$_dataFile');
      final json =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      return {
        for (final t in _deleteOrder)
          t.actualTableName: [
            for (final row in json[t.actualTableName]! as List<Object?>)
              row! as Map<String, Object?>,
          ],
      };
    } catch (_) {
      throw const BackupException(BackupFailure.integrity);
    }
  }

  /// `prefs.json` 을 읽는다. 없으면 빈 설정으로 본다.
  Future<Map<String, Object?>> _readPrefs(Directory root) async {
    final file = File('${_areaDir(root).path}/$_prefsFile');
    if (!await file.exists()) return const {};
    try {
      return jsonDecode(await file.readAsString()) as Map<String, Object?>;
    } catch (_) {
      throw const BackupException(BackupFailure.integrity);
    }
  }
}
