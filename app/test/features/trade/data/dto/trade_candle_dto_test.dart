import 'package:daylog/features/trade/data/dto/trade_candle_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trade_session_state() 의 봉 하나를 파싱한다', () {
    final dto = TradeCandleDto.fromJson({
      'i': 59,
      'o': 99.5,
      'h': 101.2,
      'l': 98.1,
      'c': 100.0,
    });

    expect(dto.index, 59);
    expect(dto.open, 99.5);
    expect(dto.high, 101.2);
    expect(dto.low, 98.1);
    expect(dto.close, 100.0);
  });

  test('정수로 온 숫자도 double 로 받는다', () {
    final dto = TradeCandleDto.fromJson({'i': 0, 'o': 100, 'h': 100, 'l': 100, 'c': 100});

    expect(dto.open, isA<double>());
    expect(dto.open, 100.0);
  });

  test('JSON 왕복', () {
    const dto = TradeCandleDto(index: 1, open: 1.1, high: 2.2, low: 0.5, close: 1.5);

    expect(TradeCandleDto.fromJson(dto.toJson()), dto);
  });
}
