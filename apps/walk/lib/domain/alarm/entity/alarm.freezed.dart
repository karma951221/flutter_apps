// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Alarm {

 int get id; int get hour; int get minute; Set<Weekday> get repeat; String get label; bool get silentWhenRingerMuted; AlarmSound get sound; bool get enabled; DateTime? get oneShotAt; int get volumePercent; int get fadeSeconds; int get snoozeMinutes; int? get snoozeLimit; int? get autoStopMinutes; bool get remindBefore; DateTime? get skippedAt;
/// Create a copy of Alarm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlarmCopyWith<Alarm> get copyWith => _$AlarmCopyWithImpl<Alarm>(this as Alarm, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Alarm&&(identical(other.id, id) || other.id == id)&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.minute, minute) || other.minute == minute)&&const DeepCollectionEquality().equals(other.repeat, repeat)&&(identical(other.label, label) || other.label == label)&&(identical(other.silentWhenRingerMuted, silentWhenRingerMuted) || other.silentWhenRingerMuted == silentWhenRingerMuted)&&(identical(other.sound, sound) || other.sound == sound)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.oneShotAt, oneShotAt) || other.oneShotAt == oneShotAt)&&(identical(other.volumePercent, volumePercent) || other.volumePercent == volumePercent)&&(identical(other.fadeSeconds, fadeSeconds) || other.fadeSeconds == fadeSeconds)&&(identical(other.snoozeMinutes, snoozeMinutes) || other.snoozeMinutes == snoozeMinutes)&&(identical(other.snoozeLimit, snoozeLimit) || other.snoozeLimit == snoozeLimit)&&(identical(other.autoStopMinutes, autoStopMinutes) || other.autoStopMinutes == autoStopMinutes)&&(identical(other.remindBefore, remindBefore) || other.remindBefore == remindBefore)&&(identical(other.skippedAt, skippedAt) || other.skippedAt == skippedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,hour,minute,const DeepCollectionEquality().hash(repeat),label,silentWhenRingerMuted,sound,enabled,oneShotAt,volumePercent,fadeSeconds,snoozeMinutes,snoozeLimit,autoStopMinutes,remindBefore,skippedAt);

@override
String toString() {
  return 'Alarm(id: $id, hour: $hour, minute: $minute, repeat: $repeat, label: $label, silentWhenRingerMuted: $silentWhenRingerMuted, sound: $sound, enabled: $enabled, oneShotAt: $oneShotAt, volumePercent: $volumePercent, fadeSeconds: $fadeSeconds, snoozeMinutes: $snoozeMinutes, snoozeLimit: $snoozeLimit, autoStopMinutes: $autoStopMinutes, remindBefore: $remindBefore, skippedAt: $skippedAt)';
}


}

/// @nodoc
abstract mixin class $AlarmCopyWith<$Res>  {
  factory $AlarmCopyWith(Alarm value, $Res Function(Alarm) _then) = _$AlarmCopyWithImpl;
@useResult
$Res call({
 int id, int hour, int minute, Set<Weekday> repeat, String label, bool silentWhenRingerMuted, AlarmSound sound, bool enabled, DateTime? oneShotAt, int volumePercent, int fadeSeconds, int snoozeMinutes, int? snoozeLimit, int? autoStopMinutes, bool remindBefore, DateTime? skippedAt
});




}
/// @nodoc
class _$AlarmCopyWithImpl<$Res>
    implements $AlarmCopyWith<$Res> {
  _$AlarmCopyWithImpl(this._self, this._then);

  final Alarm _self;
  final $Res Function(Alarm) _then;

/// Create a copy of Alarm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? hour = null,Object? minute = null,Object? repeat = null,Object? label = null,Object? silentWhenRingerMuted = null,Object? sound = null,Object? enabled = null,Object? oneShotAt = freezed,Object? volumePercent = null,Object? fadeSeconds = null,Object? snoozeMinutes = null,Object? snoozeLimit = freezed,Object? autoStopMinutes = freezed,Object? remindBefore = null,Object? skippedAt = freezed,}) {
  return _then(Alarm(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as int,minute: null == minute ? _self.minute : minute // ignore: cast_nullable_to_non_nullable
as int,repeat: null == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as Set<Weekday>,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,silentWhenRingerMuted: null == silentWhenRingerMuted ? _self.silentWhenRingerMuted : silentWhenRingerMuted // ignore: cast_nullable_to_non_nullable
as bool,sound: null == sound ? _self.sound : sound // ignore: cast_nullable_to_non_nullable
as AlarmSound,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,oneShotAt: freezed == oneShotAt ? _self.oneShotAt : oneShotAt // ignore: cast_nullable_to_non_nullable
as DateTime?,volumePercent: null == volumePercent ? _self.volumePercent : volumePercent // ignore: cast_nullable_to_non_nullable
as int,fadeSeconds: null == fadeSeconds ? _self.fadeSeconds : fadeSeconds // ignore: cast_nullable_to_non_nullable
as int,snoozeMinutes: null == snoozeMinutes ? _self.snoozeMinutes : snoozeMinutes // ignore: cast_nullable_to_non_nullable
as int,snoozeLimit: freezed == snoozeLimit ? _self.snoozeLimit : snoozeLimit // ignore: cast_nullable_to_non_nullable
as int?,autoStopMinutes: freezed == autoStopMinutes ? _self.autoStopMinutes : autoStopMinutes // ignore: cast_nullable_to_non_nullable
as int?,remindBefore: null == remindBefore ? _self.remindBefore : remindBefore // ignore: cast_nullable_to_non_nullable
as bool,skippedAt: freezed == skippedAt ? _self.skippedAt : skippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Alarm].
extension AlarmPatterns on Alarm {
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
