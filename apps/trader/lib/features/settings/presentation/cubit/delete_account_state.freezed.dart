// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delete_account_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeleteAccountState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteAccountState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteAccountState()';
}


}

/// @nodoc
class $DeleteAccountStateCopyWith<$Res>  {
$DeleteAccountStateCopyWith(DeleteAccountState _, $Res Function(DeleteAccountState) __);
}


/// Adds pattern-matching-related methods to [DeleteAccountState].
extension DeleteAccountStatePatterns on DeleteAccountState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeleteAccountIdle value)?  idle,TResult Function( DeleteAccountInProgress value)?  inProgress,TResult Function( DeleteAccountFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeleteAccountIdle() when idle != null:
return idle(_that);case DeleteAccountInProgress() when inProgress != null:
return inProgress(_that);case DeleteAccountFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeleteAccountIdle value)  idle,required TResult Function( DeleteAccountInProgress value)  inProgress,required TResult Function( DeleteAccountFailure value)  failure,}){
final _that = this;
switch (_that) {
case DeleteAccountIdle():
return idle(_that);case DeleteAccountInProgress():
return inProgress(_that);case DeleteAccountFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeleteAccountIdle value)?  idle,TResult? Function( DeleteAccountInProgress value)?  inProgress,TResult? Function( DeleteAccountFailure value)?  failure,}){
final _that = this;
switch (_that) {
case DeleteAccountIdle() when idle != null:
return idle(_that);case DeleteAccountInProgress() when inProgress != null:
return inProgress(_that);case DeleteAccountFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  inProgress,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeleteAccountIdle() when idle != null:
return idle();case DeleteAccountInProgress() when inProgress != null:
return inProgress();case DeleteAccountFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  inProgress,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case DeleteAccountIdle():
return idle();case DeleteAccountInProgress():
return inProgress();case DeleteAccountFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  inProgress,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case DeleteAccountIdle() when idle != null:
return idle();case DeleteAccountInProgress() when inProgress != null:
return inProgress();case DeleteAccountFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DeleteAccountIdle implements DeleteAccountState {
  const DeleteAccountIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteAccountIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteAccountState.idle()';
}


}




/// @nodoc


class DeleteAccountInProgress implements DeleteAccountState {
  const DeleteAccountInProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteAccountInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteAccountState.inProgress()';
}


}




/// @nodoc


class DeleteAccountFailure implements DeleteAccountState {
  const DeleteAccountFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of DeleteAccountState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteAccountFailureCopyWith<DeleteAccountFailure> get copyWith => _$DeleteAccountFailureCopyWithImpl<DeleteAccountFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteAccountFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DeleteAccountState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DeleteAccountFailureCopyWith<$Res> implements $DeleteAccountStateCopyWith<$Res> {
  factory $DeleteAccountFailureCopyWith(DeleteAccountFailure value, $Res Function(DeleteAccountFailure) _then) = _$DeleteAccountFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DeleteAccountFailureCopyWithImpl<$Res>
    implements $DeleteAccountFailureCopyWith<$Res> {
  _$DeleteAccountFailureCopyWithImpl(this._self, this._then);

  final DeleteAccountFailure _self;
  final $Res Function(DeleteAccountFailure) _then;

/// Create a copy of DeleteAccountState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DeleteAccountFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of DeleteAccountState
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
