import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/backup/area/chat_backup_area.dart';
import 'package:walk/data/backup/area/drift_rows.dart';
import 'package:walk/data/chat/database/chat_database.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_failure.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

import '../../../support/chat_db_seed.dart';

const _chatPrefs = {
  'walk.chat.retention': 'days30',
  'walk.chat.useRecords': false,
};

/// 백업에 담지 않는 키. 복원 뒤에도 기기 B 의 값 그대로여야 한다.
const _excludedPrefs = {
  'chat.keyStatus': 'valid',
  'chat.consentedVendor': 'anthropic',
  'chat.consented': true,
  'chat.consentScope': 'records',
  'walk.chat.wikiIndexSize': 'large',
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
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory wsA; // 기기 A 의 작업 폴더
  late Directory wsB;
  late Directory staging;
  late ChatDatabase a;
  late ChatDatabase b;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('chat_backup_area_test');
    wsA = Directory('${tmp.path}/a/workspace')..createSync(recursive: true);
    wsB = Directory('${tmp.path}/b/workspace')..createSync(recursive: true);
    staging = Directory('${tmp.path}/staging')..createSync();
    a = ChatDatabase(NativeDatabase.memory());
    b = ChatDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await a.close();
    await b.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> seedA() async {
    await insertConversation(a, 'c1');
    await insertConversation(a, 'c2');
    await insertTurn(
      a,
      'c1',
      1,
      attachments: jsonEncode([
        {'name': 'photo.jpg', 'kind': 'image', 'path': 'inbox/photo.jpg'},
      ]),
    );
    await insertTurn(a, 'c1', 2);
    await insertTurn(a, 'c2', 1);
    await insertUsage(a);
    await insertUsage(a, purpose: ChatUsagePurpose.wikiDistill);
    _writeFile(wsA, 'inbox/photo.jpg', [1, 2, 3]);
    _writeFile(wsA, 'out/report.md', utf8.encode('# 보고'));
  }

  test('chat round trip incl. attachments json and workspace files', () async {
    SharedPreferences.setMockInitialValues({
      ..._chatPrefs,
      'chat.keyStatus': 'invalid',
      'walk.chat.wikiIndexSize': 'small',
    });
    final prefsA = await SharedPreferences.getInstance();
    await seedA();
    final areaA = ChatBackupArea(a, wsA, prefsA);

    final counts = await areaA.export(staging);
    expect(counts, {'conversations': 2, 'files': 2});
    expect(await areaA.counts(), counts);

    SharedPreferences.setMockInitialValues(_excludedPrefs);
    final prefsB = await SharedPreferences.getInstance();
    await insertConversation(b, 'b-only');
    await insertTurn(b, 'b-only', 1);
    await insertUsage(b);
    _writeFile(wsB, 'inbox/b-only.txt', [0]);
    final areaB = ChatBackupArea(b, wsB, prefsB);
    await areaB.validate(staging);
    await areaB.replace(staging);

    for (final t in <TableInfo<Table, dynamic>>[
      a.conversations,
      a.chatTurns,
      a.chatUsageRows,
    ]) {
      expect(
        await dumpTable(b, t),
        await dumpTable(a, t),
        reason: t.actualTableName,
      );
    }
    final turn =
        await (b.select(b.chatTurns)
              ..where((t) => t.conversationId.equals('c1') & t.seq.equals(1)))
            .getSingle();
    expect(jsonDecode(turn.attachments), [
      {'name': 'photo.jpg', 'kind': 'image', 'path': 'inbox/photo.jpg'},
    ]);

    expect(File('${wsB.path}/inbox/photo.jpg').readAsBytesSync(), [1, 2, 3]);
    expect(File('${wsB.path}/out/report.md').readAsStringSync(), '# 보고');
    expect(File('${wsB.path}/inbox/b-only.txt').existsSync(), isFalse);
    expect(Directory('${wsB.path}.old').existsSync(), isFalse);

    for (final e in _chatPrefs.entries) {
      expect(prefsB.get(e.key), e.value, reason: e.key);
    }
    for (final e in _excludedPrefs.entries) {
      expect(prefsB.get(e.key), e.value, reason: e.key);
    }
  });

  test('export writes only the chat prefs keys', () async {
    SharedPreferences.setMockInitialValues({
      ..._chatPrefs,
      ..._excludedPrefs,
      'chat.models': '[]',
    });
    final prefs = await SharedPreferences.getInstance();
    await ChatBackupArea(a, wsA, prefs).export(staging);

    final written =
        jsonDecode(File('${staging.path}/chat/prefs.json').readAsStringSync())
            as Map<String, Object?>;
    expect(written, _chatPrefs);
  });

  test('replace removes chat prefs the backup does not have', () async {
    SharedPreferences.setMockInitialValues({});
    final empty = await SharedPreferences.getInstance();
    await ChatBackupArea(a, wsA, empty).export(staging);

    SharedPreferences.setMockInitialValues(_chatPrefs);
    final prefsB = await SharedPreferences.getInstance();
    await ChatBackupArea(b, wsB, prefsB).replace(staging);

    for (final key in _chatPrefs.keys) {
      expect(prefsB.containsKey(key), isFalse, reason: key);
    }
  });

  test('chat replace leaves wiki_notes untouched', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await seedA();
    await ChatBackupArea(a, wsA, prefs).export(staging);

    // B 에도 c1 이 있고 위키가 그것을 출처로 가리킨다. 백업에도 c1 이 있으니 출처가 남는다.
    await insertConversation(b, 'c1', title: 'B 의 c1');
    await insertWikiNote(b, 7, source: 'c1');
    await insertWikiNote(b, 9);
    final before = await dumpTable(b, b.wikiNotes);

    await ChatBackupArea(b, wsB, prefs).replace(staging);

    expect(await dumpTable(b, b.wikiNotes), before);
  });

  test('chat replace nulls wiki sourceConversationId pointing to removed '
      'conversations', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await seedA();
    await ChatBackupArea(a, wsA, prefs).export(staging);

    await insertConversation(b, 'gone');
    await insertWikiNote(b, 1, source: 'gone');
    await insertWikiNote(b, 2, source: null);

    await ChatBackupArea(b, wsB, prefs).replace(staging);

    final notes = await (b.select(
      b.wikiNotes,
    )..orderBy([(n) => OrderingTerm.asc(n.id)])).get();
    expect(notes.map((n) => n.id), [1, 2]);
    expect(notes.map((n) => n.sourceConversationId), [null, null]);
  });

  test(
    'replace rolls back rows and workspace when the DB step fails',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await seedA();
      await ChatBackupArea(a, wsA, prefs).export(staging);
      // 같은 (대화, 순번) 턴 두 개 — 넣을 때 기본키 충돌로 트랜잭션이 실패한다.
      final file = File('${staging.path}/chat/conversations.json');
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final turns = data['chat_turns'] as List;
      turns.add(turns.first);
      file.writeAsStringSync(jsonEncode(data));

      await insertConversation(b, 'b-only');
      _writeFile(wsB, 'inbox/b-only.txt', [0]);

      await expectLater(
        ChatBackupArea(b, wsB, prefs).replace(staging),
        throwsA(anything),
      );

      final conversations = await b.select(b.conversations).get();
      expect(conversations.map((c) => c.id), ['b-only']);
      expect(File('${wsB.path}/inbox/b-only.txt').existsSync(), isTrue);
      expect(File('${wsB.path}/inbox/photo.jpg').existsSync(), isFalse);
    },
  );

  group('validate', () {
    late ChatBackupArea areaB;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await seedA();
      await ChatBackupArea(a, wsA, prefs).export(staging);
      areaB = ChatBackupArea(b, wsB, prefs);
    });

    test('accepts a fresh export', () async {
      expect(await _failureOf(() => areaB.validate(staging)), isNull);
    });

    test('rejects turn pointing to missing conversation', () async {
      final file = File('${staging.path}/chat/conversations.json');
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      (data['chat_turns'] as List).first['conversation_id'] = 'nope';
      file.writeAsStringSync(jsonEncode(data));

      expect(
        await _failureOf(() => areaB.validate(staging)),
        BackupFailure.integrity,
      );
    });

    test('rejects missing or malformed conversations.json', () async {
      final file = File('${staging.path}/chat/conversations.json');
      file.writeAsStringSync('{oops');
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

  test('export skips links in the workspace', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final outside = File('${tmp.path}/secret.txt')..writeAsStringSync('x');
    _writeFile(wsA, 'inbox/a.txt', [1]);
    Link('${wsA.path}/inbox/link.txt').createSync(outside.path);

    final counts = await ChatBackupArea(a, wsA, prefs).export(staging);

    expect(counts['files'], 1);
    expect(
      File('${staging.path}/chat/workspace/inbox/a.txt').existsSync(),
      isTrue,
    );
    expect(
      FileSystemEntity.typeSync(
        '${staging.path}/chat/workspace/inbox/link.txt',
      ),
      FileSystemEntityType.notFound,
    );
  });

  test('id, schema and estimatedBytes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final area = ChatBackupArea(a, Directory('${tmp.path}/none'), prefs);
    expect(area.id, BackupAreaId.chat);
    expect(area.schema, {'chat': 3});
    expect(await area.estimatedBytes(), 0);

    _writeFile(wsA, 'inbox/x.bin', List.filled(100, 1));
    expect(
      await ChatBackupArea(a, wsA, prefs).estimatedBytes(),
      greaterThanOrEqualTo(100),
    );
  });

  test('vendor enum survives as stored text', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await insertConversation(a, 'c1');
    await insertTurn(a, 'c1', 1, vendor: ChatVendor.openai);
    await ChatBackupArea(a, wsA, prefs).export(staging);
    await ChatBackupArea(b, wsB, prefs).replace(staging);

    final turn = await b.select(b.chatTurns).getSingle();
    expect(turn.vendor, ChatVendor.openai);
  });
}
