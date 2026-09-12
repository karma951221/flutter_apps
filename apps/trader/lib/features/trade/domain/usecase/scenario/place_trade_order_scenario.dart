import '../../../../../core/error/failure.dart';
import '../../../../../core/error/failure_code.dart';
import '../../../../../core/result/result.dart';
import '../../entity/trade_session.dart';
import '../../entity/trade_side.dart';
import '../../repository/trade_repository.dart';

/// 주문을 낸다.
///
/// 잔고 부족·보유 초과 여부는 서버가 최종 판단한다 — 여기서는 요청 형태만
/// 본다(빈 판 id, 0 이하·NaN·Infinity 수량).
class PlaceTradeOrderScenario {
  const PlaceTradeOrderScenario(this._repository);

  final TradeRepository _repository;

  Future<Result<TradeSession>> call({
    required String sessionId,
    required TradeSide side,
    required double quantity,
  }) {
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
    if (!quantity.isFinite || quantity <= 0) {
      return Future.value(
        const Err(
          Failure.validation(
            message: '수량은 0보다 커야 합니다',
            failureCode: FailureCode.tradeQuantityInvalid,
          ),
        ),
      );
    }
    return _repository.placeOrder(
      sessionId: sessionId,
      side: side,
      quantity: quantity,
    );
  }
}
