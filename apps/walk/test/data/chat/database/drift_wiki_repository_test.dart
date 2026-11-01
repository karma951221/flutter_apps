import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:walk/data/chat/database/chat_database.dart';
import 'package:walk/data/chat/database/drift_chat_history_repository.dart';
import 'package:walk/data/chat/database/drift_chat_usage_log.dart';
import 'package:walk/data/chat/database/drift_wiki_repository.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';

import '../../../support/diary_fixtures.dart' show MutableClock;

/// c1, c2, … 순번 id.
class _SeqIds extends IdGenerator {
  _SeqIds() : super(const Uuid());

  int _n = 0;

  @override
  String newId() => 'c${++_n}';
}

WikiNoteDraft _draft(
  String title, {
  String summary = '요약',
  String body = '본문',
  String? source,
}) => WikiNoteDraft(
  title: title,
  summary: summary,
  body: body,
  sourceConversationId: source,
);

const _turn = ChatTurnDraft(
  question: 'q',
  answer: 'a',
  citedEntryIds: [],
  vendor: ChatVendor.anthropic,
  model: 'm',
);

void main() {
  final t0 = DateTime(2026, 11, 1, 9);
  late ChatDatabase db;
  late MutableClock clock;
  late DriftWikiRepository repo;
  late DriftChatHistoryRepository history;

  setUp(() {
    db = ChatDatabase(NativeDatabase.memory());
    clock = MutableClock(t0);
    repo = DriftWikiRepository(db, clock);
    history = DriftChatHistoryRepository(db, _SeqIds(), clock);
  });
  tearDown(() => db.close());

  Future<WikiNote> only(int id) async => (await repo.byIds([id])).single;

  test('create 는 1부터 id 를 주고 notes 는 updatedAt 최근 순', () async {
    final a = await repo.create(_draft('가'));
    clock.advance(const Duration(minutes: 1));
    final b = await repo.create(_draft('나'));

    expect(a, 1);
    expect(b, 2);
    final notes = await repo.notes().first;
    expect([for (final n in notes) n.id], [2, 1]);
    expect(notes.last.createdAt, t0);
    expect(notes.last.updatedAt, t0);
    expect(await repo.all(), notes);
    expect(await repo.count(), 2);
  });

  test('같은 updatedAt 이면 id 큰 순', () async {
    await repo.create(_draft('가'));
    await repo.create(_draft('나'));

    expect([for (final n in await repo.all()) n.id], [2, 1]);
  });

  test('update 는 updatedAt 만 바꾸고 순서가 맨 앞으로', () async {
    final a = await repo.create(_draft('가'));
    clock.advance(const Duration(minutes: 1));
    await repo.create(_draft('나'));
    clock.advance(const Duration(minutes: 1));
    final t2 = clock.now();

    await repo.update(a, _draft('가2', body: '새 본문'));

    final notes = await repo.all();
    expect([for (final n in notes) n.id], [1, 2]);
    final note = notes.first;
    expect(note.title, '가2');
    expect(note.body, '새 본문');
    expect(note.createdAt, t0);
    expect(note.updatedAt, t2);
  });

  test('update 의 source 가 null 이면 기존 출처를 둔다', () async {
    final ref = await history.appendTurn(turn: _turn);
    final id = await repo.create(_draft('가', source: ref.conversationId));

    await repo.update(id, _draft('나'));

    expect((await only(id)).sourceConversationId, ref.conversationId);
  });

  test('출처 대화가 그새 지워졌으면 create · update 는 출처 없이 저장한다', () async {
    final gone = (await history.appendTurn(turn: _turn)).conversationId;
    final kept = (await history.appendTurn(turn: _turn)).conversationId;
    final id = await repo.create(_draft('가', source: kept));
    await history.delete(gone);

    final fresh = await repo.create(_draft('나', source: gone));
    await repo.update(id, _draft('다', source: gone));

    expect((await only(fresh)).sourceConversationId, isNull);
    expect((await only(fresh)).title, '나');
    expect((await only(id)).sourceConversationId, isNull);
    expect((await only(id)).title, '다');
  });

  test('없는 id 를 update 하면 StateError', () async {
    expect(() => repo.update(99, _draft('가')), throwsStateError);
  });

  test('요약의 줄바꿈은 공백 하나, 제목 · 요약 · 본문은 상한에서 자른다', () async {
    final id = await repo.create(
      WikiNoteDraft(
        title: '  ${'가' * 70}  ',
        summary: ' 첫 줄\n\n 둘째   줄 ${'나' * 200}',
        body: '  ${'다' * 4100}  ',
      ),
    );

    final note = await only(id);
    expect(note.title, '가' * wikiTitleMax);
    expect(note.summary, startsWith('첫 줄 둘째 줄 나'));
    expect(note.summary.length, wikiSummaryMax);
    expect(note.body, '다' * wikiBodyMax);
  });

  test('자르기는 grapheme 단위', () async {
    const family = '👨‍👩‍👧';
    final id = await repo.create(
      WikiNoteDraft(title: family * 61, summary: '요', body: '본'),
    );

    expect((await only(id)).title, family * wikiTitleMax);
  });

  test('자른 끝의 공백은 지운다', () async {
    final id = await repo.create(
      WikiNoteDraft(
        title: '${'가' * 59} 나',
        summary: '${'요' * 119} 약',
        body: '${'본' * 3999} 문',
      ),
    );

    final note = await only(id);
    expect(note.title, '가' * 59);
    expect(note.summary, '요' * 119);
    expect(note.body, '본' * 3999);
  });

  test('본문은 trim 만 — 안쪽 줄바꿈은 둔다', () async {
    final id = await repo.create(_draft('가', body: '\n 첫 줄\n\n둘째 줄 \n'));

    expect((await only(id)).body, '첫 줄\n\n둘째 줄');
  });

  test('빈 제목 · 요약은 ArgumentError', () async {
    expect(() => repo.create(_draft('  ')), throwsArgumentError);
    expect(
      () => repo.create(_draft('가', summary: ' \n ')),
      throwsArgumentError,
    );
    final id = await repo.create(_draft('가'));
    expect(() => repo.update(id, _draft('')), throwsArgumentError);
    expect(await repo.count(), 1);
  });

  group('대화를 지우면 그 대화를 출처로 둔 메모의 sourceConversationId 만 null', () {
    test('ChatHistoryRepository.delete', () async {
      final c1 = (await history.appendTurn(turn: _turn)).conversationId;
      final c2 = (await history.appendTurn(turn: _turn)).conversationId;
      final a = await repo.create(_draft('가', source: c1));
      final b = await repo.create(_draft('나', source: c2));

      await history.delete(c1);

      expect((await only(a)).sourceConversationId, isNull);
      expect((await only(a)).title, '가');
      expect((await only(b)).sourceConversationId, c2);
    });

    test('ChatHistoryRepository.deleteOlderThan', () async {
      final old = (await history.appendTurn(turn: _turn)).conversationId;
      clock.advance(const Duration(days: 10));
      final fresh = (await history.appendTurn(turn: _turn)).conversationId;
      final a = await repo.create(_draft('가', source: old));
      final b = await repo.create(_draft('나', source: fresh));

      expect(await history.deleteOlderThan(t0.add(const Duration(days: 1))), 1);

      expect((await only(a)).sourceConversationId, isNull);
      expect((await only(b)).sourceConversationId, fresh);
      expect(await repo.count(), 2);
    });
  });

  group('deleteAll', () {
    test('deleteAll 은 메모만 지우고 대화 · chat_usage 는 남긴다', () async {
      final c = (await history.appendTurn(turn: _turn)).conversationId;
      await DriftChatUsageLog(db).record(
        ChatUsageRecord(
          at: t0,
          questionKey: 'k',
          vendor: ChatVendor.anthropic,
          model: 'm',
          fastMode: false,
          purpose: ChatUsagePurpose.chat,
          round: 1,
          temporary: false,
          inputTokens: 1,
          outputTokens: 1,
          cacheReadTokens: 0,
          cacheWriteTokens: 0,
        ),
      );
      await repo.create(_draft('가', source: c));

      await repo.deleteAll();

      expect(await repo.count(), 0);
      expect(await history.count(), 1);
      expect(await db.select(db.chatUsageRows).get(), hasLength(1));
    });

    test('지운 수를 돌려준다', () async {
      await repo.create(_draft('가'));
      await repo.create(_draft('나'));

      expect(await repo.deleteAll(), 2);
      expect(await repo.deleteAll(), 0);
    });
  });

  test('backlinks 는 [[3]] 을 가진 메모만 — [[33]] · [[일기:3]] · 자기 자신은 아니다', () async {
    await repo.create(_draft('1', body: '[[3]] 을 본다'));
    await repo.create(_draft('2', body: '[[33]] 과 [[일기:3]]'));
    await repo.create(_draft('3', body: '자기 [[3]]'));
    clock.advance(const Duration(minutes: 1));
    await repo.create(_draft('4', body: '[[3]][[1]]'));
    await repo.create(_draft('5', body: '[[ 3 ]]'));

    final back = await repo.backlinks(3);

    expect([for (final n in back) n.id], [4, 1]);
  });

  test('byIds 는 있는 것만 순서대로', () async {
    await repo.create(_draft('가'));
    await repo.create(_draft('나'));
    await repo.create(_draft('다'));

    final notes = await repo.byIds([3, 99, 1]);

    expect([for (final n in notes) n.id], [3, 1]);
    expect(await repo.byIds(const []), isEmpty);
  });

  test('watchNote 는 지우면 null', () async {
    final id = await repo.create(_draft('가'));
    final values = <WikiNote?>[];
    final sub = repo.watchNote(id).listen(values.add);
    await pumpEventQueue();

    await repo.delete(id);
    await pumpEventQueue();
    await sub.cancel();

    expect(values.first?.title, '가');
    expect(values.last, isNull);
  });
}
