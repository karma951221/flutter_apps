// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_records.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkRecords {

 int get currentStreakDays; int get longestStreakDays; Walk? get farthest; Walk? get longest;
/// Create a copy of WalkRecords
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkRecordsCopyWith<WalkRecords> get copyWith => _$WalkRecordsCopyWithImpl<WalkRecords>(this as WalkRecords, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkRecords&&(identical(other.currentStreakDays, currentStreakDays) || other.currentStreakDays == currentStreakDays)&&(identical(other.longestStreakDays, longestStreakDays) || other.longestStreakDays == longestStreakDays)&&(identical(other.farthest, farthest) || other.farthest == farthest)&&(identical(other.longest, longest) || other.longest == longest));
}


@override
int get hashCode => Object.hash(runtimeType,currentStreakDays,longestStreakDays,farthest,longest);

@override
String toString() {
  return 'WalkRecords(currentStreakDays: $currentStreakDays, longestStreakDays: $longestStreakDays, farthest: $farthest, longest: $longest)';
}


}

/// @nodoc
abstract mixin class $WalkRecordsCopyWith<$Res>  {
  factory $WalkRecordsCopyWith(WalkRecords value, $Res Function(WalkRecords) _then) = _$WalkRecordsCopyWithImpl;
@useResult
$Res call({
 int currentStreakDays, int longestStreakDays, Walk? farthest, Walk? longest
});




}
/// @nodoc
class _$WalkRecordsCopyWithImpl<$Res>
    implements $WalkRecordsCopyWith<$Res> {
  _$WalkRecordsCopyWithImpl(this._self, this._then);

  final WalkRecords _self;
  final $Res Function(WalkRecords) _then;

/// Create a copy of WalkRecords
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStreakDays = null,Object? longestStreakDays = null,Object? farthest = freezed,Object? longest = freezed,}) {
  return _then(WalkRecords(
currentStreakDays: null == currentStreakDays ? _self.currentStreakDays : currentStreakDays // ignore: cast_nullable_to_non_nullable
as int,longestStreakDays: null == longestStreakDays ? _self.longestStreakDays : longestStreakDays // ignore: cast_nullable_to_non_nullable
as int,farthest: freezed == farthest ? _self.farthest : farthest // ignore: cast_nullable_to_non_nullable
as Walk?,longest: freezed == longest ? _self.longest : longest // ignore: cast_nullable_to_non_nullable
as Walk?,
  ));
}

}


/// Adds pattern-matching-related methods to [WalkRecords].
extension WalkRecordsPatterns on WalkRecords {
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
