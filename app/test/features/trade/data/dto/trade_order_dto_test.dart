import 'package:daylog/features/trade/data/dto/trade_order_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trade_session_state() 의 주문 하나를 파싱한다', () {
    final dto = TradeOrderDto.fromJson({
      'step': 3,
      'side': 'buy',
      'quantity': 1.5,
      'price': 100.0,
      'fee': 0.15,
    });

    expect(dto.step, 3);
    expect(dto.side, 'buy');
    expect(dto.quantity, 1.5);
    expect(dto.price, 100.0);
    expect(dto.fee, 0.15);
  });

  test('정수로 온 quantity/price/fee 도 double 로 받는다', () {
    final dto = TradeOrderDto.fromJson({
      'step': 0,
      'side': 'sell',
      'quantity': 2,
      'price': 100,
      'fee': 0,
    });

    expect(dto.quantity, isA<double>());
    expect(dto.quantity, 2.0);
    expect(dto.price, 100.0);
    expect(dto.fee, 0.0);
  });

  test('JSON 왕복', () {
    const dto = TradeOrderDto(step: 2, side: 'sell', quantity: 1, price: 99, fee: 0.1);

    expect(TradeOrderDto.fromJson(dto.toJson()), dto);
  });
}
