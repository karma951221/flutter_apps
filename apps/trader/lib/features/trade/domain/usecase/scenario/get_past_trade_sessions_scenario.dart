import 'package:core/core.dart';
import '../../entity/trade_session_summary.dart';
import '../../repository/trade_repository.dart';

/// 내 지난 판(끝난 판만) 목록을 최신순으로 조회한다.
class GetPastTradeSessionsScenario {
  const GetPastTradeSessionsScenario(this._repository);

  /// 한 번에 가져올 수 있는 최대 개수. 피드·팔로우와 같은 상한을 쓴다.
  static const maxPageSize = 50;

  final TradeRepository _repository;

  Future<Result<CursorPage<TradeSessionSummary>>> call({
    required int limit,
    String? cursor,
  }) {
    // trade 전용 범위 코드가 없어 feed 와 같은 FailureCode 를 쓴다 — 문구가
    // 사용자에게 노출되는 자리가 아니라 로그·분기용이라 공유해도 무리가 없다.
    if (limit < 1 || limit > maxPageSize) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '올바른 조회 범위가 아닙니다',
            failureCode: FailureCode.feedRangeInvalid,
          ),
        ),
      );
    }
    return _repository.getPastSessions(limit: limit, cursor: cursor);
  }
}
