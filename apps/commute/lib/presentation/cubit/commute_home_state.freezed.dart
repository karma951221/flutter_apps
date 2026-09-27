// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commute_home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommuteHomeState {

 CommuteDirection get direction;
/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteHomeStateCopyWith<CommuteHomeState> get copyWith => _$CommuteHomeStateCopyWithImpl<CommuteHomeState>(this as CommuteHomeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteHomeState&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode => Object.hash(runtimeType,direction);

@override
String toString() {
  return 'CommuteHomeState(direction: $direction)';
}


}

/// @nodoc
abstract mixin class $CommuteHomeStateCopyWith<$Res>  {
  factory $CommuteHomeStateCopyWith(CommuteHomeState value, $Res Function(CommuteHomeState) _then) = _$CommuteHomeStateCopyWithImpl;
@useResult
$Res call({
 CommuteDirection direction
});




}
/// @nodoc
class _$CommuteHomeStateCopyWithImpl<$Res>
    implements $CommuteHomeStateCopyWith<$Res> {
  _$CommuteHomeStateCopyWithImpl(this._self, this._then);

  final CommuteHomeState _self;
  final $Res Function(CommuteHomeState) _then;

/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direction = null,}) {
  return _then(_self.copyWith(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CommuteDirection,
  ));
}

}


/// Adds pattern-matching-related methods to [CommuteHomeState].
extension CommuteHomeStatePatterns on CommuteHomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CommuteHomeInitial value)?  initial,TResult Function( CommuteHomeLoading value)?  loading,TResult Function( CommuteHomeLoaded value)?  loaded,TResult Function( CommuteHomeFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CommuteHomeInitial() when initial != null:
return initial(_that);case CommuteHomeLoading() when loading != null:
return loading(_that);case CommuteHomeLoaded() when loaded != null:
return loaded(_that);case CommuteHomeFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CommuteHomeInitial value)  initial,required TResult Function( CommuteHomeLoading value)  loading,required TResult Function( CommuteHomeLoaded value)  loaded,required TResult Function( CommuteHomeFailure value)  failure,}){
final _that = this;
switch (_that) {
case CommuteHomeInitial():
return initial(_that);case CommuteHomeLoading():
return loading(_that);case CommuteHomeLoaded():
return loaded(_that);case CommuteHomeFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CommuteHomeInitial value)?  initial,TResult? Function( CommuteHomeLoading value)?  loading,TResult? Function( CommuteHomeLoaded value)?  loaded,TResult? Function( CommuteHomeFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CommuteHomeInitial() when initial != null:
return initial(_that);case CommuteHomeLoading() when loading != null:
return loading(_that);case CommuteHomeLoaded() when loaded != null:
return loaded(_that);case CommuteHomeFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( CommuteDirection direction)?  initial,TResult Function( CommuteDirection direction)?  loading,TResult Function( CommuteDirection direction,  CommuteResult result)?  loaded,TResult Function( CommuteDirection direction,  Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CommuteHomeInitial() when initial != null:
return initial(_that.direction);case CommuteHomeLoading() when loading != null:
return loading(_that.direction);case CommuteHomeLoaded() when loaded != null:
return loaded(_that.direction,_that.result);case CommuteHomeFailure() when failure != null:
return failure(_that.direction,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( CommuteDirection direction)  initial,required TResult Function( CommuteDirection direction)  loading,required TResult Function( CommuteDirection direction,  CommuteResult result)  loaded,required TResult Function( CommuteDirection direction,  Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CommuteHomeInitial():
return initial(_that.direction);case CommuteHomeLoading():
return loading(_that.direction);case CommuteHomeLoaded():
return loaded(_that.direction,_that.result);case CommuteHomeFailure():
return failure(_that.direction,_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( CommuteDirection direction)?  initial,TResult? Function( CommuteDirection direction)?  loading,TResult? Function( CommuteDirection direction,  CommuteResult result)?  loaded,TResult? Function( CommuteDirection direction,  Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CommuteHomeInitial() when initial != null:
return initial(_that.direction);case CommuteHomeLoading() when loading != null:
return loading(_that.direction);case CommuteHomeLoaded() when loaded != null:
return loaded(_that.direction,_that.result);case CommuteHomeFailure() when failure != null:
return failure(_that.direction,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CommuteHomeInitial implements CommuteHomeState {
  const CommuteHomeInitial(this.direction);
  

@override final  CommuteDirection direction;

/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteHomeInitialCopyWith<CommuteHomeInitial> get copyWith => _$CommuteHomeInitialCopyWithImpl<CommuteHomeInitial>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteHomeInitial&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode => Object.hash(runtimeType,direction);

@override
String toString() {
  return 'CommuteHomeState.initial(direction: $direction)';
}


}

/// @nodoc
abstract mixin class $CommuteHomeInitialCopyWith<$Res> implements $CommuteHomeStateCopyWith<$Res> {
  factory $CommuteHomeInitialCopyWith(CommuteHomeInitial value, $Res Function(CommuteHomeInitial) _then) = _$CommuteHomeInitialCopyWithImpl;
@override @useResult
$Res call({
 CommuteDirection direction
});




}
/// @nodoc
class _$CommuteHomeInitialCopyWithImpl<$Res>
    implements $CommuteHomeInitialCopyWith<$Res> {
  _$CommuteHomeInitialCopyWithImpl(this._self, this._then);

  final CommuteHomeInitial _self;
  final $Res Function(CommuteHomeInitial) _then;

/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direction = null,}) {
  return _then(CommuteHomeInitial(
null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CommuteDirection,
  ));
}


}

/// @nodoc


class CommuteHomeLoading implements CommuteHomeState {
  const CommuteHomeLoading(this.direction);
  

@override final  CommuteDirection direction;

/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteHomeLoadingCopyWith<CommuteHomeLoading> get copyWith => _$CommuteHomeLoadingCopyWithImpl<CommuteHomeLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteHomeLoading&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode => Object.hash(runtimeType,direction);

@override
String toString() {
  return 'CommuteHomeState.loading(direction: $direction)';
}


}

/// @nodoc
abstract mixin class $CommuteHomeLoadingCopyWith<$Res> implements $CommuteHomeStateCopyWith<$Res> {
  factory $CommuteHomeLoadingCopyWith(CommuteHomeLoading value, $Res Function(CommuteHomeLoading) _then) = _$CommuteHomeLoadingCopyWithImpl;
@override @useResult
$Res call({
 CommuteDirection direction
});




}
/// @nodoc
class _$CommuteHomeLoadingCopyWithImpl<$Res>
    implements $CommuteHomeLoadingCopyWith<$Res> {
  _$CommuteHomeLoadingCopyWithImpl(this._self, this._then);

  final CommuteHomeLoading _self;
  final $Res Function(CommuteHomeLoading) _then;

/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direction = null,}) {
  return _then(CommuteHomeLoading(
null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CommuteDirection,
  ));
}


}

/// @nodoc


class CommuteHomeLoaded implements CommuteHomeState {
  const CommuteHomeLoaded(this.direction, this.result);
  

@override final  CommuteDirection direction;
 final  CommuteResult result;

/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteHomeLoadedCopyWith<CommuteHomeLoaded> get copyWith => _$CommuteHomeLoadedCopyWithImpl<CommuteHomeLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteHomeLoaded&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,direction,result);

@override
String toString() {
  return 'CommuteHomeState.loaded(direction: $direction, result: $result)';
}


}

/// @nodoc
abstract mixin class $CommuteHomeLoadedCopyWith<$Res> implements $CommuteHomeStateCopyWith<$Res> {
  factory $CommuteHomeLoadedCopyWith(CommuteHomeLoaded value, $Res Function(CommuteHomeLoaded) _then) = _$CommuteHomeLoadedCopyWithImpl;
@override @useResult
$Res call({
 CommuteDirection direction, CommuteResult result
});


$CommuteResultCopyWith<$Res> get result;

}
/// @nodoc
class _$CommuteHomeLoadedCopyWithImpl<$Res>
    implements $CommuteHomeLoadedCopyWith<$Res> {
  _$CommuteHomeLoadedCopyWithImpl(this._self, this._then);

  final CommuteHomeLoaded _self;
  final $Res Function(CommuteHomeLoaded) _then;

/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direction = null,Object? result = null,}) {
  return _then(CommuteHomeLoaded(
null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CommuteDirection,null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as CommuteResult,
  ));
}

/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommuteResultCopyWith<$Res> get result {
  
  return $CommuteResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class CommuteHomeFailure implements CommuteHomeState {
  const CommuteHomeFailure(this.direction, this.failure);
  

@override final  CommuteDirection direction;
 final  Failure failure;

/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteHomeFailureCopyWith<CommuteHomeFailure> get copyWith => _$CommuteHomeFailureCopyWithImpl<CommuteHomeFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteHomeFailure&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,direction,failure);

@override
String toString() {
  return 'CommuteHomeState.failure(direction: $direction, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CommuteHomeFailureCopyWith<$Res> implements $CommuteHomeStateCopyWith<$Res> {
  factory $CommuteHomeFailureCopyWith(CommuteHomeFailure value, $Res Function(CommuteHomeFailure) _then) = _$CommuteHomeFailureCopyWithImpl;
@override @useResult
$Res call({
 CommuteDirection direction, Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CommuteHomeFailureCopyWithImpl<$Res>
    implements $CommuteHomeFailureCopyWith<$Res> {
  _$CommuteHomeFailureCopyWithImpl(this._self, this._then);

  final CommuteHomeFailure _self;
  final $Res Function(CommuteHomeFailure) _then;

/// Create a copy of CommuteHomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? direction = null,Object? failure = null,}) {
  return _then(CommuteHomeFailure(
null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CommuteDirection,null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CommuteHomeState
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
