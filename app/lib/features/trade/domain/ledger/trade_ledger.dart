/// 표시용 순수 계산 함수 모음.
///
/// 서버(RPC)가 정본이다 — 여기는 화면이 다음 서버 응답을 기다리지 않고
/// 즉시 보여줄 값을 계산한다. 반올림은 호출부(표시 계층)의 몫이다.
abstract final class TradeLedger {
  /// 현금과 보유 수량을 현재가로 평가한 총 자산.
  static double equity(double cash, double quantity, double price) =>
      cash + quantity * price;

  /// 초기 자본 대비 수익률(%).
  static double returnPct(double equity, double initialCash) =>
      (equity / initialCash - 1) * 100;
}
