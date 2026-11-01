import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/domain/chat/entity/chat_usage_summary.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/repository/chat_usage_repository.dart';

/// 메모리 위의 대화 보관 기간 · 색인 크기. [failSet] 이면 set 들이 던진다.
class FakeChatHistorySettings implements ChatHistorySettings {
  FakeChatHistorySettings([this.retention = ChatRetention.fallback]);

  @override
  ChatRetention retention;

  @override
  WikiIndexSize wikiIndexSize = WikiIndexSize.fallback;

  bool failSet = false;

  @override
  Future<void> setRetention(ChatRetention value) async {
    if (failSet) throw StateError('prefs');
    retention = value;
  }

  @override
  Future<void> setWikiIndexSize(WikiIndexSize value) async {
    if (failSet) throw StateError('prefs');
    wikiIndexSize = value;
  }
}

/// 대화 수와 모두 지우기만 쓰는 대화 저장소. [failDeleteAll] 이면 모두 지우기가,
/// [failCount] 면 대화 수 읽기가 던진다.
class FakeChatHistoryCount implements ChatHistoryRepository {
  FakeChatHistoryCount([this.stored = 0]);

  int stored;
  bool failDeleteAll = false;
  bool failCount = false;
  int deleteAllCalls = 0;

  @override
  Future<int> count() async {
    if (failCount) throw StateError('count failed');
    return stored;
  }

  @override
  Future<int> deleteAll() async {
    deleteAllCalls++;
    if (failDeleteAll) throw StateError('delete failed');
    final n = stored;
    stored = 0;
    return n;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 달별 사용량을 [months] 에서 돌려준다. 없는 달은 빈 합계.
class FakeChatUsageRepository implements ChatUsageRepository {
  FakeChatUsageRepository([Map<(int, int), ChatUsageMonth>? months])
    : months = {...?months};

  final Map<(int, int), ChatUsageMonth> months;
  final List<(int, int)> reads = [];
  int deleteAllCalls = 0;
  bool failDeleteAll = false;

  static ChatUsageMonth empty(int year, int month) => ChatUsageMonth(
    year: year,
    month: month,
    totals: const ChatUsageTotals(
      questions: 0,
      inputTokens: 0,
      outputTokens: 0,
      cacheReadTokens: 0,
    ),
    rows: const [],
  );

  @override
  Future<ChatUsageMonth> month(int year, int month) async {
    reads.add((year, month));
    return months[(year, month)] ?? empty(year, month);
  }

  @override
  Future<void> deleteAll() async {
    deleteAllCalls++;
    if (failDeleteAll) throw StateError('clear failed');
    months.clear();
  }

  @override
  Future<int> deleteOlderThan(DateTime cutoff) async => 0;
}
