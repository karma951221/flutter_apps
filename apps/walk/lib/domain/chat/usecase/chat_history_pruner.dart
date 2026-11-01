import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../chat_history_settings.dart';
import '../repository/chat_history_repository.dart';
import '../repository/chat_usage_repository.dart';
import 'open_conversation.dart';

/// 보관 기간이 지난 대화와 오래된 사용량을 지운다. 셸이 시작 · 복귀 때 부른다.
@lazySingleton
class ChatHistoryPruner {
  ChatHistoryPruner(
    this._history,
    this._usage,
    this._settings,
    this._open,
    this._clock,
  );

  final ChatHistoryRepository _history;
  final ChatUsageRepository _usage;
  final ChatHistorySettings _settings;
  final OpenConversation _open;
  final Clock _clock;

  /// 사용량 보관: 이번 달 + 지난 12개월(지난해 같은 달까지).
  static const usageMonths = 13;

  /// 겹쳐 부르면 한 번에 하나씩 돈다(`RingArchiver` 와 같은 패턴).
  Future<void> _tail = Future.value();

  /// 보관 기간이 지난 대화(열린 대화 제외)와 13개월 전 사용량을 지운다. 겹쳐 부르면 차례로.
  /// 한쪽이 던져도 다른 쪽은 한다. 던지지 않는다.
  Future<void> prune() {
    // 어느 단계가 던져도 줄([_tail])은 성공으로 끝난다 — 다음 호출이 막히지 않게.
    final result = _tail.then((_) => _prune()).catchError((Object _) {});
    _tail = result;
    return result;
  }

  Future<void> _prune() async {
    final DateTime now;
    final Duration? period;
    try {
      now = _clock.now();
      period = _settings.retention.period;
    } on Object {
      // 시계 · 설정을 읽지 못하면 이번엔 건너뛴다.
      return;
    }
    if (period != null) {
      try {
        await _history.deleteOlderThan(now.subtract(period), except: _open.id);
      } on Object {
        // 다음 시작 · 복귀 때 다시 한다.
      }
    }
    try {
      // 그 달 1일 00:00(로컬). DateTime 이 음수 달을 지난해로 넘긴다.
      await _usage.deleteOlderThan(
        DateTime(now.year, now.month - (usageMonths - 1)),
      );
    } on Object {
      // 다음 시작 · 복귀 때 다시 한다.
    }
  }
}
