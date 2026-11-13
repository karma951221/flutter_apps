// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recorder_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecorderStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecorderStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecorderStatus()';
}


}

/// @nodoc
class $RecorderStatusCopyWith<$Res>  {
$RecorderStatusCopyWith(RecorderStatus _, $Res Function(RecorderStatus) __);
}


/// Adds pattern-matching-related methods to [RecorderStatus].
extension RecorderStatusPatterns on RecorderStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RecorderOff value)?  off,TResult Function( RecorderRunning value)?  running,TResult Function( RecorderBlocked value)?  blocked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RecorderOff() when off != null:
return off(_that);case RecorderRunning() when running != null:
return running(_that);case RecorderBlocked() when blocked != null:
return blocked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RecorderOff value)  off,required TResult Function( RecorderRunning value)  running,required TResult Function( RecorderBlocked value)  blocked,}){
final _that = this;
switch (_that) {
case RecorderOff():
return off(_that);case RecorderRunning():
return running(_that);case RecorderBlocked():
return blocked(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RecorderOff value)?  off,TResult? Function( RecorderRunning value)?  running,TResult? Function( RecorderBlocked value)?  blocked,}){
final _that = this;
switch (_that) {
case RecorderOff() when off != null:
return off(_that);case RecorderRunning() when running != null:
return running(_that);case RecorderBlocked() when blocked != null:
return blocked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  off,TResult Function( RecordMode mode,  bool stillDetection,  DateTime? recordingSince)?  running,TResult Function( RecordMode mode)?  blocked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RecorderOff() when off != null:
return off();case RecorderRunning() when running != null:
return running(_that.mode,_that.stillDetection,_that.recordingSince);case RecorderBlocked() when blocked != null:
return blocked(_that.mode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  off,required TResult Function( RecordMode mode,  bool stillDetection,  DateTime? recordingSince)  running,required TResult Function( RecordMode mode)  blocked,}) {final _that = this;
switch (_that) {
case RecorderOff():
return off();case RecorderRunning():
return running(_that.mode,_that.stillDetection,_that.recordingSince);case RecorderBlocked():
return blocked(_that.mode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  off,TResult? Function( RecordMode mode,  bool stillDetection,  DateTime? recordingSince)?  running,TResult? Function( RecordMode mode)?  blocked,}) {final _that = this;
switch (_that) {
case RecorderOff() when off != null:
return off();case RecorderRunning() when running != null:
return running(_that.mode,_that.stillDetection,_that.recordingSince);case RecorderBlocked() when blocked != null:
return blocked(_that.mode);case _:
  return null;

}
}

}

/// @nodoc


class RecorderOff implements RecorderStatus {
  const RecorderOff();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecorderOff);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RecorderStatus.off()';
}


}




/// @nodoc


class RecorderRunning implements RecorderStatus {
  const RecorderRunning(this.mode, {required this.stillDetection, this.recordingSince});
  

 final  RecordMode mode;
 final  bool stillDetection;
 final  DateTime? recordingSince;

/// Create a copy of RecorderStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecorderRunningCopyWith<RecorderRunning> get copyWith => _$RecorderRunningCopyWithImpl<RecorderRunning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecorderRunning&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.stillDetection, stillDetection) || other.stillDetection == stillDetection)&&(identical(other.recordingSince, recordingSince) || other.recordingSince == recordingSince));
}


@override
int get hashCode => Object.hash(runtimeType,mode,stillDetection,recordingSince);

@override
String toString() {
  return 'RecorderStatus.running(mode: $mode, stillDetection: $stillDetection, recordingSince: $recordingSince)';
}


}

/// @nodoc
abstract mixin class $RecorderRunningCopyWith<$Res> implements $RecorderStatusCopyWith<$Res> {
  factory $RecorderRunningCopyWith(RecorderRunning value, $Res Function(RecorderRunning) _then) = _$RecorderRunningCopyWithImpl;
@useResult
$Res call({
 RecordMode mode, bool stillDetection, DateTime? recordingSince
});




}
/// @nodoc
class _$RecorderRunningCopyWithImpl<$Res>
    implements $RecorderRunningCopyWith<$Res> {
  _$RecorderRunningCopyWithImpl(this._self, this._then);

  final RecorderRunning _self;
  final $Res Function(RecorderRunning) _then;

/// Create a copy of RecorderStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? stillDetection = null,Object? recordingSince = freezed,}) {
  return _then(RecorderRunning(
null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RecordMode,stillDetection: null == stillDetection ? _self.stillDetection : stillDetection // ignore: cast_nullable_to_non_nullable
as bool,recordingSince: freezed == recordingSince ? _self.recordingSince : recordingSince // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class RecorderBlocked implements RecorderStatus {
  const RecorderBlocked(this.mode);
  

 final  RecordMode mode;

/// Create a copy of RecorderStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecorderBlockedCopyWith<RecorderBlocked> get copyWith => _$RecorderBlockedCopyWithImpl<RecorderBlocked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecorderBlocked&&(identical(other.mode, mode) || other.mode == mode));
}


@override
int get hashCode => Object.hash(runtimeType,mode);

@override
String toString() {
  return 'RecorderStatus.blocked(mode: $mode)';
}


}

/// @nodoc
abstract mixin class $RecorderBlockedCopyWith<$Res> implements $RecorderStatusCopyWith<$Res> {
  factory $RecorderBlockedCopyWith(RecorderBlocked value, $Res Function(RecorderBlocked) _then) = _$RecorderBlockedCopyWithImpl;
@useResult
$Res call({
 RecordMode mode
});




}
/// @nodoc
class _$RecorderBlockedCopyWithImpl<$Res>
    implements $RecorderBlockedCopyWith<$Res> {
  _$RecorderBlockedCopyWithImpl(this._self, this._then);

  final RecorderBlocked _self;
  final $Res Function(RecorderBlocked) _then;

/// Create a copy of RecorderStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mode = null,}) {
  return _then(RecorderBlocked(
null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RecordMode,
  ));
}


}

// dart format on
