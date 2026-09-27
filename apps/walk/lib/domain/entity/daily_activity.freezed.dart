// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyActivity {

 DateTime get date; int get steps; double? get distanceMeters; double? get activeKcal;
/// Create a copy of DailyActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyActivityCopyWith<DailyActivity> get copyWith => _$DailyActivityCopyWithImpl<DailyActivity>(this as DailyActivity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyActivity&&(identical(other.date, date) || other.date == date)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.activeKcal, activeKcal) || other.activeKcal == activeKcal));
}


@override
int get hashCode => Object.hash(runtimeType,date,steps,distanceMeters,activeKcal);

@override
String toString() {
  return 'DailyActivity(date: $date, steps: $steps, distanceMeters: $distanceMeters, activeKcal: $activeKcal)';
}


}

/// @nodoc
abstract mixin class $DailyActivityCopyWith<$Res>  {
  factory $DailyActivityCopyWith(DailyActivity value, $Res Function(DailyActivity) _then) = _$DailyActivityCopyWithImpl;
@useResult
$Res call({
 DateTime date, int steps, double? distanceMeters, double? activeKcal
});




}
/// @nodoc
class _$DailyActivityCopyWithImpl<$Res>
    implements $DailyActivityCopyWith<$Res> {
  _$DailyActivityCopyWithImpl(this._self, this._then);

  final DailyActivity _self;
  final $Res Function(DailyActivity) _then;

/// Create a copy of DailyActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? steps = null,Object? distanceMeters = freezed,Object? activeKcal = freezed,}) {
  return _then(DailyActivity(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int,distanceMeters: freezed == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double?,activeKcal: freezed == activeKcal ? _self.activeKcal : activeKcal // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyActivity].
extension DailyActivityPatterns on DailyActivity {
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
