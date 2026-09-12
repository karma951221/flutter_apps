import 'dart:math' as math;

import '../../domain/entity/trade_candle.dart';
import '../../domain/entity/trade_order.dart';
import '../../domain/entity/trade_result.dart';
import '../../domain/entity/trade_session.dart';
import '../../domain/entity/trade_session_summary.dart';
import '../../domain/entity/trade_side.dart';
import '../../domain/trade_rules.dart';
import '../dto/trade_candle_dto.dart';
import '../dto/trade_order_dto.dart';
import '../dto/trade_result_dto.dart';
import '../dto/trade_session_dto.dart';
import '../dto/trade_session_summary_dto.dart';

/// data/domain 경계의 trade 모델 변환.
extension TradeCandleDtoMapper on TradeCandleDto {
  TradeCandle toEntity() =>
      TradeCandle(index: index, open: open, high: high, low: low, close: close);
}

extension TradeOrderDtoMapper on TradeOrderDto {
  TradeOrder toEntity() => TradeOrder(
    step: step,
    side: TradeSide.fromWire(side),
    quantity: quantity,
    price: price,
    fee: fee,
  );
}

extension TradeResultDtoMapper on TradeResultDto {
  TradeResult toEntity() => TradeResult(
    symbol: symbol,
    startDay: startDay,
    endDay: endDay,
    endIndex: endIndex,
    finalEquity: finalEquity,
    returnPct: returnPct,
    buyHoldReturnPct: buyHoldReturnPct,
    maxDrawdownPct: maxDrawdownPct,
    tradeCount: tradeCount,
  );
}

extension TradeSessionDtoMapper on TradeSessionDto {
  TradeSession toEntity() => TradeSession(
    id: id,
    userId: userId,
    step: step,
    cash: cash,
    quantity: quantity,
    isFinished: isFinished,
    candles: candles.map((candle) => candle.toEntity()).toList(),
    orders: orders.map((order) => order.toEntity()).toList(),
    result: result?.toEntity(),
  );
}

extension TradeSessionSummaryDtoMapper on TradeSessionSummaryDto {
  TradeSessionSummary toEntity() => TradeSessionSummary(
    id: id,
    createdAt: createdAt,
    finishedAt: finishedAt,
    result: _result,
  );

  /// 테이블에는 `end_index` 컬럼이 없다 — `step` 으로 되짚는다
  /// (`min(59 + step, 119)`, `TradeRules.indexForStep` 과 같은 식이되 상한을
  /// 명시적으로 건다).
  ///
  /// 목록은 끝난 판만 조회하므로 실제로는 여덟 필드가 항상 함께 채워져
  /// 있지만, 스키마상 전부 nullable 이라 하나라도 비면 null 로 방어한다
  /// (`TradeSessionSummary.result` 의 문서 참고).
  TradeResult? get _result {
    final symbol = revealedSymbol;
    final startDay = revealedStartDay;
    final endDay = revealedEndDay;
    final equity = finalEquity;
    final returnPctValue = returnPct;
    final buyHold = buyHoldReturnPct;
    final drawdown = maxDrawdownPct;
    final count = tradeCount;
    if (symbol == null ||
        startDay == null ||
        endDay == null ||
        equity == null ||
        returnPctValue == null ||
        buyHold == null ||
        drawdown == null ||
        count == null) {
      return null;
    }

    return TradeResult(
      symbol: symbol,
      startDay: startDay,
      endDay: endDay,
      endIndex: math.min(
        TradeRules.indexForStep(step),
        TradeRules.totalCandles - 1,
      ),
      finalEquity: equity,
      returnPct: returnPctValue,
      buyHoldReturnPct: buyHold,
      maxDrawdownPct: drawdown,
      tradeCount: count,
    );
  }
}
