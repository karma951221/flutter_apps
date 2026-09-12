import 'package:feature_trade/feature_trade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('진행 중인 판을 파싱한다 — result 없음', () {
    final dto = TradeSessionDto.fromJson({
      'id': 'session-1',
      'user_id': 'user-1',
      'step': 3,
      'cash': 10000,
      'quantity': 0,
      'finished': false,
      'candles': [
        {'i': 0, 'o': 100, 'h': 100, 'l': 100, 'c': 100},
      ],
      'orders': <Map<String, dynamic>>[],
      'result': null,
    });

    expect(dto.id, 'session-1');
    expect(dto.userId, 'user-1');
    expect(dto.step, 3);
    expect(dto.cash, isA<double>());
    expect(dto.cash, 10000.0);
    expect(dto.quantity, 0.0);
    expect(dto.isFinished, isFalse);
    expect(dto.candles, hasLength(1));
    expect(dto.orders, isEmpty);
    expect(dto.result, isNull);
  });

  test('끝난 판을 파싱한다 — result 있음, 주문 여러 개', () {
    final dto = TradeSessionDto.fromJson({
      'id': 'session-2',
      'user_id': 'user-2',
      'step': 60,
      'cash': 10500,
      'quantity': 0,
      'finished': true,
      'candles': <Map<String, dynamic>>[],
      'orders': [
        {'step': 0, 'side': 'buy', 'quantity': 1, 'price': 100, 'fee': 0.1},
        {'step': 5, 'side': 'sell', 'quantity': 1, 'price': 105, 'fee': 0.105},
      ],
      'result': {
        'symbol': 'AAA',
        'start_day': '2026-01-01',
        'end_day': '2026-06-01',
        'end_index': 119,
        'final_equity': 10500,
        'return_pct': 5,
        'buy_hold_return_pct': 3.2,
        'max_drawdown_pct': 12.5,
        'trade_count': 2,
      },
    });

    expect(dto.isFinished, isTrue);
    expect(dto.orders, hasLength(2));
    expect(dto.result, isNotNull);
    expect(dto.result!.symbol, 'AAA');
    expect(dto.result!.finalEquity, 10500.0);
  });

  test('candles/orders 가 없으면 빈 리스트다', () {
    final dto = TradeSessionDto.fromJson({
      'id': 'session-3',
      'user_id': 'user-3',
      'step': 0,
      'cash': 10000,
      'quantity': 0,
      'finished': false,
    });

    expect(dto.candles, isEmpty);
    expect(dto.orders, isEmpty);
  });

  test('JSON 왕복', () {
    const dto = TradeSessionDto(
      id: 'session-4',
      userId: 'user-4',
      step: 10,
      cash: 9000,
      quantity: 1.5,
      isFinished: false,
    );

    expect(TradeSessionDto.fromJson(dto.toJson()), dto);
  });
}
