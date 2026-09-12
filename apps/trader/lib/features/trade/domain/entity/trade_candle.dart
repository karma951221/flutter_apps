import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_candle.freezed.dart';

/// 정규화된 봉 하나.
///
/// 원가격은 판이 끝나기 전엔 어떤 경로로도 내려오지 않는다 — 여기 담긴
/// open/high/low/close 는 index 59(워밍업 마지막 봉)의 원종가를 100 으로
/// 맞춘 값이다.
@freezed
class TradeCandle with _$TradeCandle {
  @override
  final int index;
  @override
  final double open;
  @override
  final double high;
  @override
  final double low;
  @override
  final double close;

  const TradeCandle({
    required this.index,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}
