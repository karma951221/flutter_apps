import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/chat/entity/conversation.dart';
import '../../../domain/chat/repository/chat_history_repository.dart';
import 'chat_database.dart';

@LazySingleton(as: ChatHistoryRepository)
class DriftChatHistoryRepository implements ChatHistoryRepository {
  DriftChatHistoryRepository(this._db, this._ids, this._clock);

  final ChatDatabase _db;
  final IdGenerator _ids;
  final Clock _clock;

  @override
  Stream<List<Conversation>> conversations() {
    final c = _db.conversations;
    final t = _db.chatTurns;
    final turnCount = t.seq.count();
    final query =
        _db.select(c).join([
            leftOuterJoin(
              t,
              t.conversationId.equalsExp(c.id),
              useColumns: false,
            ),
          ])
          ..addColumns([turnCount])
          ..groupBy([c.id])
          ..orderBy([
            OrderingTerm.desc(c.updatedAt),
            OrderingTerm.desc(c.createdAt),
          ]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          _conversationFrom(r.readTable(c), r.read(turnCount) ?? 0),
      ],
    );
  }

  @override
  Stream<bool> watchExists(String id) =>
      (_db.select(_db.conversations)..where((c) => c.id.equals(id)))
          .watch()
          .map((rows) => rows.isNotEmpty)
          .distinct();

  @override
  Future<int> count() async {
    final n = _db.conversations.id.count();
    final row = await (_db.selectOnly(
      _db.conversations,
    )..addColumns([n])).getSingle();
    return row.read(n) ?? 0;
  }

  @override
  Future<List<ChatTurnRecord>> turns(String conversationId) async {
    final rows =
        await (_db.select(_db.chatTurns)
              ..where((t) => t.conversationId.equals(conversationId))
              ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
            .get();
    return [for (final r in rows) _turnFrom(r)];
  }

  @override
  Future<ChatTurnRef> appendTurn({
    String? conversationId,
    required ChatTurnDraft turn,
  }) => _db.transaction(() async {
    final now = _clock.now();
    final String id;
    final int seq;
    if (conversationId == null) {
      id = _ids.newId();
      seq = 1;
      await _db
          .into(_db.conversations)
          .insert(
            ConversationsCompanion.insert(
              id: id,
              title: conversationTitleFrom(turn.question),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      id = conversationId;
      final updated =
          await (_db.update(_db.conversations)..where((c) => c.id.equals(id)))
              .write(ConversationsCompanion(updatedAt: Value(now)));
      if (updated == 0) {
        throw StateError('대화 $id 가 없다');
      }
      final maxSeq = _db.chatTurns.seq.max();
      final row =
          await (_db.selectOnly(_db.chatTurns)
                ..addColumns([maxSeq])
                ..where(_db.chatTurns.conversationId.equals(id)))
              .getSingle();
      seq = (row.read(maxSeq) ?? 0) + 1;
    }
    await _db
        .into(_db.chatTurns)
        .insert(
          ChatTurnsCompanion.insert(
            conversationId: id,
            seq: seq,
            question: turn.question,
            answer: turn.answer,
            citedEntryIds: turn.citedEntryIds,
            stopped: Value(turn.stopped),
            vendor: turn.vendor,
            model: turn.model,
            askedAt: now,
          ),
        );
    return (conversationId: id, seq: seq);
  });

  @override
  Future<void> rename(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    await (_db.update(_db.conversations)..where((c) => c.id.equals(id))).write(
      ConversationsCompanion(
        title: Value(trimmed),
        titleEdited: const Value(true),
      ),
    );
  }

  @override
  Future<void> deleteTurn(String id, int seq) => _db.transaction(() async {
    final conversation = await (_db.select(
      _db.conversations,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (conversation == null) return;
    final deleted = await (_db.delete(
      _db.chatTurns,
    )..where((t) => t.conversationId.equals(id) & t.seq.equals(seq))).go();
    if (deleted == 0) return;
    final first =
        await (_db.select(_db.chatTurns)
              ..where((t) => t.conversationId.equals(id))
              ..orderBy([(t) => OrderingTerm.asc(t.seq)])
              ..limit(1))
            .getSingleOrNull();
    if (first == null) {
      await _deleteConversation(id);
      return;
    }
    // 남은 첫 턴이 지운 턴보다 뒤면 지운 것이 첫 턴이었다.
    if (!conversation.titleEdited && first.seq > seq) {
      await (_db.update(
        _db.conversations,
      )..where((c) => c.id.equals(id))).write(
        ConversationsCompanion(
          title: Value(conversationTitleFrom(first.question)),
        ),
      );
    }
  });

  @override
  Future<void> delete(String id) => _deleteConversation(id);

  @override
  Future<int> deleteAll() => _db.delete(_db.conversations).go();

  @override
  Future<int> deleteOlderThan(DateTime cutoff, {String? except}) {
    // 날짜는 TEXT(storeDateTimeAsText)로 저장되고 Clock.now() 의 로컬 시각이다.
    // UTC cutoff 는 'Z' 접미사가 붙어 글자 비교가 어긋나므로 로컬 시각만 받는다.
    assert(!cutoff.isUtc, 'deleteOlderThan 의 cutoff 는 로컬 시각이어야 한다');
    return (_db.delete(_db.conversations)..where((c) {
          final old = c.updatedAt.isSmallerThanValue(cutoff);
          return except == null ? old : old & c.id.equals(except).not();
        }))
        .go();
  }

  /// 턴은 foreign key cascade 로 함께 지워진다.
  Future<int> _deleteConversation(String id) =>
      (_db.delete(_db.conversations)..where((c) => c.id.equals(id))).go();

  Conversation _conversationFrom(ConversationRow r, int turnCount) =>
      Conversation(
        id: r.id,
        title: r.title,
        titleEdited: r.titleEdited,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        turnCount: turnCount,
      );

  ChatTurnRecord _turnFrom(ChatTurnRow r) => ChatTurnRecord(
    conversationId: r.conversationId,
    seq: r.seq,
    question: r.question,
    answer: r.answer,
    citedEntryIds: r.citedEntryIds,
    stopped: r.stopped,
    vendor: r.vendor,
    model: r.model,
    askedAt: r.askedAt,
  );
}
