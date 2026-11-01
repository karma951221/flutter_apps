import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/chat/database/chat_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

/// drift_dev 의 SchemaVerifier(api/migrations_native.dart)는 저장소의 drift 2.34.4 와
/// 컴파일되지 않는다(chat_database.dart 의 schemaVersion 주석). 그래서 같은 생성 도우미
/// (generated/, drift_schemas/chat/ 에서 만듦)로 v1 DB 를 파일에 만들고, ChatDatabase 로
/// 열어 올린 뒤 sqlite_master 를 도우미의 v2 DB 와 비교한다.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final helper = GeneratedHelper();
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('chat_migration');
    file = File('${dir.path}/chat.sqlite');
  });
  tearDown(() => dir.delete(recursive: true));

  /// 테이블마다 열(이름 · 타입 · NOT NULL · 기본값 · PK) · 외래 키 · 인덱스(열 · unique).
  /// CREATE 문 글자는 도우미와 띄어쓰기가 달라 SchemaVerifier 처럼 PRAGMA 로 비교한다.
  Future<Map<String, Object>> schemaOf(GeneratedDatabase db) async {
    Future<List<Map<String, Object?>>> rows(String sql) async => [
      for (final r in await db.customSelect(sql).get()) r.data,
    ];

    final tables = await rows(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    return {
      for (final t in tables)
        t['name']! as String: {
          'columns': [
            for (final c in await rows("PRAGMA table_info('${t['name']}')"))
              [c['name'], c['type'], c['notnull'], c['dflt_value'], c['pk']],
          ],
          'foreignKeys': [
            for (final f in await rows(
              "PRAGMA foreign_key_list('${t['name']}')",
            ))
              [f['table'], f['from'], f['to'], f['on_update'], f['on_delete']],
          ],
          'indexes': {
            for (final i in await rows("PRAGMA index_list('${t['name']}')"))
              if (!(i['name']! as String).startsWith('sqlite_'))
                i['name']: [
                  i['unique'],
                  for (final c in await rows(
                    "PRAGMA index_info('${i['name']}')",
                  ))
                    c['name'],
                ],
          },
        },
    };
  }

  Future<Map<String, Object>> expectedV2() async {
    final db = helper.databaseForVersion(NativeDatabase.memory(), 2);
    try {
      return await schemaOf(db);
    } finally {
      await db.close();
    }
  }

  Future<void> createV1(Future<void> Function(v1.DatabaseAtV1 db)? fill) async {
    final db =
        helper.databaseForVersion(NativeDatabase(file), 1) as v1.DatabaseAtV1;
    await db.customSelect('SELECT 1').get(); // onCreate 를 돌린다.
    await fill?.call(db);
    await db.close();
  }

  test('v1 → v2 가 스키마 v2 와 같다', () async {
    await createV1(null);

    final db = ChatDatabase(NativeDatabase(file));
    final migrated = await schemaOf(db);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    await db.close();

    final expected = await expectedV2();
    expect(expected.keys, contains('wiki_notes'));
    expect((expected['wiki_notes']! as Map)['indexes'], {
      'wiki_notes_updated_at': [0, 'updated_at'],
    });
    expect(migrated, expected);
    expect(version.data.values.single, 2);
  });

  test('새로 만든 v2 도 스키마 v2 와 같다', () async {
    final db = ChatDatabase(NativeDatabase.memory());
    final created = await schemaOf(db);
    await db.close();

    expect(created, await expectedV2());
  });

  test('v1 의 대화 · 턴 · 사용량 행이 v2 에 그대로 남는다', () async {
    final askedAt = DateTime(2026, 11, 1, 9);
    // v1 이 저장하던 모양(로컬 시각 + 오프셋 글).
    final mapper = ChatDatabase(NativeDatabase.memory());
    final at = mapper.typeMapping.mapToSqlVariable(askedAt)! as String;
    await mapper.close();
    expect(at, isNot(endsWith('Z')));
    await createV1((db) async {
      await db
          .into(db.conversations)
          .insert(
            v1.ConversationsCompanion.insert(
              id: 'c1',
              title: '제목',
              createdAt: at,
              updatedAt: at,
            ),
          );
      await db
          .into(db.chatTurns)
          .insert(
            v1.ChatTurnsCompanion.insert(
              conversationId: 'c1',
              seq: 1,
              question: 'q',
              answer: 'a',
              citedEntryIds: '["e1"]',
              vendor: 'anthropic',
              model: 'm',
              askedAt: at,
            ),
          );
      await db
          .into(db.chatUsage)
          .insert(
            v1.ChatUsageCompanion.insert(
              at: at,
              questionKey: 'k',
              vendor: 'anthropic',
              model: 'm',
              purpose: 'chat',
              round: 1,
              temporary: 0,
              inputTokens: 10,
              outputTokens: 5,
              cacheReadTokens: 2,
              cacheWriteTokens: 1,
            ),
          );
    });

    final db = ChatDatabase(NativeDatabase(file));
    final conversations = await db.select(db.conversations).get();
    final turns = await db.select(db.chatTurns).get();
    final usage = await db.select(db.chatUsageRows).get();
    final notes = await db.select(db.wikiNotes).get();
    await db.close();

    expect(conversations.single.id, 'c1');
    expect(conversations.single.title, '제목');
    expect(conversations.single.createdAt, askedAt);
    expect(turns.single.askedAt, askedAt);
    expect(turns.single.citedEntryIds, ['e1']);
    expect(turns.single.question, 'q');
    expect(usage.single.inputTokens, 10);
    expect(usage.single.questionKey, 'k');
    expect(notes, isEmpty);
  });
}
