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

  /// 화면에 찍는 종목 이름. `BTCUSDT` → `BTC`.
  ///
  /// 시세 seed 가 전부 USDT 마켓이라 접미가 모든 심볼에 똑같이 붙는다. 매번
  /// 같은 꼬리를 보여줘 봐야 구분에 보태는 게 없어 뗀다.
  String get displaySymbol => displaySymbolOf(symbol);

  /// [displaySymbol] 의 문자열 버전.
  ///
  /// 결과 entity 없이 심볼만 들고 표기해야 하는 자리(표기 헬퍼)가 규칙을
  /// 따로 구현하지 않도록 여기 하나만 둔다.
  static String displaySymbolOf(String symbol) {
    const quote = 'USDT';
    if (symbol.length > quote.length && symbol.endsWith(quote)) {
      return symbol.substring(0, symbol.length - quote.length);
    }
    return symbol;
  }
}
