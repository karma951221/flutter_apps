// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lock_setup_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LockSetupState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LockSetupState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LockSetupState()';
}


}

/// @nodoc
class $LockSetupStateCopyWith<$Res>  {
$LockSetupStateCopyWith(LockSetupState _, $Res Function(LockSetupState) __);
}


/// Adds pattern-matching-related methods to [LockSetupState].
extension LockSetupStatePatterns on LockSetupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SetupLoading value)?  loading,TResult Function( SetupNeedsScreenLock value)?  needsScreenLock,TResult Function( SetupVerifying value)?  verifying,TResult Function( SetupChoosing value)?  choosing,TResult Function( SetupEntering value)?  entering,TResult Function( SetupDone value)?  done,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SetupLoading() when loading != null:
return loading(_that);case SetupNeedsScreenLock() when needsScreenLock != null:
return needsScreenLock(_that);case SetupVerifying() when verifying != null:
return verifying(_that);case SetupChoosing() when choosing != null:
return choosing(_that);case SetupEntering() when entering != null:
return entering(_that);case SetupDone() when done != null:
return done(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SetupLoading value)  loading,required TResult Function( SetupNeedsScreenLock value)  needsScreenLock,required TResult Function( SetupVerifying value)  verifying,required TResult Function( SetupChoosing value)  choosing,required TResult Function( SetupEntering value)  entering,required TResult Function( SetupDone value)  done,}){
final _that = this;
switch (_that) {
case SetupLoading():
return loading(_that);case SetupNeedsScreenLock():
return needsScreenLock(_that);case SetupVerifying():
return verifying(_that);case SetupChoosing():
return choosing(_that);case SetupEntering():
return entering(_that);case SetupDone():
return done(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SetupLoading value)?  loading,TResult? Function( SetupNeedsScreenLock value)?  needsScreenLock,TResult? Function( SetupVerifying value)?  verifying,TResult? Function( SetupChoosing value)?  choosing,TResult? Function( SetupEntering value)?  entering,TResult? Function( SetupDone value)?  done,}){
final _that = this;
switch (_that) {
case SetupLoading() when loading != null:
return loading(_that);case SetupNeedsScreenLock() when needsScreenLock != null:
return needsScreenLock(_that);case SetupVerifying() when verifying != null:
return verifying(_that);case SetupChoosing() when choosing != null:
return choosing(_that);case SetupEntering() when entering != null:
return entering(_that);case SetupDone() when done != null:
return done(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  needsScreenLock,TResult Function( LockMethod method,  Duration? blockedFor,  bool longBlock,  bool wrong)?  verifying,TResult Function( LockMethod? current,  bool canTurnOff)?  choosing,TResult Function( LockMethod method,  bool confirming,  LockSetupError? error)?  entering,TResult Function()?  done,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SetupLoading() when loading != null:
return loading();case SetupNeedsScreenLock() when needsScreenLock != null:
return needsScreenLock();case SetupVerifying() when verifying != null:
return verifying(_that.method,_that.blockedFor,_that.longBlock,_that.wrong);case SetupChoosing() when choosing != null:
return choosing(_that.current,_that.canTurnOff);case SetupEntering() when entering != null:
return entering(_that.method,_that.confirming,_that.error);case SetupDone() when done != null:
return done();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  needsScreenLock,required TResult Function( LockMethod method,  Duration? blockedFor,  bool longBlock,  bool wrong)  verifying,required TResult Function( LockMethod? current,  bool canTurnOff)  choosing,required TResult Function( LockMethod method,  bool confirming,  LockSetupError? error)  entering,required TResult Function()  done,}) {final _that = this;
switch (_that) {
case SetupLoading():
return loading();case SetupNeedsScreenLock():
return needsScreenLock();case SetupVerifying():
return verifying(_that.method,_that.blockedFor,_that.longBlock,_that.wrong);case SetupChoosing():
return choosing(_that.current,_that.canTurnOff);case SetupEntering():
return entering(_that.method,_that.confirming,_that.error);case SetupDone():
return done();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  needsScreenLock,TResult? Function( LockMethod method,  Duration? blockedFor,  bool longBlock,  bool wrong)?  verifying,TResult? Function( LockMethod? current,  bool canTurnOff)?  choosing,TResult? Function( LockMethod method,  bool confirming,  LockSetupError? error)?  entering,TResult? Function()?  done,}) {final _that = this;
switch (_that) {
case SetupLoading() when loading != null:
return loading();case SetupNeedsScreenLock() when needsScreenLock != null:
return needsScreenLock();case SetupVerifying() when verifying != null:
return verifying(_that.method,_that.blockedFor,_that.longBlock,_that.wrong);case SetupChoosing() when choosing != null:
return choosing(_that.current,_that.canTurnOff);case SetupEntering() when entering != null:
return entering(_that.method,_that.confirming,_that.error);case SetupDone() when done != null:
return done();case _:
  return null;

}
}

}

/// @nodoc


class SetupLoading implements LockSetupState {
  const SetupLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetupLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LockSetupState.loading()';
}


}




/// @nodoc


class SetupNeedsScreenLock implements LockSetupState {
  const SetupNeedsScreenLock();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetupNeedsScreenLock);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LockSetupState.needsScreenLock()';
}


}




/// @nodoc


class SetupVerifying implements LockSetupState {
  const SetupVerifying({required this.method, this.blockedFor, this.longBlock = false, this.wrong = false});
  

 final  LockMethod method;
 final  Duration? blockedFor;
@JsonKey() final  bool longBlock;
@JsonKey() final  bool wrong;

/// Create a copy of LockSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetupVerifyingCopyWith<SetupVerifying> get copyWith => _$SetupVerifyingCopyWithImpl<SetupVerifying>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetupVerifying&&(identical(other.method, method) || other.method == method)&&(identical(other.blockedFor, blockedFor) || other.blockedFor == blockedFor)&&(identical(other.longBlock, longBlock) || other.longBlock == longBlock)&&(identical(other.wrong, wrong) || other.wrong == wrong));
}


@override
int get hashCode => Object.hash(runtimeType,method,blockedFor,longBlock,wrong);

@override
String toString() {
  return 'LockSetupState.verifying(method: $method, blockedFor: $blockedFor, longBlock: $longBlock, wrong: $wrong)';
}


}

/// @nodoc
abstract mixin class $SetupVerifyingCopyWith<$Res> implements $LockSetupStateCopyWith<$Res> {
  factory $SetupVerifyingCopyWith(SetupVerifying value, $Res Function(SetupVerifying) _then) = _$SetupVerifyingCopyWithImpl;
@useResult
$Res call({
 LockMethod method, Duration? blockedFor, bool longBlock, bool wrong
});




}
/// @nodoc
class _$SetupVerifyingCopyWithImpl<$Res>
    implements $SetupVerifyingCopyWith<$Res> {
  _$SetupVerifyingCopyWithImpl(this._self, this._then);

  final SetupVerifying _self;
  final $Res Function(SetupVerifying) _then;

/// Create a copy of LockSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? method = null,Object? blockedFor = freezed,Object? longBlock = null,Object? wrong = null,}) {
  return _then(SetupVerifying(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as LockMethod,blockedFor: freezed == blockedFor ? _self.blockedFor : blockedFor // ignore: cast_nullable_to_non_nullable
as Duration?,longBlock: null == longBlock ? _self.longBlock : longBlock // ignore: cast_nullable_to_non_nullable
as bool,wrong: null == wrong ? _self.wrong : wrong // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class SetupChoosing implements LockSetupState {
  const SetupChoosing({this.current, this.canTurnOff = false});
  

 final  LockMethod? current;
@JsonKey() final  bool canTurnOff;

/// Create a copy of LockSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetupChoosingCopyWith<SetupChoosing> get copyWith => _$SetupChoosingCopyWithImpl<SetupChoosing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetupChoosing&&(identical(other.current, current) || other.current == current)&&(identical(other.canTurnOff, canTurnOff) || other.canTurnOff == canTurnOff));
}


@override
int get hashCode => Object.hash(runtimeType,current,canTurnOff);

@override
String toString() {
  return 'LockSetupState.choosing(current: $current, canTurnOff: $canTurnOff)';
}


}

/// @nodoc
abstract mixin class $SetupChoosingCopyWith<$Res> implements $LockSetupStateCopyWith<$Res> {
  factory $SetupChoosingCopyWith(SetupChoosing value, $Res Function(SetupChoosing) _then) = _$SetupChoosingCopyWithImpl;
@useResult
$Res call({
 LockMethod? current, bool canTurnOff
});




}
/// @nodoc
class _$SetupChoosingCopyWithImpl<$Res>
    implements $SetupChoosingCopyWith<$Res> {
  _$SetupChoosingCopyWithImpl(this._self, this._then);

  final SetupChoosing _self;
  final $Res Function(SetupChoosing) _then;

/// Create a copy of LockSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? current = freezed,Object? canTurnOff = null,}) {
  return _then(SetupChoosing(
current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as LockMethod?,canTurnOff: null == canTurnOff ? _self.canTurnOff : canTurnOff // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class SetupEntering implements LockSetupState {
  const SetupEntering({required this.method, this.confirming = false, this.error});
  

 final  LockMethod method;
@JsonKey() final  bool confirming;
 final  LockSetupError? error;

/// Create a copy of LockSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetupEnteringCopyWith<SetupEntering> get copyWith => _$SetupEnteringCopyWithImpl<SetupEntering>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetupEntering&&(identical(other.method, method) || other.method == method)&&(identical(other.confirming, confirming) || other.confirming == confirming)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,method,confirming,error);

@override
String toString() {
  return 'LockSetupState.entering(method: $method, confirming: $confirming, error: $error)';
}


}

/// @nodoc
abstract mixin class $SetupEnteringCopyWith<$Res> implements $LockSetupStateCopyWith<$Res> {
  factory $SetupEnteringCopyWith(SetupEntering value, $Res Function(SetupEntering) _then) = _$SetupEnteringCopyWithImpl;
@useResult
$Res call({
 LockMethod method, bool confirming, LockSetupError? error
});




}
/// @nodoc
class _$SetupEnteringCopyWithImpl<$Res>
    implements $SetupEnteringCopyWith<$Res> {
  _$SetupEnteringCopyWithImpl(this._self, this._then);

  final SetupEntering _self;
  final $Res Function(SetupEntering) _then;

/// Create a copy of LockSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? method = null,Object? confirming = null,Object? error = freezed,}) {
  return _then(SetupEntering(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as LockMethod,confirming: null == confirming ? _self.confirming : confirming // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as LockSetupError?,
  ));
}


}

/// @nodoc


class SetupDone implements LockSetupState {
  const SetupDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetupDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LockSetupState.done()';
}


}




// dart format on
