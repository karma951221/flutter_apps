// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_trade_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeedTradeResultDto {

 String get sessionId; String get symbol; DateTime get startDay; DateTime get endDay; double get returnPct; double get buyHoldReturnPct; double get maxDrawdownPct; int get tradeCount;
/// Create a copy of FeedTradeResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedTradeResultDtoCopyWith<FeedTradeResultDto> get copyWith => _$FeedTradeResultDtoCopyWithImpl<FeedTradeResultDto>(this as FeedTradeResultDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedTradeResultDto&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.startDay, startDay) || other.startDay == startDay)&&(identical(other.endDay, endDay) || other.endDay == endDay)&&(identical(other.returnPct, returnPct) || other.returnPct == returnPct)&&(identical(other.buyHoldReturnPct, buyHoldReturnPct) || other.buyHoldReturnPct == buyHoldReturnPct)&&(identical(other.maxDrawdownPct, maxDrawdownPct) || other.maxDrawdownPct == maxDrawdownPct)&&(identical(other.tradeCount, tradeCount) || other.tradeCount == tradeCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,symbol,startDay,endDay,returnPct,buyHoldReturnPct,maxDrawdownPct,tradeCount);

@override
String toString() {
  return 'FeedTradeResultDto(sessionId: $sessionId, symbol: $symbol, startDay: $startDay, endDay: $endDay, returnPct: $returnPct, buyHoldReturnPct: $buyHoldReturnPct, maxDrawdownPct: $maxDrawdownPct, tradeCount: $tradeCount)';
}


}

/// @nodoc
abstract mixin class $FeedTradeResultDtoCopyWith<$Res>  {
  factory $FeedTradeResultDtoCopyWith(FeedTradeResultDto value, $Res Function(FeedTradeResultDto) _then) = _$FeedTradeResultDtoCopyWithImpl;
@useResult
$Res call({
 String sessionId, String symbol, DateTime startDay, DateTime endDay, double returnPct, double buyHoldReturnPct, double maxDrawdownPct, int tradeCount
});




}
/// @nodoc
class _$FeedTradeResultDtoCopyWithImpl<$Res>
    implements $FeedTradeResultDtoCopyWith<$Res> {
  _$FeedTradeResultDtoCopyWithImpl(this._self, this._then);

  final FeedTradeResultDto _self;
  final $Res Function(FeedTradeResultDto) _then;

/// Create a copy of FeedTradeResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? symbol = null,Object? startDay = null,Object? endDay = null,Object? returnPct = null,Object? buyHoldReturnPct = null,Object? maxDrawdownPct = null,Object? tradeCount = null,}) {
  return _then(FeedTradeResultDto(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,startDay: null == startDay ? _self.startDay : startDay // ignore: cast_nullable_to_non_nullable
as DateTime,endDay: null == endDay ? _self.endDay : endDay // ignore: cast_nullable_to_non_nullable
as DateTime,returnPct: null == returnPct ? _self.returnPct : returnPct // ignore: cast_nullable_to_non_nullable
as double,buyHoldReturnPct: null == buyHoldReturnPct ? _self.buyHoldReturnPct : buyHoldReturnPct // ignore: cast_nullable_to_non_nullable
as double,maxDrawdownPct: null == maxDrawdownPct ? _self.maxDrawdownPct : maxDrawdownPct // ignore: cast_nullable_to_non_nullable
as double,tradeCount: null == tradeCount ? _self.tradeCount : tradeCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedTradeResultDto].
extension FeedTradeResultDtoPatterns on FeedTradeResultDto {
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
