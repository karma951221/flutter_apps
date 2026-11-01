import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:walk/data/chat/database/chat_database.dart';
import 'package:walk/data/chat/database/drift_chat_history_repository.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';

import '../../../support/diary_fixtures.dart' show MutableClock;

/// c1, c2, … 순번 id.
class _SeqIds extends IdGenerator {
  _SeqIds() : super(const Uuid());

  int _n = 0;

  @override
  String newId() => 'c${++_n}';
}

ChatTurnDraft _draft(
  String question, {
  String answer = 'a',
  List<String> cited = const [],
  bool stopped = false,
  ChatVendor vendor = ChatVendor.anthropic,
  String model = 'claude-test',
}) => ChatTurnDraft(
  question: question,
  answer: answer,
  citedEntryIds: cited,
  stopped: stopped,
  vendor: vendor,
  model: model,
);

void main() {
  final t0 = DateTime(2026, 11, 1, 9);
  late ChatDatabase db;
  late MutableClock clock;
  late DriftChatHistoryRepository repo;

  setUp(() {
    db = ChatDatabase(NativeDatabase.memory());
    clock = MutableClock(t0);
    repo = DriftChatHistoryRepository(db, _SeqIds(), clock);
  });
  tearDown(() => db.close());

  Future<Conversation> only(String id) async =>
      (await repo.conversations().first).singleWhere((c) => c.id == id);

  test('첫 appendTurn 은 대화를 만들고 id 를 돌려준다 — 제목은 첫 질문에서', () async {
    final ref = await repo.appendTurn(turn: _draft('오늘\n뭐 했지?'));

    expect(ref.conversationId, 'c1');
    expect(ref.seq, 1);
    final c = await only('c1');
    expect(c.title, '오늘 뭐 했지?');
    expect(c.titleEdited, isFalse);
    expect(c.createdAt, t0);
    expect(c.updatedAt, t0);
    expect(c.turnCount, 1);
    expect(await repo.count(), 1);
  });

  test('같은 id 로 다시 쓰면 seq 가 1 · 2 로 늘고 updatedAt 이 바뀐다', () async {
    final first = await repo.appendTurn(turn: _draft('q1'));
    clock.advance(const Duration(minutes: 5));
    final second = await repo.appendTurn(
      conversationId: first.conversationId,
      turn: _draft('q2'),
    );

    expect(first.seq, 1);
    expect(second, (conversationId: 'c1', seq: 2));
    final c = await only('c1');
    expect(c.createdAt, t0);
    expect(c.updatedAt, t0.add(const Duration(minutes: 5)));
    expect(c.title, 'q1');
    expect(c.turnCount, 2);
  });

  test('없는 id 로 appendTurn 하면 StateError 이고 아무것도 생기지 않는다', () async {
    await expectLater(
      repo.appendTurn(conversationId: 'nope', turn: _draft('q')),
      throwsStateError,
    );
    expect(await repo.count(), 0);
    expect(await db.select(db.chatTurns).get(), isEmpty);
  });

  test(
    'turns 는 seq 순 — 질문 · 답 · 인용 id · stopped · vendor · model · askedAt 이 그대로 돌아온다',
    () async {
      final ref = await repo.appendTurn(
        turn: _draft('q1', answer: 'a1', cited: ['e1', 'e2']),
      );
      clock.advance(const Duration(minutes: 1));
      await repo.appendTurn(
        conversationId: ref.conversationId,
        turn: _draft(
          'q2',
          answer: '중간까지',
          stopped: true,
          vendor: ChatVendor.openai,
          model: 'gpt-test',
        ),
      );

      final turns = await repo.turns('c1');
      expect(turns, [
        ChatTurnRecord(
          conversationId: 'c1',
          seq: 1,
          question: 'q1',
          answer: 'a1',
          citedEntryIds: const ['e1', 'e2'],
          stopped: false,
          vendor: ChatVendor.anthropic,
          model: 'claude-test',
          askedAt: t0,
        ),
        ChatTurnRecord(
          conversationId: 'c1',
          seq: 2,
          question: 'q2',
          answer: '중간까지',
          citedEntryIds: const [],
          stopped: true,
          vendor: ChatVendor.openai,
          model: 'gpt-test',
          askedAt: t0.add(const Duration(minutes: 1)),
        ),
      ]);
      expect(await repo.turns('nope'), isEmpty);
    },
  );

  test('conversations 는 updatedAt 최근 순이고 turnCount 를 준다', () async {
    final a = await repo.appendTurn(turn: _draft('a'));
    clock.advance(const Duration(minutes: 1));
    await repo.appendTurn(turn: _draft('b'));
    clock.advance(const Duration(minutes: 1));
    await repo.appendTurn(conversationId: a.conversationId, turn: _draft('a2'));

    final list = await repo.conversations().first;
    expect([for (final c in list) c.id], ['c1', 'c2']);
    expect([for (final c in list) c.turnCount], [2, 1]);
  });

  test('쓰면 스트림이 다시 낸다', () async {
    final emitted = <List<String>>[];
    final sub = repo.conversations().listen(
      (list) => emitted.add([for (final c in list) c.id]),
    );
    await pumpEventQueue();
    await repo.appendTurn(turn: _draft('q'));
    await pumpEventQueue();
    await sub.cancel();

    expect(emitted.first, isEmpty);
    expect(emitted.last, ['c1']);
  });

  test('rename 은 titleEdited 를 켜고 updatedAt 은 그대로', () async {
    await repo.appendTurn(turn: _draft('q'));
    clock.advance(const Duration(hours: 1));

    await repo.rename('c1', '  새 이름 ');

    final c = await only('c1');
    expect(c.title, '새 이름');
    expect(c.titleEdited, isTrue);
    expect(c.updatedAt, t0);
  });

  test('빈 이름은 무시', () async {
    await repo.appendTurn(turn: _draft('q'));

    await repo.rename('c1', '   ');

    final c = await only('c1');
    expect(c.title, 'q');
    expect(c.titleEdited, isFalse);
  });

  group('deleteTurn', () {
    test('첫 턴을 지우면 자동 제목이 새 첫 질문으로', () async {
      await repo.appendTurn(turn: _draft('첫 질문'));
      clock.advance(const Duration(minutes: 1));
      await repo.appendTurn(conversationId: 'c1', turn: _draft('둘째 질문'));
      final before = await only('c1');

      await repo.deleteTurn('c1', 1);

      final c = await only('c1');
      expect(c.title, '둘째 질문');
      expect(c.turnCount, 1);
      expect(c.updatedAt, before.updatedAt);
      expect([for (final t in await repo.turns('c1')) t.seq], [2]);
    });

    test('titleEdited 면 제목 그대로', () async {
      await repo.appendTurn(turn: _draft('첫 질문'));
      await repo.appendTurn(conversationId: 'c1', turn: _draft('둘째 질문'));
      await repo.rename('c1', '내 이름');

      await repo.deleteTurn('c1', 1);

      expect((await only('c1')).title, '내 이름');
    });

    test('마지막 턴을 지우면 대화도 사라진다', () async {
      await repo.appendTurn(turn: _draft('q'));

      await repo.deleteTurn('c1', 1);

      expect(await repo.count(), 0);
      expect(await repo.conversations().first, isEmpty);
    });
  });

  Future<void> insertUsage() => db
      .into(db.chatUsageRows)
      .insert(
        ChatUsageRowsCompanion.insert(
          at: t0,
          questionKey: 'k',
          vendor: ChatVendor.anthropic,
          model: 'm',
          purpose: ChatUsagePurpose.chat,
          round: 1,
          temporary: false,
          inputTokens: 1,
          outputTokens: 1,
          cacheReadTokens: 0,
          cacheWriteTokens: 0,
        ),
      );

  test('delete · deleteAll 은 턴까지 지우고 chat_usage 는 남긴다', () async {
    await insertUsage();
    await repo.appendTurn(turn: _draft('a'));
    await repo.appendTurn(turn: _draft('b'));
    await repo.appendTurn(conversationId: 'c2', turn: _draft('b2'));

    await repo.delete('c1');
    expect(await repo.count(), 1);
    expect(await repo.turns('c1'), isEmpty);

    await repo.deleteAll();
    expect(await repo.count(), 0);
    expect(await db.select(db.chatTurns).get(), isEmpty);
    expect(await db.select(db.chatUsageRows).get(), hasLength(1));
  });

  test('deleteAll 은 지운 수를 돌려준다', () async {
    await repo.appendTurn(turn: _draft('a'));
    await repo.appendTurn(turn: _draft('b'));
    await repo.appendTurn(turn: _draft('c'));

    expect(await repo.deleteAll(), 3);
    expect(await repo.deleteAll(), 0);
  });

  test('deleteOlderThan 은 기준보다 오래된 것만 지우고 except 는 남긴다', () async {
    await repo.appendTurn(turn: _draft('old1')); // c1 @ t0
    await repo.appendTurn(turn: _draft('old2')); // c2 @ t0
    clock.advance(const Duration(days: 10));
    await repo.appendTurn(turn: _draft('new')); // c3 @ t0+10d

    final removed = await repo.deleteOlderThan(
      t0.add(const Duration(days: 1)),
      except: 'c2',
    );

    expect(removed, 1);
    final ids = {for (final c in await repo.conversations().first) c.id};
    expect(ids, {'c2', 'c3'});
    expect(await repo.turns('c1'), isEmpty);
  });

  test('watchExists 는 true 를 내고 지우면 false 를 낸다', () async {
    await repo.appendTurn(turn: _draft('q'));
    final emitted = <bool>[];
    final sub = repo.watchExists('c1').listen(emitted.add);
    await pumpEventQueue();

    // 다른 쓰기로는 같은 값을 다시 내지 않는다.
    await repo.appendTurn(conversationId: 'c1', turn: _draft('q2'));
    await pumpEventQueue();
    await repo.delete('c1');
    await pumpEventQueue();
    await sub.cancel();

    expect(emitted, [true, false]);
  });
}
