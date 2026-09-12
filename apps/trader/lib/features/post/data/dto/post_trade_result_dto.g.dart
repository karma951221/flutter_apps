// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_trade_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostTradeResultDto _$PostTradeResultDtoFromJson(Map<String, dynamic> json) =>
    PostTradeResultDto(
      sessionId: json['session_id'] as String,
      symbol: json['symbol'] as String,
      startDay: DateTime.parse(json['start_day'] as String),
      endDay: DateTime.parse(json['end_day'] as String),
      returnPct: (json['return_pct'] as num).toDouble(),
      buyHoldReturnPct: (json['buy_hold_return_pct'] as num).toDouble(),
      maxDrawdownPct: (json['max_drawdown_pct'] as num).toDouble(),
      tradeCount: (json['trade_count'] as num).toInt(),
    );

Map<String, dynamic> _$PostTradeResultDtoToJson(PostTradeResultDto instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'symbol': instance.symbol,
      'start_day': instance.startDay.toIso8601String(),
      'end_day': instance.endDay.toIso8601String(),
      'return_pct': instance.returnPct,
      'buy_hold_return_pct': instance.buyHoldReturnPct,
      'max_drawdown_pct': instance.maxDrawdownPct,
      'trade_count': instance.tradeCount,
    };
