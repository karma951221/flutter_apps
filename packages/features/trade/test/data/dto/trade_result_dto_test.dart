import 'package:feature_trade/feature_trade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trade_session_state() 의 result 를 파싱한다', () {
    final dto = TradeResultDto.fromJson({
      'symbol': 'AAA',
      'start_day': '2026-01-01',
      'end_day': '2026-06-01',
      'end_index': 119,
      'final_equity': 10500.25,
      'return_pct': 5.0,
      'buy_hold_return_pct': 3.2,
      'max_drawdown_pct': 12.5,
      'trade_count': 4,
    });

    expect(dto.symbol, 'AAA');
    expect(dto.startDay, DateTime.parse('2026-01-01'));
    expect(dto.endDay, DateTime.parse('2026-06-01'));
    expect(dto.endIndex, 119);
    expect(dto.finalEquity, 10500.25);
    expect(dto.returnPct, 5.0);
    expect(dto.buyHoldReturnPct, 3.2);
    expect(dto.maxDrawdownPct, 12.5);
    expect(dto.tradeCount, 4);
  });

  test('정수로 온 final_equity 도 double 로 받는다', () {
    final dto = TradeResultDto.fromJson({
      'symbol': 'AAA',
      'start_day': '2026-01-01',
      'end_day': '2026-06-01',
      'end_index': 119,
      'final_equity': 10000,
      'return_pct': 0,
      'buy_hold_return_pct': 0,
      'max_drawdown_pct': 0,
      'trade_count': 0,
    });

    expect(dto.finalEquity, isA<double>());
    expect(dto.finalEquity, 10000.0);
  });

  test('JSON 왕복', () {
    final dto = TradeResultDto(
      symbol: 'BBB',
      startDay: DateTime.parse('2026-02-01'),
      endDay: DateTime.parse('2026-07-01'),
      endIndex: 100,
      finalEquity: 9800.5,
      returnPct: -1.5,
      buyHoldReturnPct: -0.2,
      maxDrawdownPct: 8.1,
      tradeCount: 2,
    );

    expect(TradeResultDto.fromJson(dto.toJson()), dto);
  });
}
