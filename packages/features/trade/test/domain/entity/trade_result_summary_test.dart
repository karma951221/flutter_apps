import 'package:feature_trade/feature_trade.dart';
import 'package:flutter_test/flutter_test.dart';

// 로컬(비-UTC) 자정으로 둔다 — fromMap 이 DateTime.parse 로 만드는 값과 같은
// 형태라야 왕복 후 완전한 값 동등성(==)이 성립한다. TradeResultDto 의 왕복
// 테스트와 같은 이유다.
TradeResultSummary _summary() => TradeResultSummary(
  sessionId: 'session-1',
  symbol: 'BTCUSDT',
  startDay: DateTime.parse('2021-11-01'),
  endDay: DateTime.parse('2022-01-29'),
  returnPct: 12.34,
  buyHoldReturnPct: 3,
  maxDrawdownPct: 8,
  tradeCount: 4,
);

void main() {
  test('toMap 은 뷰의 여덟 키와 같은 JSON 호환 Map 을 준다', () {
    final map = _summary().toMap();

    expect(map, {
      'session_id': 'session-1',
      'symbol': 'BTCUSDT',
      'start_day': '2021-11-01',
      'end_day': '2022-01-29',
      'return_pct': 12.34,
      'buy_hold_return_pct': 3.0,
      'max_drawdown_pct': 8.0,
      'trade_count': 4,
    });
  });

  test('toMap → fromMap 왕복', () {
    final summary = _summary();

    final roundTripped = TradeResultSummary.fromMap(summary.toMap());

    expect(roundTripped, summary);
  });

  test('fromMap 은 시간대를 옮기지 않는다 — 날짜가 하루 밀리지 않는다', () {
    final summary = TradeResultSummary.fromMap({
      'session_id': 's1',
      'symbol': 'BTCUSDT',
      'start_day': '2024-02-01',
      'end_day': '2024-02-29',
      'return_pct': 1,
      'buy_hold_return_pct': 1,
      'max_drawdown_pct': 1,
      'trade_count': 1,
    })!;

    expect(summary.startDay, DateTime.parse('2024-02-01'));
    expect(summary.startDay.day, 1);
    expect(summary.endDay.day, 29);
  });

  test('Map 이 아니면 null', () {
    expect(TradeResultSummary.fromMap('not a map'), isNull);
    expect(TradeResultSummary.fromMap(null), isNull);
    expect(TradeResultSummary.fromMap(42), isNull);
  });

  test('키가 빠지면 null', () {
    final map = _summary().toMap()..remove('symbol');

    expect(TradeResultSummary.fromMap(map), isNull);
  });

  test('타입이 다르면 null', () {
    final map = _summary().toMap();
    map['trade_count'] = 'four';

    expect(TradeResultSummary.fromMap(map), isNull);
  });

  test('날짜가 파싱되지 않는 문자열이면 null', () {
    final map = _summary().toMap();
    map['start_day'] = '이번 달';

    expect(TradeResultSummary.fromMap(map), isNull);
  });
}
