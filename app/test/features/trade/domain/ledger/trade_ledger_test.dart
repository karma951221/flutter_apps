import 'package:daylog/features/trade/domain/ledger/trade_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TradeLedger.equity', () {
    test('현금만 있고 보유가 없으면 평가액은 현금과 같다', () {
      expect(TradeLedger.equity(10000, 0, 123.45), 10000);
    });

    test('현금과 보유 평가액을 더한다', () {
      expect(TradeLedger.equity(5000, 10, 200), 7000);
    });

    test('현금이 0이어도 보유 평가액만으로 계산된다', () {
      expect(TradeLedger.equity(0, 50, 100), 5000);
    });
  });

  group('TradeLedger.returnPct', () {
    test('평가액이 초기 자본과 같으면 수익률은 0', () {
      expect(TradeLedger.returnPct(10000, 10000), 0);
    });

    test('평가액이 초기 자본의 1.5배면 수익률은 50%', () {
      expect(TradeLedger.returnPct(15000, 10000), 50);
    });

    test('평가액이 초기 자본의 절반이면 수익률은 -50%', () {
      expect(TradeLedger.returnPct(5000, 10000), -50);
    });
  });
}
