import '../../../../../core/error/failure.dart';
import '../../../../../core/error/failure_code.dart';
import '../../../../../core/result/result.dart';
import '../../entity/trade_session.dart';
import '../../repository/trade_repository.dart';

/// 아무 step 에서나 현재 종가로 보유분을 청산하고 판을 끝낸다.
class FinishTradeSessionScenario {
  const FinishTradeSessionScenario(this._repository);

  final TradeRepository _repository;

  Future<Result<TradeSession>> call(String sessionId) {
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
    return _repository.finish(sessionId);
  }
}
