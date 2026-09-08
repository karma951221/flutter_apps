import 'package:daylog/features/trade/presentation/format/trade_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('signedPct', () {
    test('오른 값에는 + 를, 내린 값에는 빼기 부호(U+2212)를 붙인다', () {
      expect(TradeFormat.signedPct(12.34), '+12.34%');
      expect(TradeFormat.signedPct(-5.1), '−5.10%');
      expect(TradeFormat.signedPct(-5.1).contains('-'), isFalse);
    });

    test('0 은 부호 없이 찍는다', () {
      expect(TradeFormat.signedPct(0), '0.00%');
      // 반올림해서 0 이 된 값도 방향을 말하지 않는다 — '-0.00%' 는 안 나온다.
      expect(TradeFormat.signedPct(-0.001), '0.00%');
      expect(TradeFormat.signedPct(0.001), '0.00%');
    });

    test('항상 소수 두 자리다', () {
      expect(TradeFormat.signedPct(5), '+5.00%');
      expect(TradeFormat.signedPct(-1.2), '−1.20%');
    });
  });

  test('pct 는 부호 없이 소수 두 자리로 찍는다', () {
    expect(TradeFormat.pct(3.2), '3.20%');
    expect(TradeFormat.pct(0), '0.00%');
  });

  test('amount 는 천 단위 구분과 소수 두 자리로 찍는다', () {
    expect(TradeFormat.amount(10000, 'ko'), '10,000.00');
    expect(TradeFormat.amount(9876.5, 'en'), '9,876.50');
  });

  group('quantity', () {
    test('소수 6자리까지 찍되 뒤의 0 은 떼어 낸다', () {
      expect(TradeFormat.quantity(0.5), '0.5');
      expect(TradeFormat.quantity(49.950049), '49.950049');
      expect(TradeFormat.quantity(0.0999), '0.0999');
    });

    test('소수가 없으면 소수점도 붙이지 않는다', () {
      expect(TradeFormat.quantity(0), '0');
      expect(TradeFormat.quantity(10), '10');
    });

    test('금액과 달리 천 단위 구분은 넣지 않는다', () {
      expect(TradeFormat.quantity(12345.5), '12345.5');
    });
  });

  test('dayRange 는 yyyy-MM-dd 두 개를 물결로 잇는다', () {
    expect(
      TradeFormat.dayRange(DateTime.utc(2021, 11), DateTime.utc(2022, 1, 29)),
      '2021-11-01 ~ 2022-01-29',
    );
  });

  group('symbolLabel', () {
    test('USDT 접미를 뗀다', () {
      expect(TradeFormat.symbolLabel('BTCUSDT'), 'BTC');
      expect(TradeFormat.symbolLabel('ETHUSDT'), 'ETH');
    });

    test('접미가 없으면 그대로 둔다', () {
      expect(TradeFormat.symbolLabel('AAPL'), 'AAPL');
      // 통째로 USDT 인 심볼은 뗄 앞부분이 없다.
      expect(TradeFormat.symbolLabel('USDT'), 'USDT');
    });
  });
}
