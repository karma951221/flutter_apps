// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary_settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiarySettingsState {

 LockConfig? get lock; TrashRetention get retention; DiaryUsage? get usage;
/// Create a copy of DiarySettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiarySettingsStateCopyWith<DiarySettingsState> get copyWith => _$DiarySettingsStateCopyWithImpl<DiarySettingsState>(this as DiarySettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiarySettingsState&&(identical(other.lock, lock) || other.lock == lock)&&(identical(other.retention, retention) || other.retention == retention)&&(identical(other.usage, usage) || other.usage == usage));
}


@override
int get hashCode => Object.hash(runtimeType,lock,retention,usage);

@override
String toString() {
  return 'DiarySettingsState(lock: $lock, retention: $retention, usage: $usage)';
}


}

/// @nodoc
abstract mixin class $DiarySettingsStateCopyWith<$Res>  {
  factory $DiarySettingsStateCopyWith(DiarySettingsState value, $Res Function(DiarySettingsState) _then) = _$DiarySettingsStateCopyWithImpl;
@useResult
$Res call({
 LockConfig? lock, TrashRetention retention, DiaryUsage? usage
});




}
/// @nodoc
class _$DiarySettingsStateCopyWithImpl<$Res>
    implements $DiarySettingsStateCopyWith<$Res> {
  _$DiarySettingsStateCopyWithImpl(this._self, this._then);

  final DiarySettingsState _self;
  final $Res Function(DiarySettingsState) _then;

/// Create a copy of DiarySettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lock = freezed,Object? retention = null,Object? usage = freezed,}) {
  return _then(DiarySettingsState(
lock: freezed == lock ? _self.lock : lock // ignore: cast_nullable_to_non_nullable
as LockConfig?,retention: null == retention ? _self.retention : retention // ignore: cast_nullable_to_non_nullable
as TrashRetention,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as DiaryUsage?,
  ));
}

}


/// Adds pattern-matching-related methods to [DiarySettingsState].
extension DiarySettingsStatePatterns on DiarySettingsState {
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
