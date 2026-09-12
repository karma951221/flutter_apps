import 'package:feature_trade/feature_trade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TradeSizing.floorQuantity', () {
    test('음수는 0으로 내린다', () {
      expect(TradeSizing.floorQuantity(-1), 0);
    });

    test('0은 그대로 0', () {
      expect(TradeSizing.floorQuantity(0), 0);
    });

    test('소수 7자리 이하는 6자리로 내림한다', () {
      expect(TradeSizing.floorQuantity(1.1234567), closeTo(1.123456, 1e-9));
    });

    test('이진 부동소수점 오차가 있는 값도 의도한 6자리로 내림한다', () {
      // 0.29 * 1e6 은 이진 표현 오차로 289999.99999999994 가 되어, 보정 없이
      // floor 하면 289999 로 한 단위 잘못 내려간다.
      expect(TradeSizing.floorQuantity(0.29), closeTo(0.29, 1e-9));
    });

    test('NaN·Infinity 는 0으로 취급한다', () {
      // 0으로 나누기 등으로 생길 수 있다 — 그대로 두면 .floor() 가 예외를
      // 던진다.
      expect(TradeSizing.floorQuantity(double.nan), 0);
      expect(TradeSizing.floorQuantity(double.infinity), 0);
      expect(TradeSizing.floorQuantity(double.negativeInfinity), 0);
    });
  });

  group('TradeSizing.buyQuantity', () {
    test('현금이 0이면 살 수 있는 수량도 0', () {
      final quantity = TradeSizing.buyQuantity(
        cash: 0,
        price: 100,
        feeRate: 0.001,
        fraction: 1,
      );
      expect(quantity, 0);
    });

    test('100% 매수는 수수료를 포함해도 총액이 보유 현금을 넘지 않는다', () {
      const cash = 10000.0;
      const price = 100.0;
      const feeRate = 0.001;

      final quantity = TradeSizing.buyQuantity(
        cash: cash,
        price: price,
        feeRate: feeRate,
        fraction: 1,
      );
      final cost = TradeSizing.buyCost(
        quantity: quantity,
        price: price,
        feeRate: feeRate,
      );

      expect(quantity, closeTo(99.900099, 1e-9));
      expect(cost.total, lessThanOrEqualTo(cash));
    });

    test('25%·50% 매수도 총액이 그 비율의 현금을 넘지 않는다', () {
      const cash = 10000.0;
      const price = 37.5;
      const feeRate = 0.001;

      for (final fraction in [0.25, 0.5]) {
        final quantity = TradeSizing.buyQuantity(
          cash: cash,
          price: price,
          feeRate: feeRate,
          fraction: fraction,
        );
        final cost = TradeSizing.buyCost(
          quantity: quantity,
          price: price,
          feeRate: feeRate,
        );

        expect(cost.total, lessThanOrEqualTo(cash * fraction));
      }
    });
  });

  group('TradeSizing.quantityForAmount', () {
    test('금액을 그대로 수량으로 환산하고 6자리로 내림한다', () {
      final quantity = TradeSizing.quantityForAmount(
        amount: 1000,
        price: 100,
        feeRate: 0.001,
      );
      final cost = TradeSizing.buyCost(
        quantity: quantity,
        price: 100,
        feeRate: 0.001,
      );

      expect(cost.total, lessThanOrEqualTo(1000));
    });
  });

  group('TradeSizing.sellQuantity', () {
    test('100% 매도는 보유량을 그대로 돌려준다(내림 오차 없음)', () {
      const held = 1.234567;
      expect(TradeSizing.sellQuantity(quantity: held, fraction: 1), held);
    });

    test('부분 매도는 6자리로 내림한다', () {
      final quantity = TradeSizing.sellQuantity(quantity: 10, fraction: 0.3);
      expect(quantity, closeTo(3.0, 1e-9));
    });
  });

  group('TradeSizing.buyCost', () {
    test('amount·fee·total 이 정의대로 계산된다', () {
      final cost = TradeSizing.buyCost(
        quantity: 10,
        price: 100,
        feeRate: 0.001,
      );

      expect(cost, const TradeCost(amount: 1000, fee: 1, total: 1001));
    });
  });

  group('TradeSizing.sellProceeds', () {
    test('수수료는 받는 돈에서 빠진다', () {
      final proceeds = TradeSizing.sellProceeds(
        quantity: 10,
        price: 100,
        feeRate: 0.001,
      );

      expect(proceeds, const TradeCost(amount: 1000, fee: 1, total: 999));
    });
  });
}
