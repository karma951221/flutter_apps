import 'package:freezed_annotation/freezed_annotation.dart';

import 'trade_side.dart';

part 'trade_order.freezed.dart';

/// 체결된 주문 하나.
///
/// step 60 자동 종료나 [finish] 에 의한 청산 매도는 여기 담기지 않는다 —
/// 그 둘은 `trade_orders` 에 기록되지 않고 [TradeResult.tradeCount] 에도
/// 세지 않는다.
@freezed
class TradeOrder with _$TradeOrder {
  @override
  final int step;
  @override
  final TradeSide side;
  @override
  final double quantity;
  @override
  final double price;
  @override
  final double fee;

  const TradeOrder({
    required this.step,
    required this.side,
    required this.quantity,
    required this.price,
    required this.fee,
  });
}
