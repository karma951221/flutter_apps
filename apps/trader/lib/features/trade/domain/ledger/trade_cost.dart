import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_cost.freezed.dart';

/// 매수·매도 한 번의 금액 구성 — 표시용. 서버(RPC)가 정본이다.
@freezed
class TradeCost with _$TradeCost {
  @override
  final double amount;
  @override
  final double fee;
  @override
  final double total;

  const TradeCost({
    required this.amount,
    required this.fee,
    required this.total,
  });
}
