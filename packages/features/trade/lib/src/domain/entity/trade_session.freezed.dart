// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TradeSession {

 String get id; String get userId; int get step; double get cash; double get quantity; bool get isFinished; List<TradeCandle> get candles; List<TradeOrder> get orders; TradeResult? get result;
/// Create a copy of TradeSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeSessionCopyWith<TradeSession> get copyWith => _$TradeSessionCopyWithImpl<TradeSession>(this as TradeSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.step, step) || other.step == step)&&(identical(other.cash, cash) || other.cash == cash)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.isFinished, isFinished) || other.isFinished == isFinished)&&const DeepCollectionEquality().equals(other.candles, candles)&&const DeepCollectionEquality().equals(other.orders, orders)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,step,cash,quantity,isFinished,const DeepCollectionEquality().hash(candles),const DeepCollectionEquality().hash(orders),result);

@override
String toString() {
  return 'TradeSession(id: $id, userId: $userId, step: $step, cash: $cash, quantity: $quantity, isFinished: $isFinished, candles: $candles, orders: $orders, result: $result)';
}


}

/// @nodoc
abstract mixin class $TradeSessionCopyWith<$Res>  {
  factory $TradeSessionCopyWith(TradeSession value, $Res Function(TradeSession) _then) = _$TradeSessionCopyWithImpl;
@useResult
$Res call({
 String id, String userId, int step, double cash, double quantity, bool isFinished, List<TradeCandle> candles, List<TradeOrder> orders, TradeResult? result
});




}
/// @nodoc
class _$TradeSessionCopyWithImpl<$Res>
    implements $TradeSessionCopyWith<$Res> {
  _$TradeSessionCopyWithImpl(this._self, this._then);

  final TradeSession _self;
  final $Res Function(TradeSession) _then;

/// Create a copy of TradeSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? step = null,Object? cash = null,Object? quantity = null,Object? isFinished = null,Object? candles = null,Object? orders = null,Object? result = freezed,}) {
  return _then(TradeSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,cash: null == cash ? _self.cash : cash // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,isFinished: null == isFinished ? _self.isFinished : isFinished // ignore: cast_nullable_to_non_nullable
as bool,candles: null == candles ? _self.candles : candles // ignore: cast_nullable_to_non_nullable
as List<TradeCandle>,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<TradeOrder>,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TradeResult?,
  ));
}

}


/// Adds pattern-matching-related methods to [TradeSession].
extension TradeSessionPatterns on TradeSession {
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
