import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
import '../../../domain/backup/restore_notice.dart';
import '../../../domain/backup/backup_failure.dart';
import '../../../domain/diary/entity/story.dart';
import '../../diary/database/diary_database.dart';
import '../../diary/prefs_diary_preferences.dart';
import 'area_io.dart';
import 'dir_swap.dart';
import 'drift_rows.dart';
import 'prefs_snapshot.dart';

const _dataFile = 'data.json';
const _prefsFile = 'prefs.json';
const _media = 'media';

/// 일기 설정 중 백업에 담는 키. 그 밖의 `walk.diary.*` 는 담지 않는다.
const _prefKeys = {
  PrefsDiaryPreferences.trashRetentionKey,
  PrefsDiaryPreferences.draftStyleKey,
  PrefsDiaryPreferences.draftIncludePhotosKey,
};

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
    'entries': await countRows(_db, _db.entries),
    'media': await countRows(_db, _db.media),
  };

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
    await createFilesFolder(Directory('${out.path}/$_media'));

    final data = await dumpTables(_db, _deleteOrder.reversed);
    await writeAreaJson(out, _dataFile, data);

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

    await writeAreaJson(out, _prefsFile, await dumpPrefs(_prefs, _prefKeys));

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
      check(m['path'] != null && isContainedRelativePath(m['path']));
      check(isContainedRelativePath(m['thumb_path']));
    }
    for (final et in data[_db.entryTags.actualTableName]!) {
      check(entryIds.contains(et['entry_id']));
      check(tagIds.contains(et['tag_id']));
    }
  }

  @override
  Future<void> replace(Directory root) async {
    final data = await _readData(root);
    final prefs = await readPrefsSnapshot(
      _areaDir(root),
      _prefsFile,
      _prefKeys,
    );
    final incomingMedia = Directory('${_areaDir(root).path}/$_media');
    // 폴더가 없으면 이미 옮겨 간 것이다 — 미디어는 그대로 두고 DB 만 바꾼다.
    await replaceFilesFolder(_currentMedia, incomingMedia, () async {
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

    await restorePrefs(_prefs, _prefKeys, prefs);
  }

  @override
  Future<Set<RestoreNotice>> afterRestore() async => const {};

  Future<TableRows> _readData(Directory root) =>
      readTableRows(_areaDir(root), _dataFile, _deleteOrder);
}
