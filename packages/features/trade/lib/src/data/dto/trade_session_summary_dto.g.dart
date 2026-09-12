// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_session_summary_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeSessionSummaryDto _$TradeSessionSummaryDtoFromJson(
  Map<String, dynamic> json,
) => TradeSessionSummaryDto(
  id: json['id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  finishedAt: json['finished_at'] == null
      ? null
      : DateTime.parse(json['finished_at'] as String),
  step: (json['step'] as num).toInt(),
  revealedSymbol: json['revealed_symbol'] as String?,
  revealedStartDay: json['revealed_start_day'] == null
      ? null
      : DateTime.parse(json['revealed_start_day'] as String),
  revealedEndDay: json['revealed_end_day'] == null
      ? null
      : DateTime.parse(json['revealed_end_day'] as String),
  finalEquity: (json['final_equity'] as num?)?.toDouble(),
  returnPct: (json['return_pct'] as num?)?.toDouble(),
  buyHoldReturnPct: (json['buy_hold_return_pct'] as num?)?.toDouble(),
  maxDrawdownPct: (json['max_drawdown_pct'] as num?)?.toDouble(),
  tradeCount: (json['trade_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$TradeSessionSummaryDtoToJson(
  TradeSessionSummaryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'created_at': instance.createdAt.toIso8601String(),
  'finished_at': instance.finishedAt?.toIso8601String(),
  'step': instance.step,
  'revealed_symbol': instance.revealedSymbol,
  'revealed_start_day': instance.revealedStartDay?.toIso8601String(),
  'revealed_end_day': instance.revealedEndDay?.toIso8601String(),
  'final_equity': instance.finalEquity,
  'return_pct': instance.returnPct,
  'buy_hold_return_pct': instance.buyHoldReturnPct,
  'max_drawdown_pct': instance.maxDrawdownPct,
  'trade_count': instance.tradeCount,
};
