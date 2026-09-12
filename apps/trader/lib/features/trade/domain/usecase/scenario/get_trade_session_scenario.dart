import 'package:core/core.dart';
import '../../entity/trade_session.dart';
import '../../repository/trade_repository.dart';

/// 판 하나를 id 로 조회한다.
class GetTradeSessionScenario {
  const GetTradeSessionScenario(this._repository);

  final TradeRepository _repository;

  Future<Result<TradeSession>> call(String sessionId) {
    // 그대로 내려보내면 저장소가 빈 문자열로 조회를 시도해 코드 없는
    // Failure.server 가 될 수 있다 — follow 의 같은 문제(2026-08-30 리뷰)와
    // 같은 이유로 여기서 먼저 막는다.
    if (sessionId.trim().isEmpty) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '판 식별자가 필요합니다',
            failureCode: FailureCode.tradeSessionNotFound,
          ),
        ),
      );
    }
    return _repository.getSession(sessionId);
  }
}
