// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TradeResult {

 String get symbol; DateTime get startDay; DateTime get endDay; int get endIndex; double get finalEquity; double get returnPct; double get buyHoldReturnPct; double get maxDrawdownPct; int get tradeCount;
/// Create a copy of TradeResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeResultCopyWith<TradeResult> get copyWith => _$TradeResultCopyWithImpl<TradeResult>(this as TradeResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeResult&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.startDay, startDay) || other.startDay == startDay)&&(identical(other.endDay, endDay) || other.endDay == endDay)&&(identical(other.endIndex, endIndex) || other.endIndex == endIndex)&&(identical(other.finalEquity, finalEquity) || other.finalEquity == finalEquity)&&(identical(other.returnPct, returnPct) || other.returnPct == returnPct)&&(identical(other.buyHoldReturnPct, buyHoldReturnPct) || other.buyHoldReturnPct == buyHoldReturnPct)&&(identical(other.maxDrawdownPct, maxDrawdownPct) || other.maxDrawdownPct == maxDrawdownPct)&&(identical(other.tradeCount, tradeCount) || other.tradeCount == tradeCount));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,startDay,endDay,endIndex,finalEquity,returnPct,buyHoldReturnPct,maxDrawdownPct,tradeCount);

@override
String toString() {
  return 'TradeResult(symbol: $symbol, startDay: $startDay, endDay: $endDay, endIndex: $endIndex, finalEquity: $finalEquity, returnPct: $returnPct, buyHoldReturnPct: $buyHoldReturnPct, maxDrawdownPct: $maxDrawdownPct, tradeCount: $tradeCount)';
}


}

/// @nodoc
abstract mixin class $TradeResultCopyWith<$Res>  {
  factory $TradeResultCopyWith(TradeResult value, $Res Function(TradeResult) _then) = _$TradeResultCopyWithImpl;
@useResult
$Res call({
 String symbol, DateTime startDay, DateTime endDay, int endIndex, double finalEquity, double returnPct, double buyHoldReturnPct, double maxDrawdownPct, int tradeCount
});




}
/// @nodoc
class _$TradeResultCopyWithImpl<$Res>
    implements $TradeResultCopyWith<$Res> {
  _$TradeResultCopyWithImpl(this._self, this._then);

  final TradeResult _self;
  final $Res Function(TradeResult) _then;

/// Create a copy of TradeResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? startDay = null,Object? endDay = null,Object? endIndex = null,Object? finalEquity = null,Object? returnPct = null,Object? buyHoldReturnPct = null,Object? maxDrawdownPct = null,Object? tradeCount = null,}) {
  return _then(TradeResult(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,startDay: null == startDay ? _self.startDay : startDay // ignore: cast_nullable_to_non_nullable
as DateTime,endDay: null == endDay ? _self.endDay : endDay // ignore: cast_nullable_to_non_nullable
as DateTime,endIndex: null == endIndex ? _self.endIndex : endIndex // ignore: cast_nullable_to_non_nullable
as int,finalEquity: null == finalEquity ? _self.finalEquity : finalEquity // ignore: cast_nullable_to_non_nullable
as double,returnPct: null == returnPct ? _self.returnPct : returnPct // ignore: cast_nullable_to_non_nullable
as double,buyHoldReturnPct: null == buyHoldReturnPct ? _self.buyHoldReturnPct : buyHoldReturnPct // ignore: cast_nullable_to_non_nullable
as double,maxDrawdownPct: null == maxDrawdownPct ? _self.maxDrawdownPct : maxDrawdownPct // ignore: cast_nullable_to_non_nullable
as double,tradeCount: null == tradeCount ? _self.tradeCount : tradeCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TradeResult].
extension TradeResultPatterns on TradeResult {
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
