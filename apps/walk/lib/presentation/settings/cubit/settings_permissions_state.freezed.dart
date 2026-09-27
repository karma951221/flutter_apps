// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_permissions_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsPermissionsState {

 PermissionStatus? get notification; PermissionStatus? get exactAlarm; PermissionStatus? get fullScreenIntent; HealthAccess? get health;
/// Create a copy of SettingsPermissionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsPermissionsStateCopyWith<SettingsPermissionsState> get copyWith => _$SettingsPermissionsStateCopyWithImpl<SettingsPermissionsState>(this as SettingsPermissionsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsPermissionsState&&(identical(other.notification, notification) || other.notification == notification)&&(identical(other.exactAlarm, exactAlarm) || other.exactAlarm == exactAlarm)&&(identical(other.fullScreenIntent, fullScreenIntent) || other.fullScreenIntent == fullScreenIntent)&&(identical(other.health, health) || other.health == health));
}


@override
int get hashCode => Object.hash(runtimeType,notification,exactAlarm,fullScreenIntent,health);

@override
String toString() {
  return 'SettingsPermissionsState(notification: $notification, exactAlarm: $exactAlarm, fullScreenIntent: $fullScreenIntent, health: $health)';
}


}

/// @nodoc
abstract mixin class $SettingsPermissionsStateCopyWith<$Res>  {
  factory $SettingsPermissionsStateCopyWith(SettingsPermissionsState value, $Res Function(SettingsPermissionsState) _then) = _$SettingsPermissionsStateCopyWithImpl;
@useResult
$Res call({
 PermissionStatus? notification, PermissionStatus? exactAlarm, PermissionStatus? fullScreenIntent, HealthAccess? health
});




}
/// @nodoc
class _$SettingsPermissionsStateCopyWithImpl<$Res>
    implements $SettingsPermissionsStateCopyWith<$Res> {
  _$SettingsPermissionsStateCopyWithImpl(this._self, this._then);

  final SettingsPermissionsState _self;
  final $Res Function(SettingsPermissionsState) _then;

/// Create a copy of SettingsPermissionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notification = freezed,Object? exactAlarm = freezed,Object? fullScreenIntent = freezed,Object? health = freezed,}) {
  return _then(SettingsPermissionsState(
notification: freezed == notification ? _self.notification : notification // ignore: cast_nullable_to_non_nullable
as PermissionStatus?,exactAlarm: freezed == exactAlarm ? _self.exactAlarm : exactAlarm // ignore: cast_nullable_to_non_nullable
as PermissionStatus?,fullScreenIntent: freezed == fullScreenIntent ? _self.fullScreenIntent : fullScreenIntent // ignore: cast_nullable_to_non_nullable
as PermissionStatus?,health: freezed == health ? _self.health : health // ignore: cast_nullable_to_non_nullable
as HealthAccess?,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsPermissionsState].
extension SettingsPermissionsStatePatterns on SettingsPermissionsState {
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
