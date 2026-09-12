// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'submit_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubmitState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmitState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SubmitState()';
}


}

/// @nodoc
class $SubmitStateCopyWith<$Res>  {
$SubmitStateCopyWith(SubmitState _, $Res Function(SubmitState) __);
}


/// Adds pattern-matching-related methods to [SubmitState].
extension SubmitStatePatterns on SubmitState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SubmitIdle value)?  idle,TResult Function( SubmitInProgress value)?  inProgress,TResult Function( SubmitSuccess value)?  success,TResult Function( SubmitFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SubmitIdle() when idle != null:
return idle(_that);case SubmitInProgress() when inProgress != null:
return inProgress(_that);case SubmitSuccess() when success != null:
return success(_that);case SubmitFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SubmitIdle value)  idle,required TResult Function( SubmitInProgress value)  inProgress,required TResult Function( SubmitSuccess value)  success,required TResult Function( SubmitFailure value)  failure,}){
final _that = this;
switch (_that) {
case SubmitIdle():
return idle(_that);case SubmitInProgress():
return inProgress(_that);case SubmitSuccess():
return success(_that);case SubmitFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SubmitIdle value)?  idle,TResult? Function( SubmitInProgress value)?  inProgress,TResult? Function( SubmitSuccess value)?  success,TResult? Function( SubmitFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SubmitIdle() when idle != null:
return idle(_that);case SubmitInProgress() when inProgress != null:
return inProgress(_that);case SubmitSuccess() when success != null:
return success(_that);case SubmitFailure() when failure != null:
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
case SubmitIdle() when idle != null:
return idle();case SubmitInProgress() when inProgress != null:
return inProgress();case SubmitSuccess() when success != null:
return success();case SubmitFailure() when failure != null:
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
case SubmitIdle():
return idle();case SubmitInProgress():
return inProgress();case SubmitSuccess():
return success();case SubmitFailure():
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
case SubmitIdle() when idle != null:
return idle();case SubmitInProgress() when inProgress != null:
return inProgress();case SubmitSuccess() when success != null:
return success();case SubmitFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SubmitIdle implements SubmitState {
  const SubmitIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmitIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SubmitState.idle()';
}


}




/// @nodoc


class SubmitInProgress implements SubmitState {
  const SubmitInProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmitInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SubmitState.inProgress()';
}


}




/// @nodoc


class SubmitSuccess implements SubmitState {
  const SubmitSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmitSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SubmitState.success()';
}


}




/// @nodoc


class SubmitFailure implements SubmitState {
  const SubmitFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SubmitState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubmitFailureCopyWith<SubmitFailure> get copyWith => _$SubmitFailureCopyWithImpl<SubmitFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubmitFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SubmitState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SubmitFailureCopyWith<$Res> implements $SubmitStateCopyWith<$Res> {
  factory $SubmitFailureCopyWith(SubmitFailure value, $Res Function(SubmitFailure) _then) = _$SubmitFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SubmitFailureCopyWithImpl<$Res>
    implements $SubmitFailureCopyWith<$Res> {
  _$SubmitFailureCopyWithImpl(this._self, this._then);

  final SubmitFailure _self;
  final $Res Function(SubmitFailure) _then;

/// Create a copy of SubmitState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SubmitFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SubmitState
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
