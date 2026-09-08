import 'package:freezed_annotation/freezed_annotation.dart';

import 'trade_result.dart';

part 'trade_result_summary.freezed.dart';

/// 게시물에 붙은 끝난 판의 결과 요약.
///
/// [TradeResult] 와 값이 겹치지만 쓰임이 다르다. 저쪽은 결과 화면이 쓰는 판
/// 전체의 결과(현금·종료 봉까지)이고, 이쪽은 **피드 카드 한 장에 필요한 만큼**
/// 이다 — 대신 결과 화면으로 들어갈 [sessionId] 를 갖는다. 뷰
/// (`posts_with_author.trade_result`)와 단건 조회의 임베드가 내려주는 여덟 키가
/// 그대로 이 여덟 필드다(docs/schema.md §6).
@freezed
class TradeResultSummary with _$TradeResultSummary {
  const TradeResultSummary({
    required this.sessionId,
    required this.symbol,
    required this.startDay,
    required this.endDay,
    required this.returnPct,
    required this.buyHoldReturnPct,
    required this.maxDrawdownPct,
    required this.tradeCount,
  });

  /// 결과 화면으로 들어가는 링크. 끝난 판이므로 누구나 열 수 있다.
  @override
  final String sessionId;
  @override
  final String symbol;
  @override
  final DateTime startDay;
  @override
  final DateTime endDay;
  @override
  final double returnPct;
  @override
  final double buyHoldReturnPct;
  @override
  final double maxDrawdownPct;
  @override
  final int tradeCount;

  /// 그냥 들고만 있었을 때(buy & hold)보다 나은 성과를 냈는지.
  bool get beatBuyHold => returnPct > buyHoldReturnPct;

  /// 화면에 찍는 종목 이름. `BTCUSDT` → `BTC`.
  ///
  /// 규칙은 [TradeResult.displaySymbolOf] 하나만 둔다 — 결과 화면과 피드 카드가
  /// 같은 심볼을 다르게 적으면 안 된다.
  String get displaySymbol => TradeResult.displaySymbolOf(symbol);
}
