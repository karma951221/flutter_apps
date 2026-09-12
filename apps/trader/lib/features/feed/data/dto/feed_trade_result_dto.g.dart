// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_trade_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedTradeResultDto _$FeedTradeResultDtoFromJson(Map<String, dynamic> json) =>
    FeedTradeResultDto(
      sessionId: json['session_id'] as String,
      symbol: json['symbol'] as String,
      startDay: DateTime.parse(json['start_day'] as String),
      endDay: DateTime.parse(json['end_day'] as String),
      returnPct: (json['return_pct'] as num).toDouble(),
      buyHoldReturnPct: (json['buy_hold_return_pct'] as num).toDouble(),
      maxDrawdownPct: (json['max_drawdown_pct'] as num).toDouble(),
      tradeCount: (json['trade_count'] as num).toInt(),
    );

Map<String, dynamic> _$FeedTradeResultDtoToJson(FeedTradeResultDto instance) =>
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
