import 'trade_cost.dart';

/// 매매 수량 계산 — 표시용.
///
/// 서버(RPC)가 소수 6자리로 반올림해 정본을 만든다. 여기는 사용자가 버튼을
/// 누르기 전에 화면에 미리 보여줄 값을 같은 규칙으로 미리 계산한다.
abstract final class TradeSizing {
  /// 소수 6자리로 내림한다.
  ///
  /// 이진 부동소수점 오차 때문에 그냥 곱해서 floor 하면 `0.29` 처럼 딱
  /// 떨어져야 할 값이 `0.289999...` 로 밀려 한 단위 아래로 잘릴 수 있다 —
  /// 아주 작은 보정값을 더해 그 오차를 흡수한다.
  ///
  /// `NaN`·`Infinity`(0 으로 나누기 등으로 생길 수 있다)는 유효한 수량이
  /// 아니므로 0 으로 취급한다 — 그대로 두면 `.floor()` 가 예외를 던진다.
  static double floorQuantity(double q) {
    if (!q.isFinite || q <= 0) return 0;
    return ((q * 1e6) + 1e-6).floor() / 1e6;
  }

  /// 현금의 [fraction] 만큼 살 수 있는 수량(25/50/100% 버튼).
  static double buyQuantity({
    required double cash,
    required double price,
    required double feeRate,
    required double fraction,
  }) => floorQuantity(cash * fraction / (price * (1 + feeRate)));

  /// 직접 입력한 금액으로 살 수 있는 수량.
  static double quantityForAmount({
    required double amount,
    required double price,
    required double feeRate,
  }) => floorQuantity(amount / (price * (1 + feeRate)));

  /// 보유 수량의 [fraction] 만큼 파는 수량.
  ///
  /// 100% 는 내림 계산을 거치지 않고 보유량을 그대로 돌려준다 — 전량 매도인데
  /// 부동소수점 내림 오차로 미세하게 덜 파는 값이 나오는 것을 막는다.
  static double sellQuantity({
    required double quantity,
    required double fraction,
  }) => fraction >= 1 ? quantity : floorQuantity(quantity * fraction);

  /// 매수 시 금액 구성.
  static TradeCost buyCost({
    required double quantity,
    required double price,
    required double feeRate,
  }) {
    final amount = quantity * price;
    final fee = amount * feeRate;
    return TradeCost(amount: amount, fee: fee, total: amount + fee);
  }

  /// 매도 시 금액 구성. 수수료는 받는 돈에서 빠진다.
  static TradeCost sellProceeds({
    required double quantity,
    required double price,
    required double feeRate,
  }) {
    final amount = quantity * price;
    final fee = amount * feeRate;
    return TradeCost(amount: amount, fee: fee, total: amount - fee);
  }
}
