import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_result.freezed.dart';

/// 끝난 판의 결과.
///
/// 원가격·심볼·날짜는 판이 끝나야만 공개된다 — 진행 중인 판에는 이 값이
/// 없다([TradeSession.result] 가 null).
@freezed
class TradeResult with _$TradeResult {
  @override
  final String symbol;
  @override
  final DateTime startDay;
  @override
  final DateTime endDay;
  @override
  final int endIndex;
  @override
  final double finalEquity;
  @override
  final double returnPct;
  @override
  final double buyHoldReturnPct;
  @override
  final double maxDrawdownPct;
  @override
  final int tradeCount;

  const TradeResult({
    required this.symbol,
    required this.startDay,
    required this.endDay,
    required this.endIndex,
    required this.finalEquity,
    required this.returnPct,
    required this.buyHoldReturnPct,
    required this.maxDrawdownPct,
    required this.tradeCount,
  });

  /// 그냥 들고만 있었을 때(buy & hold)보다 나은 성과를 냈는지.
  bool get beatBuyHold => returnPct > buyHoldReturnPct;
}
