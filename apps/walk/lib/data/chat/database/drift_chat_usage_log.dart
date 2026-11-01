import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/chat/chat_usage_log.dart';
import '../../../domain/chat/entity/chat_usage_summary.dart';
import '../../../domain/chat/repository/chat_usage_repository.dart';
import 'chat_database.dart';

/// ChatUsageRecord 한 건 = chat_usage 한 행. 내용 · 대화 id 는 담지 않는다.
@LazySingleton(as: ChatUsageLog)
class DriftChatUsageLog implements ChatUsageLog {
  DriftChatUsageLog(this._db);

  final ChatDatabase _db;

  @override
  Future<void> record(ChatUsageRecord r) async {
    await _db
        .into(_db.chatUsageRows)
        .insert(
          ChatUsageRowsCompanion.insert(
            at: r.at,
            questionKey: r.questionKey,
            vendor: r.vendor,
            model: r.model,
            fastMode: Value(r.fastMode),
            purpose: r.purpose,
            round: r.round,
            temporary: r.temporary,
            inputTokens: r.inputTokens,
            outputTokens: r.outputTokens,
            cacheReadTokens: r.cacheReadTokens,
            cacheWriteTokens: r.cacheWriteTokens,
            reasoningTokens: Value(r.reasoningTokens),
            wikiIndexNotes: Value(r.wikiIndexNotes),
            wikiIndexChars: Value(r.wikiIndexChars),
            readWikiCalls: Value(r.readWikiCalls),
          ),
        );
  }
}

@LazySingleton(as: ChatUsageRepository)
class DriftChatUsageRepository implements ChatUsageRepository {
  DriftChatUsageRepository(this._db);

  final ChatDatabase _db;

  @override
  Future<ChatUsageMonth> month(int year, int month) async {
    final u = _db.chatUsageRows;
    final from = DateTime(year, month);
    final to = DateTime(year, month + 1);
    final inRange =
        u.at.isBiggerOrEqualValue(from) & u.at.isSmallerThanValue(to);
    final isChat = u.purpose.equalsValue(ChatUsagePurpose.chat);

    final questionKeys = u.questionKey.count(distinct: true, filter: isChat);
    final input = u.inputTokens.sum();
    final output = u.outputTokens.sum();
    final cacheRead = u.cacheReadTokens.sum();

    final totalsRow =
        await (_db.selectOnly(u)
              ..addColumns([questionKeys, input, output, cacheRead])
              ..where(inRange))
            .getSingle();
    final totals = ChatUsageTotals(
      questions: totalsRow.read(questionKeys) ?? 0,
      inputTokens: totalsRow.read(input) ?? 0,
      outputTokens: totalsRow.read(output) ?? 0,
      cacheReadTokens: totalsRow.read(cacheRead) ?? 0,
    );

    final rowQuestions = u.questionKey.count(distinct: true);
    final rowInput = u.inputTokens.sum();
    final rowOutput = u.outputTokens.sum();
    final rowRows =
        await (_db.selectOnly(u)
              ..addColumns([
                u.vendor,
                u.model,
                u.purpose,
                rowQuestions,
                rowInput,
                rowOutput,
              ])
              ..where(inRange)
              ..groupBy([u.vendor, u.model, u.purpose])
              ..orderBy([OrderingTerm.desc(rowInput)]))
            .get();
    final rows = [
      for (final r in rowRows)
        ChatUsageModelRow(
          vendor: u.vendor.converter.fromSql(r.read(u.vendor)!),
          model: r.read(u.model)!,
          purpose: u.purpose.converter.fromSql(r.read(u.purpose)!),
          questions: r.read(rowQuestions) ?? 0,
          inputTokens: r.read(rowInput) ?? 0,
          outputTokens: r.read(rowOutput) ?? 0,
        ),
    ];
    return ChatUsageMonth(
      year: year,
      month: month,
      totals: totals,
      rows: rows,
      wiki: await _wikiStats(inRange),
    );
  }

  /// 일반 대화(chat · 임시 아님) 질문별로 묶어 1라운드 색인 값과 read_wiki 여부를 모은다.
  Future<ChatUsageWikiStats> _wikiStats(Expression<bool> inRange) async {
    final u = _db.chatUsageRows;
    final isFirst = u.round.equals(1);
    final notes = u.wikiIndexNotes.sum(filter: isFirst);
    final chars = u.wikiIndexChars.sum(filter: isFirst);
    final reads = u.readWikiCalls.sum();
    final perQuestion =
        await (_db.selectOnly(u)
              ..addColumns([u.questionKey, notes, chars, reads])
              ..where(
                inRange &
                    u.purpose.equalsValue(ChatUsagePurpose.chat) &
                    u.temporary.equals(false),
              )
              ..groupBy([u.questionKey]))
            .get();
    final questions = perQuestion.length;
    if (questions == 0) return ChatUsageWikiStats.empty;
    var totalNotes = 0;
    var totalChars = 0;
    var withRead = 0;
    for (final r in perQuestion) {
      totalNotes += r.read(notes) ?? 0;
      totalChars += r.read(chars) ?? 0;
      if ((r.read(reads) ?? 0) >= 1) withRead++;
    }
    return ChatUsageWikiStats(
      questions: questions,
      avgIndexNotes: totalNotes / questions,
      avgIndexChars: totalChars / questions,
      questionsWithReadWiki: withRead,
    );
  }

  @override
  Future<int> deleteOlderThan(DateTime cutoff) => (_db.delete(
    _db.chatUsageRows,
  )..where((u) => u.at.isSmallerThanValue(cutoff))).go();

  @override
  Future<void> deleteAll() => _db.delete(_db.chatUsageRows).go();
}
