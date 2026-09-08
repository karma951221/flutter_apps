import 'package:injectable/injectable.dart';

import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../entity/trade_session.dart';
import '../entity/trade_session_summary.dart';
import '../entity/trade_side.dart';
import '../repository/trade_repository.dart';
import 'scenario/advance_trade_session_scenario.dart';
import 'scenario/finish_trade_session_scenario.dart';
import 'scenario/get_active_trade_session_scenario.dart';
import 'scenario/get_past_trade_sessions_scenario.dart';
import 'scenario/get_trade_session_scenario.dart';
import 'scenario/place_trade_order_scenario.dart';
import 'scenario/start_trade_session_scenario.dart';

/// trade feature 의 presentation 진입점.
abstract interface class TradeUseCase {
  Future<Result<String>> startSession();

  Future<Result<TradeSession>> getSession(String sessionId);

  Future<Result<TradeSession?>> getActiveSession();

  Future<Result<TradeSession>> placeOrder({
    required String sessionId,
    required TradeSide side,
    required double quantity,
  });

  Future<Result<TradeSession>> advance(String sessionId);

  Future<Result<TradeSession>> finish(String sessionId);

  Future<Result<CursorPage<TradeSessionSummary>>> getPastSessions({
    int limit = 20,
    String? cursor,
  });
}

@LazySingleton(as: TradeUseCase)
class DefaultTradeUseCase implements TradeUseCase {
  DefaultTradeUseCase(this._repository);

  final TradeRepository _repository;

  @override
  Future<Result<String>> startSession() =>
      StartTradeSessionScenario(_repository)();

  @override
  Future<Result<TradeSession>> getSession(String sessionId) =>
      GetTradeSessionScenario(_repository)(sessionId);

  @override
  Future<Result<TradeSession?>> getActiveSession() =>
      GetActiveTradeSessionScenario(_repository)();

  @override
  Future<Result<TradeSession>> placeOrder({
    required String sessionId,
    required TradeSide side,
    required double quantity,
  }) => PlaceTradeOrderScenario(_repository)(
    sessionId: sessionId,
    side: side,
    quantity: quantity,
  );

  @override
  Future<Result<TradeSession>> advance(String sessionId) =>
      AdvanceTradeSessionScenario(_repository)(sessionId);

  @override
  Future<Result<TradeSession>> finish(String sessionId) =>
      FinishTradeSessionScenario(_repository)(sessionId);

  @override
  Future<Result<CursorPage<TradeSessionSummary>>> getPastSessions({
    int limit = 20,
    String? cursor,
  }) =>
      GetPastTradeSessionsScenario(_repository)(limit: limit, cursor: cursor);
}
