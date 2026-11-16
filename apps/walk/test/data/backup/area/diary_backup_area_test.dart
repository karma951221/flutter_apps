import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/backup/area/diary_backup_area.dart';
import 'package:walk/data/backup/area/drift_rows.dart';
import 'package:walk/data/diary/database/diary_database.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_failure.dart';
import 'package:walk/domain/diary/entity/entry_location.dart';
import 'package:walk/domain/diary/entity/story.dart';

import '../../../support/diary_fixtures.dart';

const _diaryPrefs = {
  'walk.diary.trashRetention': 'day30',
  'walk.diary.draft.style': 'polite',
  'walk.diary.draft.includePhotos': true,
};

Future<Map<String, List<Map<String, Object?>>>> _dumpAll(
  DiaryDatabase db,
) async => {
  for (final t in db.allTables) t.actualTableName: await dumpTable(db, t),
};

void _writeFile(Directory dir, String relative, List<int> bytes) =>
    File('${dir.path}/$relative')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);

Future<BackupFailure?> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } on BackupException catch (e) {
    return e.failure;
  }
  return null;
}

void main() {
  // 기기 A · B 두 메모리 DB 를 같이 연다(실행기는 서로 다르다).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory rootA; // 기기 A 의 일기 폴더
  late Directory rootB; // 기기 B 의 일기 폴더
  late Directory staging; // 백업 작업 폴더
  late DiaryHarness a;
  late DiaryHarness b;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('diary_backup_area_test');
    rootA = Directory('${tmp.path}/a/diary')..createSync(recursive: true);
    rootB = Directory('${tmp.path}/b/diary')..createSync(recursive: true);
    staging = Directory('${tmp.path}/staging')..createSync();
    a = DiaryHarness();
    b = DiaryHarness(now: DateTime(2026, 11, 16));
  });

  tearDown(() async {
    await a.close();
    await b.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> seedA() async {
    final story = okValue(
      await a.repository.createStory(
        title: '여름 여행',
        startedAt: DateTime(2026, 7, 1),
      ),
    );
    okValue(
      await a.repository.createEntry(
        entryDraft(
          storyId: story.id,
          body: '바다',
          location: const EntryLocation(placeName: '해변', lat: 37.5, lng: 127),
          media: [photoMedia('p1'), videoMedia('v1')],
          tags: ['여행', '바다'],
        ),
      ),
    );
    final trashed = okValue(
      await a.repository.createEntry(
        entryDraft(body: '지울 기록', media: [photoMedia('p2')], tags: ['여행']),
      ),
    );
    await a.trashDirectly(trashed.id);
    _writeFile(rootA, 'media/p1.jpg', [1, 2, 3]);
    _writeFile(rootA, 'media/v1.mp4', List.filled(64, 7));
    _writeFile(rootA, 'media/v1.thumb.jpg', [9, 9]);
    _writeFile(rootA, 'media/p2.jpg', [4, 5]);
  }

  test('round trip: A export → B replace → all six tables row-equal and '
      'media bytes equal', () async {
    SharedPreferences.setMockInitialValues(_diaryPrefs);
    final prefsA = await SharedPreferences.getInstance();
    await seedA();
    final areaA = DiaryBackupArea(a.db, rootA, prefsA);

    final counts = await areaA.export(staging);
    expect(counts, {'entries': 2, 'media': 3});
    expect(await areaA.counts(), counts);

    SharedPreferences.setMockInitialValues({'other.key': 1});
    final prefsB = await SharedPreferences.getInstance();
    _writeFile(rootB, 'media/b-only.jpg', [0]);
    final areaB = DiaryBackupArea(b.db, rootB, prefsB);
    await areaB.validate(staging);
    await areaB.replace(staging);

    final dumpA = await _dumpAll(a.db);
    expect(dumpA['entries'], hasLength(2));
    expect(dumpA['media'], hasLength(3));
    expect(dumpA['entry_tags'], hasLength(3));
    expect(await _dumpAll(b.db), dumpA);

    for (final name in ['p1.jpg', 'v1.mp4', 'v1.thumb.jpg', 'p2.jpg']) {
      expect(
        File('${rootB.path}/media/$name').readAsBytesSync(),
        File('${rootA.path}/media/$name').readAsBytesSync(),
        reason: name,
      );
    }
    expect(File('${rootB.path}/media/b-only.jpg').existsSync(), isFalse);
    expect(Directory('${rootB.path}/media.old').existsSync(), isFalse);

    for (final e in _diaryPrefs.entries) {
      expect(prefsB.get(e.key), e.value, reason: e.key);
    }
    expect(prefsB.get('other.key'), 1);
  });

  test('replace into empty device keeps daily story', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // 기본 스토리 행이 빠진 백업(예: 손으로 고친 파일)
    _writeFile(
      staging,
      'diary/data.json',
      utf8.encode(
        jsonEncode({
          'stories': <Object>[],
          'places': <Object>[],
          'tags': <Object>[],
          'entries': <Object>[],
          'media': <Object>[],
          'entry_tags': <Object>[],
        }),
      ),
    );
    final area = DiaryBackupArea(b.db, rootB, prefs);

    await area.validate(staging);
    // 처음 연 때와 다른 시각이어야 다시 만든 행인지 가려진다.
    b.clock.advance(const Duration(days: 3));
    await area.replace(staging);

    final stories = await b.db.select(b.db.stories).get();
    expect(stories.map((s) => s.id), [Story.dailyId]);
    // 기본 스토리 시각은 DB 시계를 따른다.
    expect(stories.single.startedAt, b.clock.now());
    expect(stories.single.createdAt, b.clock.now());
    expect(Directory('${rootB.path}/media').existsSync(), isTrue);
  });

  test('replace removes diary prefs the backup does not have', () async {
    SharedPreferences.setMockInitialValues({});
    final empty = await SharedPreferences.getInstance();
    await DiaryBackupArea(a.db, rootA, empty).export(staging);

    SharedPreferences.setMockInitialValues(_diaryPrefs);
    final prefsB = await SharedPreferences.getInstance();
    await DiaryBackupArea(b.db, rootB, prefsB).replace(staging);

    for (final key in _diaryPrefs.keys) {
      expect(prefsB.containsKey(key), isFalse, reason: key);
    }
  });

  group('validate', () {
    late DiaryBackupArea areaB;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await seedA();
      await DiaryBackupArea(a.db, rootA, prefs).export(staging);
      areaB = DiaryBackupArea(b.db, rootB, prefs);
    });

    Map<String, dynamic> readData() =>
        jsonDecode(File('${staging.path}/diary/data.json').readAsStringSync())
            as Map<String, dynamic>;

    void writeData(Map<String, dynamic> data) => File(
      '${staging.path}/diary/data.json',
    ).writeAsStringSync(jsonEncode(data));

    test('accepts a fresh export', () async {
      expect(await _failureOf(() => areaB.validate(staging)), isNull);
    });

    test('rejects entry pointing to missing story', () async {
      final data = readData();
      (data['entries'] as List).first['story_id'] = 'nope';
      writeData(data);

      expect(
        await _failureOf(() => areaB.validate(staging)),
        BackupFailure.integrity,
      );
    });

    test('rejects media pointing to missing entry', () async {
      final data = readData();
      (data['media'] as List).first['entry_id'] = 'nope';
      writeData(data);

      expect(
        await _failureOf(() => areaB.validate(staging)),
        BackupFailure.integrity,
      );
    });

    test('rejects entry tag pointing to missing tag', () async {
      final data = readData();
      (data['entry_tags'] as List).first['tag_id'] = 'nope';
      writeData(data);

      expect(
        await _failureOf(() => areaB.validate(staging)),
        BackupFailure.integrity,
      );
    });

    test('rejects missing or malformed data.json', () async {
      File('${staging.path}/diary/data.json').writeAsStringSync('{oops');
      expect(
        await _failureOf(() => areaB.validate(staging)),
        BackupFailure.integrity,
      );

      File('${staging.path}/diary/data.json').deleteSync();
      expect(
        await _failureOf(() => areaB.validate(staging)),
        BackupFailure.integrity,
      );
    });
  });

  test('export skips diary/tmp/', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    _writeFile(rootA, 'tmp/draft.jpg', [1]);
    _writeFile(rootA, 'media/p1.jpg', [2]);

    await DiaryBackupArea(a.db, rootA, prefs).export(staging);

    expect(File('${staging.path}/diary/media/p1.jpg').existsSync(), isTrue);
    expect(Directory('${staging.path}/diary/tmp').existsSync(), isFalse);
    expect(File('${staging.path}/diary/data.json').existsSync(), isTrue);
    expect(File('${staging.path}/diary/prefs.json').existsSync(), isTrue);
  });

  test('id, schema and estimatedBytes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final area = DiaryBackupArea(a.db, rootA, prefs);
    expect(await area.estimatedBytes(), 0);

    _writeFile(rootA, 'media/p1.jpg', List.filled(100, 1));
    _writeFile(rootA, 'tmp/x.jpg', List.filled(1000, 1));

    expect(area.id, BackupAreaId.diary);
    expect(area.schema, {'diary': 1});
    expect(await area.estimatedBytes(), greaterThanOrEqualTo(100));
    expect(await area.estimatedBytes(), lessThan(1000));
  });
}
