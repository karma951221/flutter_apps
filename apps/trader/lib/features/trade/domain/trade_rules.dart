/// F10 모의투자 판의 규칙 상수.
///
/// 서버(RPC)가 정본이다 — 여기 상수는 화면 구성과 표시용 계산에 쓰는
/// 사본이고, 실제 매매 가능 여부·잔고 검증은 항상 서버가 최종 판단한다.
abstract final class TradeRules {
  /// 봉 index 0..59, 워밍업 구간. 보이기만 하고 매매할 수 없다.
  static const warmupCandles = 60;

  /// step 0..59 에서 매매할 수 있다. step 60 은 자동 종료다.
  static const tradeSteps = 60;

  /// 전체 봉 개수, index 0..119.
  static const totalCandles = 120;

  /// 판을 시작할 때의 현금.
  static const initialCash = 10000.0;

  /// 매수·매도 양쪽에 붙는 수수료율(0.1%).
  static const feeRate = 0.001;

  /// step [step] 에서 보이는 마지막(현재) 봉의 index.
  static int indexForStep(int step) => warmupCandles - 1 + step;
}
