import 'package:freezed_annotation/freezed_annotation.dart';

import 'trade_candle_dto.dart';
import 'trade_order_dto.dart';
import 'trade_result_dto.dart';

part 'trade_session_dto.freezed.dart';
part 'trade_session_dto.g.dart';

/// `get_trade_session` · `place_trade_order` · `advance_trade_session` ·
/// `finish_trade_session` RPC 가 공통으로 돌려주는 `trade_session_state()`
/// jsonb 의 전송 형식.
///
/// 진행 중인 판은 `result` 가 없다(null) — 판이 끝나야만 채워진다.
@freezed
@JsonSerializable()
class TradeSessionDto with _$TradeSessionDto {
  const TradeSessionDto({
    required this.id,
    required this.userId,
    required this.step,
    required this.cash,
    required this.quantity,
    required this.isFinished,
    this.candles = const [],
    this.orders = const [],
    this.result,
  });

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final int step;
  @override
  final double cash;
  @override
  final double quantity;
  @override
  @JsonKey(name: 'finished')
  final bool isFinished;
  @override
  @JsonKey(defaultValue: [])
  final List<TradeCandleDto> candles;
  @override
  @JsonKey(defaultValue: [])
  final List<TradeOrderDto> orders;
  @override
  final TradeResultDto? result;

  factory TradeSessionDto.fromJson(Map<String, dynamic> json) =>
      _$TradeSessionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TradeSessionDtoToJson(this);
}
