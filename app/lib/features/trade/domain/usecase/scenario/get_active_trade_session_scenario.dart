import '../../../../../core/result/result.dart';
import '../../entity/trade_session.dart';
import '../../repository/trade_repository.dart';

/// 진행 중인 판을 가져온다. 없으면 null — 실패가 아니다.
class GetActiveTradeSessionScenario {
  const GetActiveTradeSessionScenario(this._repository);

  final TradeRepository _repository;

  Future<Result<TradeSession?>> call() => _repository.getActiveSession();
}
