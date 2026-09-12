// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeOrderDto _$TradeOrderDtoFromJson(Map<String, dynamic> json) =>
    TradeOrderDto(
      step: (json['step'] as num).toInt(),
      side: json['side'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      fee: (json['fee'] as num).toDouble(),
    );

Map<String, dynamic> _$TradeOrderDtoToJson(TradeOrderDto instance) =>
    <String, dynamic>{
      'step': instance.step,
      'side': instance.side,
      'quantity': instance.quantity,
      'price': instance.price,
      'fee': instance.fee,
    };
