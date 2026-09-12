// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_session_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TradeSessionDto {

 String get id; String get userId; int get step; double get cash; double get quantity; bool get isFinished; List<TradeCandleDto> get candles; List<TradeOrderDto> get orders; TradeResultDto? get result;
/// Create a copy of TradeSessionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeSessionDtoCopyWith<TradeSessionDto> get copyWith => _$TradeSessionDtoCopyWithImpl<TradeSessionDto>(this as TradeSessionDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeSessionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.step, step) || other.step == step)&&(identical(other.cash, cash) || other.cash == cash)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.isFinished, isFinished) || other.isFinished == isFinished)&&const DeepCollectionEquality().equals(other.candles, candles)&&const DeepCollectionEquality().equals(other.orders, orders)&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,step,cash,quantity,isFinished,const DeepCollectionEquality().hash(candles),const DeepCollectionEquality().hash(orders),result);

@override
String toString() {
  return 'TradeSessionDto(id: $id, userId: $userId, step: $step, cash: $cash, quantity: $quantity, isFinished: $isFinished, candles: $candles, orders: $orders, result: $result)';
}


}

/// @nodoc
abstract mixin class $TradeSessionDtoCopyWith<$Res>  {
  factory $TradeSessionDtoCopyWith(TradeSessionDto value, $Res Function(TradeSessionDto) _then) = _$TradeSessionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String userId, int step, double cash, double quantity, bool isFinished, List<TradeCandleDto> candles, List<TradeOrderDto> orders, TradeResultDto? result
});




}
/// @nodoc
class _$TradeSessionDtoCopyWithImpl<$Res>
    implements $TradeSessionDtoCopyWith<$Res> {
  _$TradeSessionDtoCopyWithImpl(this._self, this._then);

  final TradeSessionDto _self;
  final $Res Function(TradeSessionDto) _then;

/// Create a copy of TradeSessionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? step = null,Object? cash = null,Object? quantity = null,Object? isFinished = null,Object? candles = null,Object? orders = null,Object? result = freezed,}) {
  return _then(TradeSessionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,cash: null == cash ? _self.cash : cash // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,isFinished: null == isFinished ? _self.isFinished : isFinished // ignore: cast_nullable_to_non_nullable
as bool,candles: null == candles ? _self.candles : candles // ignore: cast_nullable_to_non_nullable
as List<TradeCandleDto>,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<TradeOrderDto>,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TradeResultDto?,
  ));
}

}


/// Adds pattern-matching-related methods to [TradeSessionDto].
extension TradeSessionDtoPatterns on TradeSessionDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
