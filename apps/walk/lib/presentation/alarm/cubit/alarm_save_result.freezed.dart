// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_save_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlarmSaveResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmSaveResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmSaveResult()';
}


}

/// @nodoc
class $AlarmSaveResultCopyWith<$Res>  {
$AlarmSaveResultCopyWith(AlarmSaveResult _, $Res Function(AlarmSaveResult) __);
}


/// Adds pattern-matching-related methods to [AlarmSaveResult].
extension AlarmSaveResultPatterns on AlarmSaveResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AlarmRingsIn value)?  ringsIn,TResult Function( AlarmPausedOut value)?  pausedOut,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AlarmRingsIn() when ringsIn != null:
return ringsIn(_that);case AlarmPausedOut() when pausedOut != null:
return pausedOut(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AlarmRingsIn value)  ringsIn,required TResult Function( AlarmPausedOut value)  pausedOut,}){
final _that = this;
switch (_that) {
case AlarmRingsIn():
return ringsIn(_that);case AlarmPausedOut():
return pausedOut(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AlarmRingsIn value)?  ringsIn,TResult? Function( AlarmPausedOut value)?  pausedOut,}){
final _that = this;
switch (_that) {
case AlarmRingsIn() when ringsIn != null:
return ringsIn(_that);case AlarmPausedOut() when pausedOut != null:
return pausedOut(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Duration untilRing)?  ringsIn,TResult Function()?  pausedOut,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AlarmRingsIn() when ringsIn != null:
return ringsIn(_that.untilRing);case AlarmPausedOut() when pausedOut != null:
return pausedOut();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Duration untilRing)  ringsIn,required TResult Function()  pausedOut,}) {final _that = this;
switch (_that) {
case AlarmRingsIn():
return ringsIn(_that.untilRing);case AlarmPausedOut():
return pausedOut();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Duration untilRing)?  ringsIn,TResult? Function()?  pausedOut,}) {final _that = this;
switch (_that) {
case AlarmRingsIn() when ringsIn != null:
return ringsIn(_that.untilRing);case AlarmPausedOut() when pausedOut != null:
return pausedOut();case _:
  return null;

}
}

}

/// @nodoc


class AlarmRingsIn implements AlarmSaveResult {
  const AlarmRingsIn(this.untilRing);
  

 final  Duration untilRing;

/// Create a copy of AlarmSaveResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlarmRingsInCopyWith<AlarmRingsIn> get copyWith => _$AlarmRingsInCopyWithImpl<AlarmRingsIn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmRingsIn&&(identical(other.untilRing, untilRing) || other.untilRing == untilRing));
}


@override
int get hashCode => Object.hash(runtimeType,untilRing);

@override
String toString() {
  return 'AlarmSaveResult.ringsIn(untilRing: $untilRing)';
}


}

/// @nodoc
abstract mixin class $AlarmRingsInCopyWith<$Res> implements $AlarmSaveResultCopyWith<$Res> {
  factory $AlarmRingsInCopyWith(AlarmRingsIn value, $Res Function(AlarmRingsIn) _then) = _$AlarmRingsInCopyWithImpl;
@useResult
$Res call({
 Duration untilRing
});




}
/// @nodoc
class _$AlarmRingsInCopyWithImpl<$Res>
    implements $AlarmRingsInCopyWith<$Res> {
  _$AlarmRingsInCopyWithImpl(this._self, this._then);

  final AlarmRingsIn _self;
  final $Res Function(AlarmRingsIn) _then;

/// Create a copy of AlarmSaveResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? untilRing = null,}) {
  return _then(AlarmRingsIn(
null == untilRing ? _self.untilRing : untilRing // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc


class AlarmPausedOut implements AlarmSaveResult {
  const AlarmPausedOut();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmPausedOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmSaveResult.pausedOut()';
}


}




// dart format on
