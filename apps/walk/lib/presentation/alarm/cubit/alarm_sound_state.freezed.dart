// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_sound_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlarmSoundChoice {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmSoundChoice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmSoundChoice()';
}


}

/// @nodoc
class $AlarmSoundChoiceCopyWith<$Res>  {
$AlarmSoundChoiceCopyWith(AlarmSoundChoice _, $Res Function(AlarmSoundChoice) __);
}


/// Adds pattern-matching-related methods to [AlarmSoundChoice].
extension AlarmSoundChoicePatterns on AlarmSoundChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SystemSoundChoice value)?  system,TResult Function( BundledSoundChoice value)?  bundled,TResult Function( DeviceSoundChoice value)?  device,TResult Function( CurrentSoundChoice value)?  current,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SystemSoundChoice() when system != null:
return system(_that);case BundledSoundChoice() when bundled != null:
return bundled(_that);case DeviceSoundChoice() when device != null:
return device(_that);case CurrentSoundChoice() when current != null:
return current(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SystemSoundChoice value)  system,required TResult Function( BundledSoundChoice value)  bundled,required TResult Function( DeviceSoundChoice value)  device,required TResult Function( CurrentSoundChoice value)  current,}){
final _that = this;
switch (_that) {
case SystemSoundChoice():
return system(_that);case BundledSoundChoice():
return bundled(_that);case DeviceSoundChoice():
return device(_that);case CurrentSoundChoice():
return current(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SystemSoundChoice value)?  system,TResult? Function( BundledSoundChoice value)?  bundled,TResult? Function( DeviceSoundChoice value)?  device,TResult? Function( CurrentSoundChoice value)?  current,}){
final _that = this;
switch (_that) {
case SystemSoundChoice() when system != null:
return system(_that);case BundledSoundChoice() when bundled != null:
return bundled(_that);case DeviceSoundChoice() when device != null:
return device(_that);case CurrentSoundChoice() when current != null:
return current(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  system,TResult Function( String asset)?  bundled,TResult Function( DeviceRingtone ringtone)?  device,TResult Function( AlarmSound sound)?  current,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SystemSoundChoice() when system != null:
return system();case BundledSoundChoice() when bundled != null:
return bundled(_that.asset);case DeviceSoundChoice() when device != null:
return device(_that.ringtone);case CurrentSoundChoice() when current != null:
return current(_that.sound);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  system,required TResult Function( String asset)  bundled,required TResult Function( DeviceRingtone ringtone)  device,required TResult Function( AlarmSound sound)  current,}) {final _that = this;
switch (_that) {
case SystemSoundChoice():
return system();case BundledSoundChoice():
return bundled(_that.asset);case DeviceSoundChoice():
return device(_that.ringtone);case CurrentSoundChoice():
return current(_that.sound);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  system,TResult? Function( String asset)?  bundled,TResult? Function( DeviceRingtone ringtone)?  device,TResult? Function( AlarmSound sound)?  current,}) {final _that = this;
switch (_that) {
case SystemSoundChoice() when system != null:
return system();case BundledSoundChoice() when bundled != null:
return bundled(_that.asset);case DeviceSoundChoice() when device != null:
return device(_that.ringtone);case CurrentSoundChoice() when current != null:
return current(_that.sound);case _:
  return null;

}
}

}

/// @nodoc


class SystemSoundChoice implements AlarmSoundChoice {
  const SystemSoundChoice();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemSoundChoice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmSoundChoice.system()';
}


}




/// @nodoc


class BundledSoundChoice implements AlarmSoundChoice {
  const BundledSoundChoice(this.asset);
  

 final  String asset;

/// Create a copy of AlarmSoundChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BundledSoundChoiceCopyWith<BundledSoundChoice> get copyWith => _$BundledSoundChoiceCopyWithImpl<BundledSoundChoice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BundledSoundChoice&&(identical(other.asset, asset) || other.asset == asset));
}


@override
int get hashCode => Object.hash(runtimeType,asset);

@override
String toString() {
  return 'AlarmSoundChoice.bundled(asset: $asset)';
}


}

/// @nodoc
abstract mixin class $BundledSoundChoiceCopyWith<$Res> implements $AlarmSoundChoiceCopyWith<$Res> {
  factory $BundledSoundChoiceCopyWith(BundledSoundChoice value, $Res Function(BundledSoundChoice) _then) = _$BundledSoundChoiceCopyWithImpl;
@useResult
$Res call({
 String asset
});




}
/// @nodoc
class _$BundledSoundChoiceCopyWithImpl<$Res>
    implements $BundledSoundChoiceCopyWith<$Res> {
  _$BundledSoundChoiceCopyWithImpl(this._self, this._then);

  final BundledSoundChoice _self;
  final $Res Function(BundledSoundChoice) _then;

/// Create a copy of AlarmSoundChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? asset = null,}) {
  return _then(BundledSoundChoice(
null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DeviceSoundChoice implements AlarmSoundChoice {
  const DeviceSoundChoice(this.ringtone);
  

 final  DeviceRingtone ringtone;

/// Create a copy of AlarmSoundChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceSoundChoiceCopyWith<DeviceSoundChoice> get copyWith => _$DeviceSoundChoiceCopyWithImpl<DeviceSoundChoice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceSoundChoice&&(identical(other.ringtone, ringtone) || other.ringtone == ringtone));
}


@override
int get hashCode => Object.hash(runtimeType,ringtone);

@override
String toString() {
  return 'AlarmSoundChoice.device(ringtone: $ringtone)';
}


}

/// @nodoc
abstract mixin class $DeviceSoundChoiceCopyWith<$Res> implements $AlarmSoundChoiceCopyWith<$Res> {
  factory $DeviceSoundChoiceCopyWith(DeviceSoundChoice value, $Res Function(DeviceSoundChoice) _then) = _$DeviceSoundChoiceCopyWithImpl;
@useResult
$Res call({
 DeviceRingtone ringtone
});




}
/// @nodoc
class _$DeviceSoundChoiceCopyWithImpl<$Res>
    implements $DeviceSoundChoiceCopyWith<$Res> {
  _$DeviceSoundChoiceCopyWithImpl(this._self, this._then);

  final DeviceSoundChoice _self;
  final $Res Function(DeviceSoundChoice) _then;

/// Create a copy of AlarmSoundChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ringtone = null,}) {
  return _then(DeviceSoundChoice(
null == ringtone ? _self.ringtone : ringtone // ignore: cast_nullable_to_non_nullable
as DeviceRingtone,
  ));
}


}

/// @nodoc


class CurrentSoundChoice implements AlarmSoundChoice {
  const CurrentSoundChoice(this.sound);
  

 final  AlarmSound sound;

/// Create a copy of AlarmSoundChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrentSoundChoiceCopyWith<CurrentSoundChoice> get copyWith => _$CurrentSoundChoiceCopyWithImpl<CurrentSoundChoice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrentSoundChoice&&(identical(other.sound, sound) || other.sound == sound));
}


@override
int get hashCode => Object.hash(runtimeType,sound);

@override
String toString() {
  return 'AlarmSoundChoice.current(sound: $sound)';
}


}

/// @nodoc
abstract mixin class $CurrentSoundChoiceCopyWith<$Res> implements $AlarmSoundChoiceCopyWith<$Res> {
  factory $CurrentSoundChoiceCopyWith(CurrentSoundChoice value, $Res Function(CurrentSoundChoice) _then) = _$CurrentSoundChoiceCopyWithImpl;
@useResult
$Res call({
 AlarmSound sound
});


$AlarmSoundCopyWith<$Res> get sound;

}
/// @nodoc
class _$CurrentSoundChoiceCopyWithImpl<$Res>
    implements $CurrentSoundChoiceCopyWith<$Res> {
  _$CurrentSoundChoiceCopyWithImpl(this._self, this._then);

  final CurrentSoundChoice _self;
  final $Res Function(CurrentSoundChoice) _then;

/// Create a copy of AlarmSoundChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sound = null,}) {
  return _then(CurrentSoundChoice(
null == sound ? _self.sound : sound // ignore: cast_nullable_to_non_nullable
as AlarmSound,
  ));
}

/// Create a copy of AlarmSoundChoice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlarmSoundCopyWith<$Res> get sound {
  
  return $AlarmSoundCopyWith<$Res>(_self.sound, (value) {
    return _then(_self.copyWith(sound: value));
  });
}
}

/// @nodoc
mixin _$DeviceRingtones {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceRingtones);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeviceRingtones()';
}


}

/// @nodoc
class $DeviceRingtonesCopyWith<$Res>  {
$DeviceRingtonesCopyWith(DeviceRingtones _, $Res Function(DeviceRingtones) __);
}


/// Adds pattern-matching-related methods to [DeviceRingtones].
extension DeviceRingtonesPatterns on DeviceRingtones {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeviceRingtonesLoading value)?  loading,TResult Function( DeviceRingtonesLoaded value)?  loaded,TResult Function( DeviceRingtonesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeviceRingtonesLoading() when loading != null:
return loading(_that);case DeviceRingtonesLoaded() when loaded != null:
return loaded(_that);case DeviceRingtonesFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeviceRingtonesLoading value)  loading,required TResult Function( DeviceRingtonesLoaded value)  loaded,required TResult Function( DeviceRingtonesFailure value)  failure,}){
final _that = this;
switch (_that) {
case DeviceRingtonesLoading():
return loading(_that);case DeviceRingtonesLoaded():
return loaded(_that);case DeviceRingtonesFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeviceRingtonesLoading value)?  loading,TResult? Function( DeviceRingtonesLoaded value)?  loaded,TResult? Function( DeviceRingtonesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case DeviceRingtonesLoading() when loading != null:
return loading(_that);case DeviceRingtonesLoaded() when loaded != null:
return loaded(_that);case DeviceRingtonesFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<DeviceRingtone> items)?  loaded,TResult Function()?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeviceRingtonesLoading() when loading != null:
return loading();case DeviceRingtonesLoaded() when loaded != null:
return loaded(_that.items);case DeviceRingtonesFailure() when failure != null:
return failure();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<DeviceRingtone> items)  loaded,required TResult Function()  failure,}) {final _that = this;
switch (_that) {
case DeviceRingtonesLoading():
return loading();case DeviceRingtonesLoaded():
return loaded(_that.items);case DeviceRingtonesFailure():
return failure();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<DeviceRingtone> items)?  loaded,TResult? Function()?  failure,}) {final _that = this;
switch (_that) {
case DeviceRingtonesLoading() when loading != null:
return loading();case DeviceRingtonesLoaded() when loaded != null:
return loaded(_that.items);case DeviceRingtonesFailure() when failure != null:
return failure();case _:
  return null;

}
}

}

/// @nodoc


class DeviceRingtonesLoading implements DeviceRingtones {
  const DeviceRingtonesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceRingtonesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeviceRingtones.loading()';
}


}




/// @nodoc


class DeviceRingtonesLoaded implements DeviceRingtones {
  const DeviceRingtonesLoaded(final  List<DeviceRingtone> items): _items = items;
  

 final  List<DeviceRingtone> _items;
 List<DeviceRingtone> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of DeviceRingtones
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceRingtonesLoadedCopyWith<DeviceRingtonesLoaded> get copyWith => _$DeviceRingtonesLoadedCopyWithImpl<DeviceRingtonesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceRingtonesLoaded&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'DeviceRingtones.loaded(items: $items)';
}


}

/// @nodoc
abstract mixin class $DeviceRingtonesLoadedCopyWith<$Res> implements $DeviceRingtonesCopyWith<$Res> {
  factory $DeviceRingtonesLoadedCopyWith(DeviceRingtonesLoaded value, $Res Function(DeviceRingtonesLoaded) _then) = _$DeviceRingtonesLoadedCopyWithImpl;
@useResult
$Res call({
 List<DeviceRingtone> items
});




}
/// @nodoc
class _$DeviceRingtonesLoadedCopyWithImpl<$Res>
    implements $DeviceRingtonesLoadedCopyWith<$Res> {
  _$DeviceRingtonesLoadedCopyWithImpl(this._self, this._then);

  final DeviceRingtonesLoaded _self;
  final $Res Function(DeviceRingtonesLoaded) _then;

/// Create a copy of DeviceRingtones
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(DeviceRingtonesLoaded(
null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<DeviceRingtone>,
  ));
}


}

/// @nodoc


class DeviceRingtonesFailure implements DeviceRingtones {
  const DeviceRingtonesFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceRingtonesFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeviceRingtones.failure()';
}


}




/// @nodoc
mixin _$AlarmSoundState {

 AlarmSoundChoice get selected; DeviceRingtones get ringtones; bool get importing;
/// Create a copy of AlarmSoundState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlarmSoundStateCopyWith<AlarmSoundState> get copyWith => _$AlarmSoundStateCopyWithImpl<AlarmSoundState>(this as AlarmSoundState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmSoundState&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.ringtones, ringtones) || other.ringtones == ringtones)&&(identical(other.importing, importing) || other.importing == importing));
}


@override
int get hashCode => Object.hash(runtimeType,selected,ringtones,importing);

@override
String toString() {
  return 'AlarmSoundState(selected: $selected, ringtones: $ringtones, importing: $importing)';
}


}

/// @nodoc
abstract mixin class $AlarmSoundStateCopyWith<$Res>  {
  factory $AlarmSoundStateCopyWith(AlarmSoundState value, $Res Function(AlarmSoundState) _then) = _$AlarmSoundStateCopyWithImpl;
@useResult
$Res call({
 AlarmSoundChoice selected, DeviceRingtones ringtones, bool importing
});




}
/// @nodoc
class _$AlarmSoundStateCopyWithImpl<$Res>
    implements $AlarmSoundStateCopyWith<$Res> {
  _$AlarmSoundStateCopyWithImpl(this._self, this._then);

  final AlarmSoundState _self;
  final $Res Function(AlarmSoundState) _then;

/// Create a copy of AlarmSoundState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selected = null,Object? ringtones = null,Object? importing = null,}) {
  return _then(AlarmSoundState(
selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as AlarmSoundChoice,ringtones: null == ringtones ? _self.ringtones : ringtones // ignore: cast_nullable_to_non_nullable
as DeviceRingtones,importing: null == importing ? _self.importing : importing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AlarmSoundState].
extension AlarmSoundStatePatterns on AlarmSoundState {
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
