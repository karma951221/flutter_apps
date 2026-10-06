// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlarmReminder {

 int get id; int get packageId; int get alarmId; ReminderKind get kind; DateTime get at; DateTime get ringAt; String? get holidayName;
/// Create a copy of AlarmReminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlarmReminderCopyWith<AlarmReminder> get copyWith => _$AlarmReminderCopyWithImpl<AlarmReminder>(this as AlarmReminder, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmReminder&&(identical(other.id, id) || other.id == id)&&(identical(other.packageId, packageId) || other.packageId == packageId)&&(identical(other.alarmId, alarmId) || other.alarmId == alarmId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.at, at) || other.at == at)&&(identical(other.ringAt, ringAt) || other.ringAt == ringAt)&&(identical(other.holidayName, holidayName) || other.holidayName == holidayName));
}


@override
int get hashCode => Object.hash(runtimeType,id,packageId,alarmId,kind,at,ringAt,holidayName);

@override
String toString() {
  return 'AlarmReminder(id: $id, packageId: $packageId, alarmId: $alarmId, kind: $kind, at: $at, ringAt: $ringAt, holidayName: $holidayName)';
}


}

/// @nodoc
abstract mixin class $AlarmReminderCopyWith<$Res>  {
  factory $AlarmReminderCopyWith(AlarmReminder value, $Res Function(AlarmReminder) _then) = _$AlarmReminderCopyWithImpl;
@useResult
$Res call({
 int id, int packageId, int alarmId, ReminderKind kind, DateTime at, DateTime ringAt, String? holidayName
});




}
/// @nodoc
class _$AlarmReminderCopyWithImpl<$Res>
    implements $AlarmReminderCopyWith<$Res> {
  _$AlarmReminderCopyWithImpl(this._self, this._then);

  final AlarmReminder _self;
  final $Res Function(AlarmReminder) _then;

/// Create a copy of AlarmReminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? packageId = null,Object? alarmId = null,Object? kind = null,Object? at = null,Object? ringAt = null,Object? holidayName = freezed,}) {
  return _then(AlarmReminder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,packageId: null == packageId ? _self.packageId : packageId // ignore: cast_nullable_to_non_nullable
as int,alarmId: null == alarmId ? _self.alarmId : alarmId // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ReminderKind,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,ringAt: null == ringAt ? _self.ringAt : ringAt // ignore: cast_nullable_to_non_nullable
as DateTime,holidayName: freezed == holidayName ? _self.holidayName : holidayName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AlarmReminder].
extension AlarmReminderPatterns on AlarmReminder {
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
