import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_result_dto.freezed.dart';
part 'trade_result_dto.g.dart';

/// `trade_session_state()` 가 판이 끝났을 때만 채우는 결과 스냅샷의 전송 형식.
///
/// `start_day`/`end_day` 는 `to_char(..., 'YYYY-MM-DD')` 로 오므로 `DateTime`
/// 필드가 표준 파서로 그대로 받는다.
@freezed
@JsonSerializable()
class TradeResultDto with _$TradeResultDto {
  const TradeResultDto({
    required this.symbol,
    required this.startDay,
    required this.endDay,
    required this.endIndex,
    required this.finalEquity,
    required this.returnPct,
    required this.buyHoldReturnPct,
    required this.maxDrawdownPct,
    required this.tradeCount,
  });

  @override
  final String symbol;
  @override
  @JsonKey(name: 'start_day')
  final DateTime startDay;
  @override
  @JsonKey(name: 'end_day')
  final DateTime endDay;
  @override
  @JsonKey(name: 'end_index')
  final int endIndex;
  @override
  @JsonKey(name: 'final_equity')
  final double finalEquity;
  @override
  @JsonKey(name: 'return_pct')
  final double returnPct;
  @override
  @JsonKey(name: 'buy_hold_return_pct')
  final double buyHoldReturnPct;
  @override
  @JsonKey(name: 'max_drawdown_pct')
  final double maxDrawdownPct;
  @override
  @JsonKey(name: 'trade_count')
  final int tradeCount;

  factory TradeResultDto.fromJson(Map<String, dynamic> json) =>
      _$TradeResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TradeResultDtoToJson(this);
}
