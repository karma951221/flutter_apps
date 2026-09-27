import 'package:freezed_annotation/freezed_annotation.dart';

import 'trade_result.dart';

part 'trade_result_summary.freezed.dart';

/// 게시물에 붙은 끝난 판의 결과 요약.
///
/// [TradeResult] 와 값이 겹치지만 쓰임이 다르다. 저쪽은 결과 화면이 쓰는 판
/// 전체의 결과(현금·종료 봉까지)이고, 이쪽은 **피드 카드 한 장에 필요한 만큼**
/// 이다 — 대신 결과 화면으로 들어갈 [sessionId] 를 갖는다. 뷰
/// (`posts_with_author.trade_result`)와 단건 조회의 임베드가 내려주는 여덟 키가
/// 그대로 이 여덟 필드다(apps/trader/docs/schema.md §6).
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

  /// go_router 의 `extra` 로 들려 보낼 JSON 호환 표현.
  ///
  /// 이 타입 자체를 `extra` 로 넘기면 go_router 가 상태 복원용 기본 codec으로
  /// `json.encoder.convert` 를 시도하다 실패해 경고를 낸다(codec 미등록 클래스).
  /// 키는 `posts_with_author.trade_result` 뷰가 내려주는 여덟 키와 같다
  /// (apps/trader/docs/schema.md §6).
  Map<String, Object?> toMap() => {
    'session_id': sessionId,
    'symbol': symbol,
    'start_day': _formatDay(startDay),
    'end_day': _formatDay(endDay),
    'return_pct': returnPct,
    'buy_hold_return_pct': buyHoldReturnPct,
    'max_drawdown_pct': maxDrawdownPct,
    'trade_count': tradeCount,
  };

  static String _formatDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// [toMap] 의 역변환. `raw` 가 그 형태가 아니면(맵이 아니거나, 키가 없거나,
  /// 타입이 다르면) `null` 을 돌려준다 — 낡거나 손으로 만든 `extra` 가 작성
  /// 화면을 깨뜨리지 않게 하기 위해서다.
  static TradeResultSummary? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final sessionId = raw['session_id'];
    final symbol = raw['symbol'];
    final startDay = raw['start_day'];
    final endDay = raw['end_day'];
    final returnPct = raw['return_pct'];
    final buyHoldReturnPct = raw['buy_hold_return_pct'];
    final maxDrawdownPct = raw['max_drawdown_pct'];
    final tradeCount = raw['trade_count'];
    if (sessionId is! String ||
        symbol is! String ||
        startDay is! String ||
        endDay is! String ||
        returnPct is! num ||
        buyHoldReturnPct is! num ||
        maxDrawdownPct is! num ||
        tradeCount is! num) {
      return null;
    }
    final parsedStart = DateTime.tryParse(startDay);
    final parsedEnd = DateTime.tryParse(endDay);
    if (parsedStart == null || parsedEnd == null) return null;
    return TradeResultSummary(
      sessionId: sessionId,
      symbol: symbol,
      startDay: parsedStart,
      endDay: parsedEnd,
      returnPct: returnPct.toDouble(),
      buyHoldReturnPct: buyHoldReturnPct.toDouble(),
      maxDrawdownPct: maxDrawdownPct.toDouble(),
      tradeCount: tradeCount.toInt(),
    );
  }
}
