// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeResultDto _$TradeResultDtoFromJson(Map<String, dynamic> json) =>
    TradeResultDto(
      symbol: json['symbol'] as String,
      startDay: DateTime.parse(json['start_day'] as String),
      endDay: DateTime.parse(json['end_day'] as String),
      endIndex: (json['end_index'] as num).toInt(),
      finalEquity: (json['final_equity'] as num).toDouble(),
      returnPct: (json['return_pct'] as num).toDouble(),
      buyHoldReturnPct: (json['buy_hold_return_pct'] as num).toDouble(),
      maxDrawdownPct: (json['max_drawdown_pct'] as num).toDouble(),
      tradeCount: (json['trade_count'] as num).toInt(),
    );

Map<String, dynamic> _$TradeResultDtoToJson(TradeResultDto instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'start_day': instance.startDay.toIso8601String(),
      'end_day': instance.endDay.toIso8601String(),
      'end_index': instance.endIndex,
      'final_equity': instance.finalEquity,
      'return_pct': instance.returnPct,
      'buy_hold_return_pct': instance.buyHoldReturnPct,
      'max_drawdown_pct': instance.maxDrawdownPct,
      'trade_count': instance.tradeCount,
    };
