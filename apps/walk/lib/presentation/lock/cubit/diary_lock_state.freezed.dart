// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary_lock_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiaryLockState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiaryLockState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DiaryLockState()';
}


}

/// @nodoc
class $DiaryLockStateCopyWith<$Res>  {
$DiaryLockStateCopyWith(DiaryLockState _, $Res Function(DiaryLockState) __);
}


/// Adds pattern-matching-related methods to [DiaryLockState].
extension DiaryLockStatePatterns on DiaryLockState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LockUnlocked value)?  unlocked,TResult Function( LockLocked value)?  locked,TResult Function( LockResetting value)?  resetting,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LockUnlocked() when unlocked != null:
return unlocked(_that);case LockLocked() when locked != null:
return locked(_that);case LockResetting() when resetting != null:
return resetting(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LockUnlocked value)  unlocked,required TResult Function( LockLocked value)  locked,required TResult Function( LockResetting value)  resetting,}){
final _that = this;
switch (_that) {
case LockUnlocked():
return unlocked(_that);case LockLocked():
return locked(_that);case LockResetting():
return resetting(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LockUnlocked value)?  unlocked,TResult? Function( LockLocked value)?  locked,TResult? Function( LockResetting value)?  resetting,}){
final _that = this;
switch (_that) {
case LockUnlocked() when unlocked != null:
return unlocked(_that);case LockLocked() when locked != null:
return locked(_that);case LockResetting() when resetting != null:
return resetting(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  unlocked,TResult Function( LockMethod method,  Duration? blockedFor,  bool longBlock,  bool wrong,  bool deviceUnavailable)?  locked,TResult Function()?  resetting,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LockUnlocked() when unlocked != null:
return unlocked();case LockLocked() when locked != null:
return locked(_that.method,_that.blockedFor,_that.longBlock,_that.wrong,_that.deviceUnavailable);case LockResetting() when resetting != null:
return resetting();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  unlocked,required TResult Function( LockMethod method,  Duration? blockedFor,  bool longBlock,  bool wrong,  bool deviceUnavailable)  locked,required TResult Function()  resetting,}) {final _that = this;
switch (_that) {
case LockUnlocked():
return unlocked();case LockLocked():
return locked(_that.method,_that.blockedFor,_that.longBlock,_that.wrong,_that.deviceUnavailable);case LockResetting():
return resetting();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  unlocked,TResult? Function( LockMethod method,  Duration? blockedFor,  bool longBlock,  bool wrong,  bool deviceUnavailable)?  locked,TResult? Function()?  resetting,}) {final _that = this;
switch (_that) {
case LockUnlocked() when unlocked != null:
return unlocked();case LockLocked() when locked != null:
return locked(_that.method,_that.blockedFor,_that.longBlock,_that.wrong,_that.deviceUnavailable);case LockResetting() when resetting != null:
return resetting();case _:
  return null;

}
}

}

/// @nodoc


class LockUnlocked implements DiaryLockState {
  const LockUnlocked();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LockUnlocked);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DiaryLockState.unlocked()';
}


}




/// @nodoc


class LockLocked implements DiaryLockState {
  const LockLocked({required this.method, this.blockedFor, this.longBlock = false, this.wrong = false, this.deviceUnavailable = false});
  

 final  LockMethod method;
 final  Duration? blockedFor;
@JsonKey() final  bool longBlock;
@JsonKey() final  bool wrong;
@JsonKey() final  bool deviceUnavailable;

/// Create a copy of DiaryLockState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LockLockedCopyWith<LockLocked> get copyWith => _$LockLockedCopyWithImpl<LockLocked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LockLocked&&(identical(other.method, method) || other.method == method)&&(identical(other.blockedFor, blockedFor) || other.blockedFor == blockedFor)&&(identical(other.longBlock, longBlock) || other.longBlock == longBlock)&&(identical(other.wrong, wrong) || other.wrong == wrong)&&(identical(other.deviceUnavailable, deviceUnavailable) || other.deviceUnavailable == deviceUnavailable));
}


@override
int get hashCode => Object.hash(runtimeType,method,blockedFor,longBlock,wrong,deviceUnavailable);

@override
String toString() {
  return 'DiaryLockState.locked(method: $method, blockedFor: $blockedFor, longBlock: $longBlock, wrong: $wrong, deviceUnavailable: $deviceUnavailable)';
}


}

/// @nodoc
abstract mixin class $LockLockedCopyWith<$Res> implements $DiaryLockStateCopyWith<$Res> {
  factory $LockLockedCopyWith(LockLocked value, $Res Function(LockLocked) _then) = _$LockLockedCopyWithImpl;
@useResult
$Res call({
 LockMethod method, Duration? blockedFor, bool longBlock, bool wrong, bool deviceUnavailable
});




}
/// @nodoc
class _$LockLockedCopyWithImpl<$Res>
    implements $LockLockedCopyWith<$Res> {
  _$LockLockedCopyWithImpl(this._self, this._then);

  final LockLocked _self;
  final $Res Function(LockLocked) _then;

/// Create a copy of DiaryLockState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? method = null,Object? blockedFor = freezed,Object? longBlock = null,Object? wrong = null,Object? deviceUnavailable = null,}) {
  return _then(LockLocked(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as LockMethod,blockedFor: freezed == blockedFor ? _self.blockedFor : blockedFor // ignore: cast_nullable_to_non_nullable
as Duration?,longBlock: null == longBlock ? _self.longBlock : longBlock // ignore: cast_nullable_to_non_nullable
as bool,wrong: null == wrong ? _self.wrong : wrong // ignore: cast_nullable_to_non_nullable
as bool,deviceUnavailable: null == deviceUnavailable ? _self.deviceUnavailable : deviceUnavailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class LockResetting implements DiaryLockState {
  const LockResetting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LockResetting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DiaryLockState.resetting()';
}


}




// dart format on
