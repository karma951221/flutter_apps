import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/chat/database/chat_database.dart';
import 'package:walk/data/chat/database/drift_chat_usage_log.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';

ChatUsageRecord _rec({
  DateTime? at,
  String key = 'q1',
  ChatVendor vendor = ChatVendor.anthropic,
  String model = 'opus',
  ChatUsagePurpose purpose = ChatUsagePurpose.chat,
  int round = 1,
  bool temporary = false,
  int input = 10,
  int output = 5,
  int cacheRead = 2,
  int? reasoning,
}) => ChatUsageRecord(
  at: at ?? DateTime(2026, 10, 15, 12),
  questionKey: key,
  vendor: vendor,
  model: model,
  fastMode: false,
  purpose: purpose,
  round: round,
  temporary: temporary,
  inputTokens: input,
  outputTokens: output,
  cacheReadTokens: cacheRead,
  cacheWriteTokens: 1,
  reasoningTokens: reasoning,
);

void main() {
  late ChatDatabase db;
  late DriftChatUsageLog log;
  late DriftChatUsageRepository repo;

  setUp(() {
    db = ChatDatabase(NativeDatabase.memory());
    log = DriftChatUsageLog(db);
    repo = DriftChatUsageRepository(db);
  });
  tearDown(() => db.close());

  test('record 는 필드를 빠짐없이 한 행으로 쓴다', () async {
    final a = ChatUsageRecord(
      at: DateTime(2026, 10, 15, 12, 30),
      questionKey: 'k',
      vendor: ChatVendor.openai,
      model: 'gpt',
      fastMode: true,
      purpose: ChatUsagePurpose.wikiDistill,
      round: 3,
      temporary: true,
      inputTokens: 11,
      outputTokens: 22,
      cacheReadTokens: 33,
      cacheWriteTokens: 44,
      reasoningTokens: 55,
      wikiIndexNotes: 6,
      wikiIndexChars: 77,
      readWikiCalls: 8,
    );
    await log.record(a);
    await log.record(_rec(key: 'k2'));
    final rows = await db.select(db.chatUsageRows).get();
    expect(rows, hasLength(2));
    final r = rows.first;
    expect(r.at, a.at);
    expect(r.questionKey, 'k');
    expect(r.vendor, ChatVendor.openai);
    expect(r.model, 'gpt');
    expect(r.fastMode, isTrue);
    expect(r.purpose, ChatUsagePurpose.wikiDistill);
    expect(r.round, 3);
    expect(r.temporary, isTrue);
    expect(r.inputTokens, 11);
    expect(r.outputTokens, 22);
    expect(r.cacheReadTokens, 33);
    expect(r.cacheWriteTokens, 44);
    expect(r.reasoningTokens, 55);
    expect(r.wikiIndexNotes, 6);
    expect(r.wikiIndexChars, 77);
    expect(r.readWikiCalls, 8);
    expect(rows.last.reasoningTokens, isNull);
  });

  test('month 는 그 달만 센다 — 앞뒤 달 경계', () async {
    await log.record(
      _rec(key: 'before', at: DateTime(2026, 9, 30, 23, 59, 59)),
    );
    await log.record(_rec(key: 'first', at: DateTime(2026, 10, 1)));
    await log.record(_rec(key: 'last', at: DateTime(2026, 10, 31, 23, 59, 59)));
    await log.record(_rec(key: 'next', at: DateTime(2026, 11, 1)));
    final m = await repo.month(2026, 10);
    expect(m.year, 2026);
    expect(m.month, 10);
    expect(m.totals.questions, 2);
    expect(m.totals.inputTokens, 20);
    expect(m.totals.outputTokens, 10);
    expect(m.totals.cacheReadTokens, 4);
  });

  test('질문 수는 같은 questionKey 의 라운드를 하나로 센다', () async {
    for (var i = 1; i <= 3; i++) {
      await log.record(_rec(key: 'a', round: i));
    }
    await log.record(_rec(key: 'b'));
    final m = await repo.month(2026, 10);
    expect(m.totals.questions, 2);
    expect(m.totals.inputTokens, 40);
  });

  test('rows 는 벤더 · 모델 · purpose 로 묶는다', () async {
    await log.record(_rec(key: 'a', input: 100));
    await log.record(
      _rec(key: 'b', vendor: ChatVendor.openai, model: 'gpt', input: 300),
    );
    await log.record(
      _rec(key: 'w', purpose: ChatUsagePurpose.wikiDistill, input: 50),
    );
    final m = await repo.month(2026, 10);
    expect(m.rows, hasLength(3));
    expect(m.rows.map((r) => r.inputTokens), [300, 100, 50]);
    expect(m.rows[0].vendor, ChatVendor.openai);
    expect(m.rows[0].model, 'gpt');
    expect(m.rows[2].purpose, ChatUsagePurpose.wikiDistill);
    expect(m.totals.questions, 2);
    expect(m.totals.inputTokens, 450);
  });

  test('임시 대화 행도 합계에 들어간다', () async {
    await log.record(_rec(key: 't', temporary: true, input: 7));
    final m = await repo.month(2026, 10);
    expect(m.totals.inputTokens, 7);
    expect(m.totals.questions, 1);
  });

  test('빈 달은 0 과 빈 rows', () async {
    final m = await repo.month(2026, 3);
    expect(m.totals.questions, 0);
    expect(m.totals.inputTokens, 0);
    expect(m.totals.outputTokens, 0);
    expect(m.totals.cacheReadTokens, 0);
    expect(m.rows, isEmpty);
  });

  test('deleteOlderThan 은 기준 전만 지우고 수를 돌려준다', () async {
    await log.record(_rec(key: 'old1', at: DateTime(2026, 8, 1)));
    await log.record(_rec(key: 'old2', at: DateTime(2026, 9, 1)));
    await log.record(_rec(key: 'edge', at: DateTime(2026, 10, 1)));
    final n = await repo.deleteOlderThan(DateTime(2026, 10, 1));
    expect(n, 2);
    expect(await db.select(db.chatUsageRows).get(), hasLength(1));
  });

  test('deleteAll 은 대화를 지우지 않는다', () async {
    await db
        .into(db.conversations)
        .insert(
          ConversationsCompanion.insert(
            id: 'c1',
            title: 't',
            createdAt: DateTime(2026, 10, 1),
            updatedAt: DateTime(2026, 10, 1),
          ),
        );
    await log.record(_rec());
    await repo.deleteAll();
    expect(await db.select(db.chatUsageRows).get(), isEmpty);
    expect(await db.select(db.conversations).get(), hasLength(1));
  });
}
