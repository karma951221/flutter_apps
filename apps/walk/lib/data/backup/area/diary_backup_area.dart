import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
import '../../../domain/backup/backup_failure.dart';
import '../../../domain/diary/entity/story.dart';
import '../../diary/database/diary_database.dart';
import '../../diary/prefs_diary_preferences.dart';
import 'dir_swap.dart';
import 'drift_rows.dart';

const _dataFile = 'data.json';
const _prefsFile = 'prefs.json';
const _media = 'media';

/// 일기 설정 중 백업에 담는 키. 그 밖의 `walk.diary.*` 는 담지 않는다.
const _prefKeys = [
  PrefsDiaryPreferences.trashRetentionKey,
  PrefsDiaryPreferences.draftStyleKey,
  PrefsDiaryPreferences.draftIncludePhotosKey,
];

/// 일기 영역. `diary/data.json`(여섯 테이블 행) · `diary/media/`(사진 · 동영상 · 썸네일) ·
/// `diary/prefs.json`(일기 설정)을 쓴다. 저장 전 사본인 `diaryRoot/tmp/` 는 담지 않는다.
class DiaryBackupArea implements BackupAreaSource {
  DiaryBackupArea(this._db, this._diaryRoot, this._prefs);

  final DiaryDatabase _db;
  final Directory _diaryRoot;
  final SharedPreferences _prefs;

  /// 지울 때 순서(자식 → 부모). 넣을 때는 거꾸로.
  List<TableInfo<Table, dynamic>> get _deleteOrder => [
    _db.entryTags,
    _db.media,
    _db.entries,
    _db.tags,
    _db.places,
    _db.stories,
  ];

  Directory get _currentMedia => Directory('${_diaryRoot.path}/$_media');

  Directory _areaDir(Directory root) => Directory('${root.path}/${id.name}');

  @override
  BackupAreaId get id => BackupAreaId.diary;

  @override
  Map<String, int> get schema => {'diary': _db.schemaVersion};

  /// 휴지통 기록도 백업에 들어가므로 함께 센다.
  @override
  Future<Map<String, int>> counts() async => {
    'entries': await _count(_db.entries),
    'media': await _count(_db.media),
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

  /// 미디어 파일 크기의 합. DB 행 · 설정은 그에 비해 작아 넣지 않는다.
  @override
  Future<int> estimatedBytes() async {
    final dir = _currentMedia;
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final f in dir.list(recursive: true)) {
      if (f is File) total += await f.length();
    }
    return total;
  }

  @override
  Future<Map<String, int>> export(Directory root) async {
    final out = _areaDir(root);
    await Directory('${out.path}/$_media').create(recursive: true);

    final data = await _db.transaction(
      () async => {
        for (final t in _deleteOrder.reversed)
          t.actualTableName: await dumpTable(_db, t),
      },
    );
    await File('${out.path}/$_dataFile').writeAsString(jsonEncode(data));

    final source = _currentMedia;
    if (await source.exists()) {
      await for (final f in source.list(recursive: true)) {
        if (f is! File) continue;
        final relative = f.path.substring(source.path.length + 1);
        final target = File('${out.path}/$_media/$relative');
        await target.parent.create(recursive: true);
        await f.copy(target.path);
      }
    }

    await File('${out.path}/$_prefsFile').writeAsString(
      jsonEncode({
        for (final key in _prefKeys)
          if (_prefs.get(key) case final Object value) key: value,
      }),
    );

    final entries = data[_db.entries.actualTableName]!.length;
    final media = data[_db.media.actualTableName]!.length;
    return {'entries': entries, 'media': media};
  }

  @override
  Future<void> validate(Directory root) async {
    final data = await _readData(root);
    Set<Object?> ids(TableInfo<Table, dynamic> t, String column) => {
      for (final row in data[t.actualTableName]!) row[column],
    };

    final storyIds = ids(_db.stories, 'id')..add(Story.dailyId);
    final placeIds = ids(_db.places, 'id');
    final tagIds = ids(_db.tags, 'id');
    final entryIds = ids(_db.entries, 'id');

    void check(bool ok) {
      if (!ok) throw const BackupException(BackupFailure.integrity);
    }

    for (final e in data[_db.entries.actualTableName]!) {
      check(storyIds.contains(e['story_id']));
      check(e['place_id'] == null || placeIds.contains(e['place_id']));
    }
    for (final m in data[_db.media.actualTableName]!) {
      check(entryIds.contains(m['entry_id']));
    }
    for (final et in data[_db.entryTags.actualTableName]!) {
      check(entryIds.contains(et['entry_id']));
      check(tagIds.contains(et['tag_id']));
    }
  }

  @override
  Future<void> replace(Directory root) async {
    final data = await _readData(root);
    final prefs = await _readPrefs(root);
    final incomingMedia = Directory('${_areaDir(root).path}/$_media');
    // 미디어가 하나도 없던 백업이면 빈 폴더로 바꿔 넣는다.
    await incomingMedia.create(recursive: true);
    await _diaryRoot.create(recursive: true);

    await swapDirectory(_currentMedia, incomingMedia, () async {
      await _db.transaction(() async {
        for (final t in _deleteOrder) {
          await deleteAllRows(_db, t);
        }
        for (final t in _deleteOrder.reversed) {
          await insertRows(_db, t, data[t.actualTableName]!);
          // 기록을 둘 곳이 없어지지 않게, 백업에 기본 스토리가 없으면 만든다.
          if (t == _db.stories) await _db.ensureDailyStory();
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

  @override
  Future<void> afterRestore() async {}

  /// `data.json` 을 테이블 이름 → 행 목록으로 읽는다. 없거나 모양이 다르면 integrity.
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
    } on BackupException {
      rethrow;
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
