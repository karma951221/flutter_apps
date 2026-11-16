import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
import '../../../domain/backup/backup_failure.dart';
import '../../chat/database/chat_database.dart';
import '../../chat/prefs_chat_history_settings.dart';
import 'area_io.dart';
import 'drift_rows.dart';
import 'prefs_snapshot.dart';

const _dataFile = 'notes.json';
const _prefsFile = 'prefs.json';
const _sourceColumn = 'source_conversation_id';

/// LLM 위키 영역. `wiki/notes.json`(`wiki_notes` 행, 정수 id 그대로) ·
/// `wiki/prefs.json`(`walk.chat.wikiIndexSize`)을 쓴다.
///
/// 같은 DB 의 대화 테이블은 건드리지 않는다. 지금 기기에 없는 대화를 가리키는 출처는
/// null 로 넣는다(대화를 지울 때의 규칙과 같다).
class WikiBackupArea implements BackupAreaSource {
  WikiBackupArea(this._db, this._prefs);

  final ChatDatabase _db;
  final SharedPreferences _prefs;

  static const _prefKeys = {PrefsChatHistorySettings.wikiIndexSizeKey};

  String get _table => _db.wikiNotes.actualTableName;

  Directory _areaDir(Directory root) => Directory('${root.path}/${id.name}');

  @override
  BackupAreaId get id => BackupAreaId.wiki;

  @override
  Map<String, int> get schema => {'chat': _db.schemaVersion};

  @override
  Future<Map<String, int>> counts() async => {
    'notes': await countRows(_db, _db.wikiNotes),
  };

  /// 메모 글자 수의 합(UTF-8 이면 한글은 그 세 배쯤이라 넉넉히 곱한다).
  @override
  Future<int> estimatedBytes() async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(LENGTH(title) + LENGTH(summary) + '
          'LENGTH(body)), 0) AS c FROM "$_table"',
          readsFrom: {_db.wikiNotes},
        )
        .getSingle();
    return row.read<int>('c') * 3;
  }

  @override
  Future<Map<String, int>> export(Directory root) async {
    final out = _areaDir(root);
    await out.create(recursive: true);

    final rows = await dumpTable(_db, _db.wikiNotes);
    await writeAreaJson(out, _dataFile, {_table: rows});
    await writeAreaJson(out, _prefsFile, await dumpPrefs(_prefs, _prefKeys));

    return {'notes': rows.length};
  }

  @override
  Future<void> validate(Directory root) async {
    final rows = await _readRows(root);
    final ids = <int>{};
    for (final row in rows) {
      // id 는 모델이 보는 정수라 그대로 넣는다. 정수가 아니거나 겹치면 깨진 백업.
      if (row['id'] case final int noteId when ids.add(noteId)) continue;
      throw const BackupException(BackupFailure.integrity);
    }
  }

  @override
  Future<void> replace(Directory root) async {
    final rows = await _readRows(root);
    final prefs = await readPrefsSnapshot(
      _areaDir(root),
      _prefsFile,
      _prefKeys,
    );

    await _db.transaction(() async {
      final conversationIds = {
        for (final c in await _db.select(_db.conversations).get()) c.id,
      };
      await deleteAllRows(_db, _db.wikiNotes);
      await insertRows(_db, _db.wikiNotes, [
        for (final row in rows)
          if (row[_sourceColumn] case final Object source
              when !conversationIds.contains(source))
            {...row, _sourceColumn: null}
          else
            row,
      ]);
      await _resetSequence();
    });

    await restorePrefs(_prefs, _prefKeys, prefs);
  }

  /// 자동 증가가 넣은 메모의 최대 id 다음부터 이어지게 한다. 지운 행이 있어도
  /// `sqlite_sequence` 는 줄지 않으므로 직접 맞춘다(메모가 없으면 1부터).
  Future<void> _resetSequence() async {
    await _db.customStatement('DELETE FROM sqlite_sequence WHERE name = ?', [
      _table,
    ]);
    await _db.customStatement(
      'INSERT INTO sqlite_sequence (name, seq) '
      'SELECT ?, m FROM (SELECT MAX(id) AS m FROM "$_table") '
      'WHERE m IS NOT NULL',
      [_table],
    );
  }

  @override
  Future<void> afterRestore() async {}

  /// `notes.json` 의 행 목록. 없거나 모양이 다르면 integrity.
  Future<List<Map<String, Object?>>> _readRows(Directory root) async =>
      (await readTableRows(_areaDir(root), _dataFile, [
        _db.wikiNotes,
      ]))[_table]!;
}
