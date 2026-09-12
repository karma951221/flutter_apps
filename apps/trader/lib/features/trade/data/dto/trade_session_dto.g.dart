// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_session_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeSessionDto _$TradeSessionDtoFromJson(Map<String, dynamic> json) =>
    TradeSessionDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      step: (json['step'] as num).toInt(),
      cash: (json['cash'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      isFinished: json['finished'] as bool,
      candles:
          (json['candles'] as List<dynamic>?)
              ?.map((e) => TradeCandleDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      orders:
          (json['orders'] as List<dynamic>?)
              ?.map((e) => TradeOrderDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      result: json['result'] == null
          ? null
          : TradeResultDto.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TradeSessionDtoToJson(TradeSessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'step': instance.step,
      'cash': instance.cash,
      'quantity': instance.quantity,
      'finished': instance.isFinished,
      'candles': instance.candles,
      'orders': instance.orders,
      'result': instance.result,
    };
