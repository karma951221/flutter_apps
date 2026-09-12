import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_candle_dto.freezed.dart';
part 'trade_candle_dto.g.dart';

/// `trade_session_state()` 가 내려주는 봉 하나(`{i, o, h, l, c}`)의 전송 형식.
///
/// 숫자는 jsonb number 로 온다 — 정수로 떨어져도(`o: 100`) json_serializable 이
/// `(x as num).toDouble()` 로 받으므로 double 필드로 안전하다.
@freezed
@JsonSerializable()
class TradeCandleDto with _$TradeCandleDto {
  const TradeCandleDto({
    required this.index,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  @override
  @JsonKey(name: 'i')
  final int index;
  @override
  @JsonKey(name: 'o')
  final double open;
  @override
  @JsonKey(name: 'h')
  final double high;
  @override
  @JsonKey(name: 'l')
  final double low;
  @override
  @JsonKey(name: 'c')
  final double close;

  factory TradeCandleDto.fromJson(Map<String, dynamic> json) =>
      _$TradeCandleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TradeCandleDtoToJson(this);
}
