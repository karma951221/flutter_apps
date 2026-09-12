/// 매매 방향. 롱만 지원하므로 매수·매도 두 가지뿐이다.
enum TradeSide {
  buy,
  sell;

  /// RPC 로 보내는 문자열 표현. enum 이름과 같다.
  String get wire => name;

  /// RPC 가 돌려준 문자열을 [TradeSide] 로 되돌린다. 모르는 값이면 던진다 —
  /// 서버가 이미 `invalid side` 로 거부했어야 할 값이라 여기까지 오면 버그다.
  static TradeSide fromWire(String value) => values.byName(value);
}
