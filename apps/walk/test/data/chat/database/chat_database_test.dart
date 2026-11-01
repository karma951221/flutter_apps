import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/chat/database/chat_database.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

void main() {
  final at = DateTime(2026, 11, 1, 9);
  late ChatDatabase db;

  setUp(() => db = ChatDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('foreign_keys 가 켜져 있다', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 1);
  });

  test('대화를 지우면 턴이 cascade 로 지워진다', () async {
    await db
        .into(db.conversations)
        .insert(
          ConversationsCompanion.insert(
            id: 'c1',
            title: 't',
            createdAt: at,
            updatedAt: at,
          ),
        );
    for (final seq in [1, 2]) {
      await db
          .into(db.chatTurns)
          .insert(
            ChatTurnsCompanion.insert(
              conversationId: 'c1',
              seq: seq,
              question: 'q',
              answer: 'a',
              citedEntryIds: const [],
              vendor: ChatVendor.anthropic,
              model: 'm',
              askedAt: at,
            ),
          );
    }
    expect(await db.select(db.chatTurns).get(), hasLength(2));

    await db.delete(db.conversations).go();

    expect(await db.select(db.chatTurns).get(), isEmpty);
  });

  test('chat_usage 테이블 이름은 chat_usage 다', () {
    expect(db.chatUsageRows.actualTableName, 'chat_usage');
  });

  test('schemaVersion 은 1', () {
    expect(db.schemaVersion, 1);
  });
}
