// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_sound.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlarmSound {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmSound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmSound()';
}


}

/// @nodoc
class $AlarmSoundCopyWith<$Res>  {
$AlarmSoundCopyWith(AlarmSound _, $Res Function(AlarmSound) __);
}


/// Adds pattern-matching-related methods to [AlarmSound].
extension AlarmSoundPatterns on AlarmSound {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SystemAlarmSound value)?  system,TResult Function( BundledAlarmSound value)?  bundled,TResult Function( DeviceAlarmSound value)?  device,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SystemAlarmSound() when system != null:
return system(_that);case BundledAlarmSound() when bundled != null:
return bundled(_that);case DeviceAlarmSound() when device != null:
return device(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SystemAlarmSound value)  system,required TResult Function( BundledAlarmSound value)  bundled,required TResult Function( DeviceAlarmSound value)  device,}){
final _that = this;
switch (_that) {
case SystemAlarmSound():
return system(_that);case BundledAlarmSound():
return bundled(_that);case DeviceAlarmSound():
return device(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SystemAlarmSound value)?  system,TResult? Function( BundledAlarmSound value)?  bundled,TResult? Function( DeviceAlarmSound value)?  device,}){
final _that = this;
switch (_that) {
case SystemAlarmSound() when system != null:
return system(_that);case BundledAlarmSound() when bundled != null:
return bundled(_that);case DeviceAlarmSound() when device != null:
return device(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  system,TResult Function( String asset)?  bundled,TResult Function( String title,  String path)?  device,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SystemAlarmSound() when system != null:
return system();case BundledAlarmSound() when bundled != null:
return bundled(_that.asset);case DeviceAlarmSound() when device != null:
return device(_that.title,_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  system,required TResult Function( String asset)  bundled,required TResult Function( String title,  String path)  device,}) {final _that = this;
switch (_that) {
case SystemAlarmSound():
return system();case BundledAlarmSound():
return bundled(_that.asset);case DeviceAlarmSound():
return device(_that.title,_that.path);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  system,TResult? Function( String asset)?  bundled,TResult? Function( String title,  String path)?  device,}) {final _that = this;
switch (_that) {
case SystemAlarmSound() when system != null:
return system();case BundledAlarmSound() when bundled != null:
return bundled(_that.asset);case DeviceAlarmSound() when device != null:
return device(_that.title,_that.path);case _:
  return null;

}
}

}

/// @nodoc


class SystemAlarmSound extends AlarmSound {
  const SystemAlarmSound(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemAlarmSound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmSound.system()';
}


}




/// @nodoc


class BundledAlarmSound extends AlarmSound {
  const BundledAlarmSound(this.asset): super._();
  

 final  String asset;

/// Create a copy of AlarmSound
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BundledAlarmSoundCopyWith<BundledAlarmSound> get copyWith => _$BundledAlarmSoundCopyWithImpl<BundledAlarmSound>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BundledAlarmSound&&(identical(other.asset, asset) || other.asset == asset));
}


@override
int get hashCode => Object.hash(runtimeType,asset);

@override
String toString() {
  return 'AlarmSound.bundled(asset: $asset)';
}


}

/// @nodoc
abstract mixin class $BundledAlarmSoundCopyWith<$Res> implements $AlarmSoundCopyWith<$Res> {
  factory $BundledAlarmSoundCopyWith(BundledAlarmSound value, $Res Function(BundledAlarmSound) _then) = _$BundledAlarmSoundCopyWithImpl;
@useResult
$Res call({
 String asset
});




}
/// @nodoc
class _$BundledAlarmSoundCopyWithImpl<$Res>
    implements $BundledAlarmSoundCopyWith<$Res> {
  _$BundledAlarmSoundCopyWithImpl(this._self, this._then);

  final BundledAlarmSound _self;
  final $Res Function(BundledAlarmSound) _then;

/// Create a copy of AlarmSound
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? asset = null,}) {
  return _then(BundledAlarmSound(
null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DeviceAlarmSound extends AlarmSound {
  const DeviceAlarmSound({required this.title, required this.path}): super._();
  

 final  String title;
 final  String path;

/// Create a copy of AlarmSound
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceAlarmSoundCopyWith<DeviceAlarmSound> get copyWith => _$DeviceAlarmSoundCopyWithImpl<DeviceAlarmSound>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceAlarmSound&&(identical(other.title, title) || other.title == title)&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode => Object.hash(runtimeType,title,path);

@override
String toString() {
  return 'AlarmSound.device(title: $title, path: $path)';
}


}

/// @nodoc
abstract mixin class $DeviceAlarmSoundCopyWith<$Res> implements $AlarmSoundCopyWith<$Res> {
  factory $DeviceAlarmSoundCopyWith(DeviceAlarmSound value, $Res Function(DeviceAlarmSound) _then) = _$DeviceAlarmSoundCopyWithImpl;
@useResult
$Res call({
 String title, String path
});




}
/// @nodoc
class _$DeviceAlarmSoundCopyWithImpl<$Res>
    implements $DeviceAlarmSoundCopyWith<$Res> {
  _$DeviceAlarmSoundCopyWithImpl(this._self, this._then);

  final DeviceAlarmSound _self;
  final $Res Function(DeviceAlarmSound) _then;

/// Create a copy of AlarmSound
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,Object? path = null,}) {
  return _then(DeviceAlarmSound(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
