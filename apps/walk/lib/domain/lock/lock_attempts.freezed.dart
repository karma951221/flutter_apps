// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lock_attempts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LockAttempts {

 int get failures; DateTime? get blockedUntil; bool get longBlock;
/// Create a copy of LockAttempts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LockAttemptsCopyWith<LockAttempts> get copyWith => _$LockAttemptsCopyWithImpl<LockAttempts>(this as LockAttempts, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LockAttempts&&(identical(other.failures, failures) || other.failures == failures)&&(identical(other.blockedUntil, blockedUntil) || other.blockedUntil == blockedUntil)&&(identical(other.longBlock, longBlock) || other.longBlock == longBlock));
}


@override
int get hashCode => Object.hash(runtimeType,failures,blockedUntil,longBlock);

@override
String toString() {
  return 'LockAttempts(failures: $failures, blockedUntil: $blockedUntil, longBlock: $longBlock)';
}


}

/// @nodoc
abstract mixin class $LockAttemptsCopyWith<$Res>  {
  factory $LockAttemptsCopyWith(LockAttempts value, $Res Function(LockAttempts) _then) = _$LockAttemptsCopyWithImpl;
@useResult
$Res call({
 int failures, DateTime? blockedUntil, bool longBlock
});




}
/// @nodoc
class _$LockAttemptsCopyWithImpl<$Res>
    implements $LockAttemptsCopyWith<$Res> {
  _$LockAttemptsCopyWithImpl(this._self, this._then);

  final LockAttempts _self;
  final $Res Function(LockAttempts) _then;

/// Create a copy of LockAttempts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? failures = null,Object? blockedUntil = freezed,Object? longBlock = null,}) {
  return _then(LockAttempts(
failures: null == failures ? _self.failures : failures // ignore: cast_nullable_to_non_nullable
as int,blockedUntil: freezed == blockedUntil ? _self.blockedUntil : blockedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,longBlock: null == longBlock ? _self.longBlock : longBlock // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LockAttempts].
extension LockAttemptsPatterns on LockAttempts {
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
