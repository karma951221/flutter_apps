import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_order_dto.freezed.dart';
part 'trade_order_dto.g.dart';

/// `trade_session_state()` 가 내려주는 체결 주문 하나의 전송 형식.
///
/// `side` 는 `'buy'`/`'sell'` 문자열 그대로 둔다 — `TradeSide` 로의 변환은
/// mapper 의 몫이다(`TradeSide.fromWire`).
@freezed
@JsonSerializable()
class TradeOrderDto with _$TradeOrderDto {
  const TradeOrderDto({
    required this.step,
    required this.side,
    required this.quantity,
    required this.price,
    required this.fee,
  });

  @override
  final int step;
  @override
  final String side;
  @override
  final double quantity;
  @override
  final double price;
  @override
  final double fee;

  factory TradeOrderDto.fromJson(Map<String, dynamic> json) =>
      _$TradeOrderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TradeOrderDtoToJson(this);
}
