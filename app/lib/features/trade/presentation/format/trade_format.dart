import 'package:intl/intl.dart';

import '../../domain/entity/trade_result.dart';

/// 모의투자 화면의 숫자·날짜 표기.
///
/// 수익률·평가액·기간은 홈 · 결과 · (나중에) 공유 카드가 같은 모양으로
/// 보여줘야 한다. 화면마다 `toStringAsFixed` 를 따로 부르면 부호나 자릿수가
/// 조금씩 어긋나므로 한곳에 모은다.
abstract final class TradeFormat {
  /// 빼기 부호(U+2212). 하이픈(`-`)보다 숫자 옆에서 폭과 높이가 맞는다.
  static const minusSign = '−';

  /// 부호를 붙인 퍼센트. `+12.34%` · `−5.10%`, 0 은 부호 없이 `0.00%`.
  ///
  /// 0 에 부호를 붙이지 않는 이유는 `+0.00%` 가 "조금 벌었다"로 읽히기
  /// 때문이다. 반올림해서 0 이 된 값도 같이 부호를 잃는다 — 그 자리에서
  /// 방향을 말할 만큼의 차이가 아니다.
  static String signedPct(double value) {
    final magnitude = value.abs().toStringAsFixed(2);
    if (magnitude == '0.00') return '0.00%';
    return '${value < 0 ? minusSign : '+'}$magnitude%';
  }

  /// 부호 없는 퍼센트. 방향을 문장이 이미 말하는 자리(보유 대비 차이)에 쓴다.
  static String pct(double value) => '${value.toStringAsFixed(2)}%';

  /// 금액. 로케일의 천 단위 구분과 소수 두 자리로 찍는다.
  static String amount(double value, String locale) =>
      NumberFormat('#,##0.00', locale).format(value);

  /// 판이 다룬 기간. `2021-11-01 ~ 2022-01-29`.
  ///
  /// 로컬 시간대로 옮기지 않는다. 여기 오는 값은 순간이 아니라 달력의
  /// 날짜라서, 시간대를 적용하면 하루가 밀린다.
  static String dayRange(DateTime start, DateTime end) =>
      '${_day.format(start)} ~ ${_day.format(end)}';

  /// 종목 표기. `BTCUSDT` → `BTC`.
  ///
  /// 규칙의 정본은 도메인([TradeResult.displaySymbolOf])이다. 화면이 결과
  /// entity 없이 심볼 문자열만 들고 있을 때를 위한 통로다.
  static String symbolLabel(String symbol) =>
      TradeResult.displaySymbolOf(symbol);

  static final _day = DateFormat('yyyy-MM-dd');
}
