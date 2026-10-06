// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'holiday_settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HolidaySettingsState {

 bool get holidayReminder; HolidaySource? get source; PermissionStatus? get calendar;
/// Create a copy of HolidaySettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HolidaySettingsStateCopyWith<HolidaySettingsState> get copyWith => _$HolidaySettingsStateCopyWithImpl<HolidaySettingsState>(this as HolidaySettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HolidaySettingsState&&(identical(other.holidayReminder, holidayReminder) || other.holidayReminder == holidayReminder)&&(identical(other.source, source) || other.source == source)&&(identical(other.calendar, calendar) || other.calendar == calendar));
}


@override
int get hashCode => Object.hash(runtimeType,holidayReminder,source,calendar);

@override
String toString() {
  return 'HolidaySettingsState(holidayReminder: $holidayReminder, source: $source, calendar: $calendar)';
}


}

/// @nodoc
abstract mixin class $HolidaySettingsStateCopyWith<$Res>  {
  factory $HolidaySettingsStateCopyWith(HolidaySettingsState value, $Res Function(HolidaySettingsState) _then) = _$HolidaySettingsStateCopyWithImpl;
@useResult
$Res call({
 bool holidayReminder, HolidaySource? source, PermissionStatus? calendar
});




}
/// @nodoc
class _$HolidaySettingsStateCopyWithImpl<$Res>
    implements $HolidaySettingsStateCopyWith<$Res> {
  _$HolidaySettingsStateCopyWithImpl(this._self, this._then);

  final HolidaySettingsState _self;
  final $Res Function(HolidaySettingsState) _then;

/// Create a copy of HolidaySettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? holidayReminder = null,Object? source = freezed,Object? calendar = freezed,}) {
  return _then(HolidaySettingsState(
holidayReminder: null == holidayReminder ? _self.holidayReminder : holidayReminder // ignore: cast_nullable_to_non_nullable
as bool,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as HolidaySource?,calendar: freezed == calendar ? _self.calendar : calendar // ignore: cast_nullable_to_non_nullable
as PermissionStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [HolidaySettingsState].
extension HolidaySettingsStatePatterns on HolidaySettingsState {
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
