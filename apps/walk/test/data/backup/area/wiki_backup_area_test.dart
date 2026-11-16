import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart'
    show OrderingTerm, Table, TableInfo, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/backup/area/drift_rows.dart';
import 'package:walk/data/backup/area/wiki_backup_area.dart';
import 'package:walk/data/chat/database/chat_database.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_failure.dart';

import '../../../support/chat_db_seed.dart';

Future<BackupFailure?> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } on BackupException catch (e) {
    return e.failure;
  }
  return null;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory staging;
  late ChatDatabase a;
  late ChatDatabase b;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('wiki_backup_area_test');
    staging = Directory('${tmp.path}/staging')..createSync();
    a = ChatDatabase(NativeDatabase.memory());
    b = ChatDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await a.close();
    await b.close();
    tmp.deleteSync(recursive: true);
  });

  Future<List<WikiNoteRow>> notesOf(ChatDatabase db) =>
      (db.select(db.wikiNotes)..orderBy([(n) => OrderingTerm.asc(n.id)])).get();

  test('wiki round trip keeps integer ids and autoincrement continues after '
      'max id', () async {
    SharedPreferences.setMockInitialValues({
      'walk.chat.wikiIndexSize': 'large',
      'walk.chat.retention': 'days30',
    });
    final prefsA = await SharedPreferences.getInstance();
    await insertConversation(a, 'c1');
    await insertWikiNote(a, 3, source: 'c1', title: '셋');
    await insertWikiNote(a, 12, title: '열둘');
    final areaA = WikiBackupArea(a, prefsA);

    final counts = await areaA.export(staging);
    expect(counts, {'notes': 2});
    expect(await areaA.counts(), counts);

    SharedPreferences.setMockInitialValues({'walk.chat.retention': 'days7'});
    final prefsB = await SharedPreferences.getInstance();
    await insertConversation(b, 'c1');
    // B 의 시퀀스가 백업보다 높아도 복원 뒤에는 백업의 최대 id 다음부터 이어진다.
    for (var i = 0; i < 20; i++) {
      await insertWikiNote(b, null);
    }
    final areaB = WikiBackupArea(b, prefsB);
    await areaB.validate(staging);
    await areaB.replace(staging);

    expect(await dumpTable(b, b.wikiNotes), await dumpTable(a, a.wikiNotes));
    expect((await notesOf(b)).map((n) => n.id), [3, 12]);
    expect(await insertWikiNote(b, null), 13);

    expect(prefsB.get('walk.chat.wikiIndexSize'), 'large');
    // 대화 설정은 위키 영역이 아니다.
    expect(prefsB.get('walk.chat.retention'), 'days7');
  });

  test('wiki restore nulls sourceConversationId whose conversation is '
      'absent', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await insertConversation(a, 'kept');
    await insertConversation(a, 'only-a');
    await insertWikiNote(a, 1, source: 'kept');
    await insertWikiNote(a, 2, source: 'only-a');
    await WikiBackupArea(a, prefs).export(staging);

    await insertConversation(b, 'kept');
    await WikiBackupArea(b, prefs).replace(staging);

    expect((await notesOf(b)).map((n) => n.sourceConversationId), [
      'kept',
      null,
    ]);
  });

  test('wiki replace leaves conversations untouched', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await insertWikiNote(a, 1);
    await WikiBackupArea(a, prefs).export(staging);

    await insertConversation(b, 'c1');
    await insertTurn(b, 'c1', 1);
    await insertUsage(b);
    await insertWikiNote(b, 5, source: 'c1');
    final before = {
      for (final t in <TableInfo<Table, dynamic>>[
        b.conversations,
        b.chatTurns,
        b.chatUsageRows,
      ])
        t.actualTableName: await dumpTable(b, t),
    };

    await WikiBackupArea(b, prefs).replace(staging);

    expect({
      for (final t in <TableInfo<Table, dynamic>>[
        b.conversations,
        b.chatTurns,
        b.chatUsageRows,
      ])
        t.actualTableName: await dumpTable(b, t),
    }, before);
    expect((await notesOf(b)).map((n) => n.id), [1]);
  });

  test('replace into empty wiki then autoincrement starts after max', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await WikiBackupArea(a, prefs).export(staging);
    await insertWikiNote(b, 4);
    await WikiBackupArea(b, prefs).replace(staging);

    expect(await notesOf(b), isEmpty);
    expect(await insertWikiNote(b, null), 1);
  });

  test('replace removes wiki prefs the backup does not have', () async {
    SharedPreferences.setMockInitialValues({});
    final empty = await SharedPreferences.getInstance();
    await WikiBackupArea(a, empty).export(staging);

    SharedPreferences.setMockInitialValues({
      'walk.chat.wikiIndexSize': 'large',
    });
    final prefsB = await SharedPreferences.getInstance();
    await WikiBackupArea(b, prefsB).replace(staging);

    expect(prefsB.containsKey('walk.chat.wikiIndexSize'), isFalse);
  });

  group('validate', () {
    late WikiBackupArea areaB;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await insertWikiNote(a, 1);
      await WikiBackupArea(a, prefs).export(staging);
      areaB = WikiBackupArea(b, prefs);
    });

    test('accepts a fresh export', () async {
      expect(await _failureOf(() => areaB.validate(staging)), isNull);
    });

    test('rejects note without integer id', () async {
      final file = File('${staging.path}/wiki/notes.json');
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      (data['wiki_notes'] as List).first['id'] = 'x';
      file.writeAsStringSync(jsonEncode(data));

      expect(
        await _failureOf(() => areaB.validate(staging)),
        BackupFailure.integrity,
      );
    });

    test('rejects missing or malformed notes.json', () async {
      final file = File('${staging.path}/wiki/notes.json');
      file.writeAsStringSync('[]');
      expect(
        await _failureOf(() => areaB.validate(staging)),
        BackupFailure.integrity,
      );

      file.deleteSync();
      expect(
        await _failureOf(() => areaB.validate(staging)),
        BackupFailure.integrity,
      );
    });
  });

  test('id and schema', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final area = WikiBackupArea(a, prefs);
    expect(area.id, BackupAreaId.wiki);
    expect(area.schema, {'chat': 3});
    expect(await area.estimatedBytes(), greaterThanOrEqualTo(0));
  });
}
