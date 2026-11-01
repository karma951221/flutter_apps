import '../entity/chat_usage_summary.dart';

abstract interface class ChatUsageRepository {
  /// 로컬 `DateTime(year, month)` 이상 `DateTime(year, month + 1)` 미만.
  /// questions = 서로 다른 questionKey 수(purpose == chat 만), 토큰은 모든 purpose 합(임시 대화 포함).
  Future<ChatUsageMonth> month(int year, int month);

  /// at < [cutoff] 행을 지운다. 지운 수.
  Future<int> deleteOlderThan(DateTime cutoff);

  Future<void> deleteAll();
}
