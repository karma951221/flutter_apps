// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'change_password_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChangePasswordState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePasswordState()';
}


}

/// @nodoc
class $ChangePasswordStateCopyWith<$Res>  {
$ChangePasswordStateCopyWith(ChangePasswordState _, $Res Function(ChangePasswordState) __);
}


/// Adds pattern-matching-related methods to [ChangePasswordState].
extension ChangePasswordStatePatterns on ChangePasswordState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChangePasswordIdle value)?  idle,TResult Function( ChangePasswordInProgress value)?  inProgress,TResult Function( ChangePasswordSuccess value)?  success,TResult Function( ChangePasswordFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChangePasswordIdle() when idle != null:
return idle(_that);case ChangePasswordInProgress() when inProgress != null:
return inProgress(_that);case ChangePasswordSuccess() when success != null:
return success(_that);case ChangePasswordFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChangePasswordIdle value)  idle,required TResult Function( ChangePasswordInProgress value)  inProgress,required TResult Function( ChangePasswordSuccess value)  success,required TResult Function( ChangePasswordFailure value)  failure,}){
final _that = this;
switch (_that) {
case ChangePasswordIdle():
return idle(_that);case ChangePasswordInProgress():
return inProgress(_that);case ChangePasswordSuccess():
return success(_that);case ChangePasswordFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChangePasswordIdle value)?  idle,TResult? Function( ChangePasswordInProgress value)?  inProgress,TResult? Function( ChangePasswordSuccess value)?  success,TResult? Function( ChangePasswordFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ChangePasswordIdle() when idle != null:
return idle(_that);case ChangePasswordInProgress() when inProgress != null:
return inProgress(_that);case ChangePasswordSuccess() when success != null:
return success(_that);case ChangePasswordFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  inProgress,TResult Function()?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChangePasswordIdle() when idle != null:
return idle();case ChangePasswordInProgress() when inProgress != null:
return inProgress();case ChangePasswordSuccess() when success != null:
return success();case ChangePasswordFailure() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  inProgress,required TResult Function()  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case ChangePasswordIdle():
return idle();case ChangePasswordInProgress():
return inProgress();case ChangePasswordSuccess():
return success();case ChangePasswordFailure():
return failure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  inProgress,TResult? Function()?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case ChangePasswordIdle() when idle != null:
return idle();case ChangePasswordInProgress() when inProgress != null:
return inProgress();case ChangePasswordSuccess() when success != null:
return success();case ChangePasswordFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ChangePasswordIdle implements ChangePasswordState {
  const ChangePasswordIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePasswordState.idle()';
}


}




/// @nodoc


class ChangePasswordInProgress implements ChangePasswordState {
  const ChangePasswordInProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePasswordState.inProgress()';
}


}




/// @nodoc


class ChangePasswordSuccess implements ChangePasswordState {
  const ChangePasswordSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChangePasswordState.success()';
}


}




/// @nodoc


class ChangePasswordFailure implements ChangePasswordState {
  const ChangePasswordFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of ChangePasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangePasswordFailureCopyWith<ChangePasswordFailure> get copyWith => _$ChangePasswordFailureCopyWithImpl<ChangePasswordFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangePasswordFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ChangePasswordState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ChangePasswordFailureCopyWith<$Res> implements $ChangePasswordStateCopyWith<$Res> {
  factory $ChangePasswordFailureCopyWith(ChangePasswordFailure value, $Res Function(ChangePasswordFailure) _then) = _$ChangePasswordFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ChangePasswordFailureCopyWithImpl<$Res>
    implements $ChangePasswordFailureCopyWith<$Res> {
  _$ChangePasswordFailureCopyWithImpl(this._self, this._then);

  final ChangePasswordFailure _self;
  final $Res Function(ChangePasswordFailure) _then;

/// Create a copy of ChangePasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ChangePasswordFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ChangePasswordState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
