// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_session_summary_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TradeSessionSummaryDto {

 String get id; DateTime get createdAt; DateTime? get finishedAt; int get step; String? get revealedSymbol; DateTime? get revealedStartDay; DateTime? get revealedEndDay; double? get finalEquity; double? get returnPct; double? get buyHoldReturnPct; double? get maxDrawdownPct; int? get tradeCount;
/// Create a copy of TradeSessionSummaryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeSessionSummaryDtoCopyWith<TradeSessionSummaryDto> get copyWith => _$TradeSessionSummaryDtoCopyWithImpl<TradeSessionSummaryDto>(this as TradeSessionSummaryDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeSessionSummaryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.step, step) || other.step == step)&&(identical(other.revealedSymbol, revealedSymbol) || other.revealedSymbol == revealedSymbol)&&(identical(other.revealedStartDay, revealedStartDay) || other.revealedStartDay == revealedStartDay)&&(identical(other.revealedEndDay, revealedEndDay) || other.revealedEndDay == revealedEndDay)&&(identical(other.finalEquity, finalEquity) || other.finalEquity == finalEquity)&&(identical(other.returnPct, returnPct) || other.returnPct == returnPct)&&(identical(other.buyHoldReturnPct, buyHoldReturnPct) || other.buyHoldReturnPct == buyHoldReturnPct)&&(identical(other.maxDrawdownPct, maxDrawdownPct) || other.maxDrawdownPct == maxDrawdownPct)&&(identical(other.tradeCount, tradeCount) || other.tradeCount == tradeCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,createdAt,finishedAt,step,revealedSymbol,revealedStartDay,revealedEndDay,finalEquity,returnPct,buyHoldReturnPct,maxDrawdownPct,tradeCount);

@override
String toString() {
  return 'TradeSessionSummaryDto(id: $id, createdAt: $createdAt, finishedAt: $finishedAt, step: $step, revealedSymbol: $revealedSymbol, revealedStartDay: $revealedStartDay, revealedEndDay: $revealedEndDay, finalEquity: $finalEquity, returnPct: $returnPct, buyHoldReturnPct: $buyHoldReturnPct, maxDrawdownPct: $maxDrawdownPct, tradeCount: $tradeCount)';
}


}

/// @nodoc
abstract mixin class $TradeSessionSummaryDtoCopyWith<$Res>  {
  factory $TradeSessionSummaryDtoCopyWith(TradeSessionSummaryDto value, $Res Function(TradeSessionSummaryDto) _then) = _$TradeSessionSummaryDtoCopyWithImpl;
@useResult
$Res call({
 String id, DateTime createdAt, DateTime? finishedAt, int step, String? revealedSymbol, DateTime? revealedStartDay, DateTime? revealedEndDay, double? finalEquity, double? returnPct, double? buyHoldReturnPct, double? maxDrawdownPct, int? tradeCount
});




}
/// @nodoc
class _$TradeSessionSummaryDtoCopyWithImpl<$Res>
    implements $TradeSessionSummaryDtoCopyWith<$Res> {
  _$TradeSessionSummaryDtoCopyWithImpl(this._self, this._then);

  final TradeSessionSummaryDto _self;
  final $Res Function(TradeSessionSummaryDto) _then;

/// Create a copy of TradeSessionSummaryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? finishedAt = freezed,Object? step = null,Object? revealedSymbol = freezed,Object? revealedStartDay = freezed,Object? revealedEndDay = freezed,Object? finalEquity = freezed,Object? returnPct = freezed,Object? buyHoldReturnPct = freezed,Object? maxDrawdownPct = freezed,Object? tradeCount = freezed,}) {
  return _then(TradeSessionSummaryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,revealedSymbol: freezed == revealedSymbol ? _self.revealedSymbol : revealedSymbol // ignore: cast_nullable_to_non_nullable
as String?,revealedStartDay: freezed == revealedStartDay ? _self.revealedStartDay : revealedStartDay // ignore: cast_nullable_to_non_nullable
as DateTime?,revealedEndDay: freezed == revealedEndDay ? _self.revealedEndDay : revealedEndDay // ignore: cast_nullable_to_non_nullable
as DateTime?,finalEquity: freezed == finalEquity ? _self.finalEquity : finalEquity // ignore: cast_nullable_to_non_nullable
as double?,returnPct: freezed == returnPct ? _self.returnPct : returnPct // ignore: cast_nullable_to_non_nullable
as double?,buyHoldReturnPct: freezed == buyHoldReturnPct ? _self.buyHoldReturnPct : buyHoldReturnPct // ignore: cast_nullable_to_non_nullable
as double?,maxDrawdownPct: freezed == maxDrawdownPct ? _self.maxDrawdownPct : maxDrawdownPct // ignore: cast_nullable_to_non_nullable
as double?,tradeCount: freezed == tradeCount ? _self.tradeCount : tradeCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TradeSessionSummaryDto].
extension TradeSessionSummaryDtoPatterns on TradeSessionSummaryDto {
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
