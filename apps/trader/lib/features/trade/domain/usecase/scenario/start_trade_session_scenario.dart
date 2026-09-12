import 'package:core/core.dart';
import '../../repository/trade_repository.dart';

/// 새 판을 시작한다.
///
/// 진행 중인 판이 있으면 서버가 거부한다
/// ([FailureCode.tradeSessionAlreadyActive]) — 여기서 미리 막지 않는다.
/// 클라이언트가 "진행 중인지" 를 캐시해서 판단하면 다른 기기에서 이미 시작한
/// 판과 어긋날 수 있어서다.
class StartTradeSessionScenario {
  const StartTradeSessionScenario(this._repository);

  final TradeRepository _repository;

  Future<Result<String>> call() => _repository.startSession();
}
