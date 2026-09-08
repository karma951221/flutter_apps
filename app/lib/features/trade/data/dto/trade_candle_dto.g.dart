// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_candle_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeCandleDto _$TradeCandleDtoFromJson(Map<String, dynamic> json) =>
    TradeCandleDto(
      index: (json['i'] as num).toInt(),
      open: (json['o'] as num).toDouble(),
      high: (json['h'] as num).toDouble(),
      low: (json['l'] as num).toDouble(),
      close: (json['c'] as num).toDouble(),
    );

Map<String, dynamic> _$TradeCandleDtoToJson(TradeCandleDto instance) =>
    <String, dynamic>{
      'i': instance.index,
      'o': instance.open,
      'h': instance.high,
      'l': instance.low,
      'c': instance.close,
    };
