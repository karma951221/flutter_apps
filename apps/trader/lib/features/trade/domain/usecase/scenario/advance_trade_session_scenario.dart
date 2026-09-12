import '../../../../../core/error/failure.dart';
import '../../../../../core/error/failure_code.dart';
import '../../../../../core/result/result.dart';
import '../../entity/trade_session.dart';
import '../../repository/trade_repository.dart';

/// 다음 step 으로 진행한다.
///
/// step 59 에서 부르면 서버가 index 119 를 공개하고 보유분을 청산해 판을
/// 자동 종료한다.
class AdvanceTradeSessionScenario {
  const AdvanceTradeSessionScenario(this._repository);

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
    return _repository.advance(sessionId);
  }
}
