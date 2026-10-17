// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthFormState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthFormState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthFormState()';
}


}

/// @nodoc
class $AuthFormStateCopyWith<$Res>  {
$AuthFormStateCopyWith(AuthFormState _, $Res Function(AuthFormState) __);
}


/// Adds pattern-matching-related methods to [AuthFormState].
extension AuthFormStatePatterns on AuthFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthFormIdle value)?  idle,TResult Function( AuthFormSubmitting value)?  submitting,TResult Function( AuthFormSucceeded value)?  succeeded,TResult Function( AuthFormFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthFormIdle() when idle != null:
return idle(_that);case AuthFormSubmitting() when submitting != null:
return submitting(_that);case AuthFormSucceeded() when succeeded != null:
return succeeded(_that);case AuthFormFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthFormIdle value)  idle,required TResult Function( AuthFormSubmitting value)  submitting,required TResult Function( AuthFormSucceeded value)  succeeded,required TResult Function( AuthFormFailed value)  failed,}){
final _that = this;
switch (_that) {
case AuthFormIdle():
return idle(_that);case AuthFormSubmitting():
return submitting(_that);case AuthFormSucceeded():
return succeeded(_that);case AuthFormFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthFormIdle value)?  idle,TResult? Function( AuthFormSubmitting value)?  submitting,TResult? Function( AuthFormSucceeded value)?  succeeded,TResult? Function( AuthFormFailed value)?  failed,}){
final _that = this;
switch (_that) {
case AuthFormIdle() when idle != null:
return idle(_that);case AuthFormSubmitting() when submitting != null:
return submitting(_that);case AuthFormSucceeded() when succeeded != null:
return succeeded(_that);case AuthFormFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  submitting,TResult Function()?  succeeded,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthFormIdle() when idle != null:
return idle();case AuthFormSubmitting() when submitting != null:
return submitting();case AuthFormSucceeded() when succeeded != null:
return succeeded();case AuthFormFailed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  submitting,required TResult Function()  succeeded,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case AuthFormIdle():
return idle();case AuthFormSubmitting():
return submitting();case AuthFormSucceeded():
return succeeded();case AuthFormFailed():
return failed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  submitting,TResult? Function()?  succeeded,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case AuthFormIdle() when idle != null:
return idle();case AuthFormSubmitting() when submitting != null:
return submitting();case AuthFormSucceeded() when succeeded != null:
return succeeded();case AuthFormFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class AuthFormIdle implements AuthFormState {
  const AuthFormIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthFormIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthFormState.idle()';
}


}




/// @nodoc


class AuthFormSubmitting implements AuthFormState {
  const AuthFormSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthFormSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthFormState.submitting()';
}


}




/// @nodoc


class AuthFormSucceeded implements AuthFormState {
  const AuthFormSucceeded();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthFormSucceeded);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthFormState.succeeded()';
}


}




/// @nodoc


class AuthFormFailed implements AuthFormState {
  const AuthFormFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of AuthFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthFormFailedCopyWith<AuthFormFailed> get copyWith => _$AuthFormFailedCopyWithImpl<AuthFormFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthFormFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'AuthFormState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AuthFormFailedCopyWith<$Res> implements $AuthFormStateCopyWith<$Res> {
  factory $AuthFormFailedCopyWith(AuthFormFailed value, $Res Function(AuthFormFailed) _then) = _$AuthFormFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$AuthFormFailedCopyWithImpl<$Res>
    implements $AuthFormFailedCopyWith<$Res> {
  _$AuthFormFailedCopyWithImpl(this._self, this._then);

  final AuthFormFailed _self;
  final $Res Function(AuthFormFailed) _then;

/// Create a copy of AuthFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(AuthFormFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of AuthFormState
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
