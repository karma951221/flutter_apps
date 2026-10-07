// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ring_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RingLogGroup {

 int get packageId; Alarm? get alarm; DateTime get at; DateTime? get rangAt; int get snoozes; RingLogKind? get end; DateTime? get endedAt; bool get skipped;
/// Create a copy of RingLogGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RingLogGroupCopyWith<RingLogGroup> get copyWith => _$RingLogGroupCopyWithImpl<RingLogGroup>(this as RingLogGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RingLogGroup&&(identical(other.packageId, packageId) || other.packageId == packageId)&&(identical(other.alarm, alarm) || other.alarm == alarm)&&(identical(other.at, at) || other.at == at)&&(identical(other.rangAt, rangAt) || other.rangAt == rangAt)&&(identical(other.snoozes, snoozes) || other.snoozes == snoozes)&&(identical(other.end, end) || other.end == end)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.skipped, skipped) || other.skipped == skipped));
}


@override
int get hashCode => Object.hash(runtimeType,packageId,alarm,at,rangAt,snoozes,end,endedAt,skipped);

@override
String toString() {
  return 'RingLogGroup(packageId: $packageId, alarm: $alarm, at: $at, rangAt: $rangAt, snoozes: $snoozes, end: $end, endedAt: $endedAt, skipped: $skipped)';
}


}

/// @nodoc
abstract mixin class $RingLogGroupCopyWith<$Res>  {
  factory $RingLogGroupCopyWith(RingLogGroup value, $Res Function(RingLogGroup) _then) = _$RingLogGroupCopyWithImpl;
@useResult
$Res call({
 int packageId, Alarm? alarm, DateTime at, DateTime? rangAt, int snoozes, RingLogKind? end, DateTime? endedAt, bool skipped
});




}
/// @nodoc
class _$RingLogGroupCopyWithImpl<$Res>
    implements $RingLogGroupCopyWith<$Res> {
  _$RingLogGroupCopyWithImpl(this._self, this._then);

  final RingLogGroup _self;
  final $Res Function(RingLogGroup) _then;

/// Create a copy of RingLogGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? packageId = null,Object? alarm = freezed,Object? at = null,Object? rangAt = freezed,Object? snoozes = null,Object? end = freezed,Object? endedAt = freezed,Object? skipped = null,}) {
  return _then(RingLogGroup(
packageId: null == packageId ? _self.packageId : packageId // ignore: cast_nullable_to_non_nullable
as int,alarm: freezed == alarm ? _self.alarm : alarm // ignore: cast_nullable_to_non_nullable
as Alarm?,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,rangAt: freezed == rangAt ? _self.rangAt : rangAt // ignore: cast_nullable_to_non_nullable
as DateTime?,snoozes: null == snoozes ? _self.snoozes : snoozes // ignore: cast_nullable_to_non_nullable
as int,end: freezed == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as RingLogKind?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RingLogGroup].
extension RingLogGroupPatterns on RingLogGroup {
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
