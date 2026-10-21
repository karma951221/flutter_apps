// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commute_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommuteStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommuteStatus()';
}


}

/// @nodoc
class $CommuteStatusCopyWith<$Res>  {
$CommuteStatusCopyWith(CommuteStatus _, $Res Function(CommuteStatus) __);
}


/// Adds pattern-matching-related methods to [CommuteStatus].
extension CommuteStatusPatterns on CommuteStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CommuteIdle value)?  idle,TResult Function( CommuteLoading value)?  loading,TResult Function( CommuteLoaded value)?  loaded,TResult Function( CommuteFailed value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CommuteIdle() when idle != null:
return idle(_that);case CommuteLoading() when loading != null:
return loading(_that);case CommuteLoaded() when loaded != null:
return loaded(_that);case CommuteFailed() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CommuteIdle value)  idle,required TResult Function( CommuteLoading value)  loading,required TResult Function( CommuteLoaded value)  loaded,required TResult Function( CommuteFailed value)  failure,}){
final _that = this;
switch (_that) {
case CommuteIdle():
return idle(_that);case CommuteLoading():
return loading(_that);case CommuteLoaded():
return loaded(_that);case CommuteFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CommuteIdle value)?  idle,TResult? Function( CommuteLoading value)?  loading,TResult? Function( CommuteLoaded value)?  loaded,TResult? Function( CommuteFailed value)?  failure,}){
final _that = this;
switch (_that) {
case CommuteIdle() when idle != null:
return idle(_that);case CommuteLoading() when loading != null:
return loading(_that);case CommuteLoaded() when loaded != null:
return loaded(_that);case CommuteFailed() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  loading,TResult Function( CommuteResult result)?  loaded,TResult Function( CommuteFailure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CommuteIdle() when idle != null:
return idle();case CommuteLoading() when loading != null:
return loading();case CommuteLoaded() when loaded != null:
return loaded(_that.result);case CommuteFailed() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  loading,required TResult Function( CommuteResult result)  loaded,required TResult Function( CommuteFailure failure)  failure,}) {final _that = this;
switch (_that) {
case CommuteIdle():
return idle();case CommuteLoading():
return loading();case CommuteLoaded():
return loaded(_that.result);case CommuteFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  loading,TResult? Function( CommuteResult result)?  loaded,TResult? Function( CommuteFailure failure)?  failure,}) {final _that = this;
switch (_that) {
case CommuteIdle() when idle != null:
return idle();case CommuteLoading() when loading != null:
return loading();case CommuteLoaded() when loaded != null:
return loaded(_that.result);case CommuteFailed() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CommuteIdle implements CommuteStatus {
  const CommuteIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommuteStatus.idle()';
}


}




/// @nodoc


class CommuteLoading implements CommuteStatus {
  const CommuteLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommuteStatus.loading()';
}


}




/// @nodoc


class CommuteLoaded implements CommuteStatus {
  const CommuteLoaded(this.result);
  

 final  CommuteResult result;

/// Create a copy of CommuteStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteLoadedCopyWith<CommuteLoaded> get copyWith => _$CommuteLoadedCopyWithImpl<CommuteLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteLoaded&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString() {
  return 'CommuteStatus.loaded(result: $result)';
}


}

/// @nodoc
abstract mixin class $CommuteLoadedCopyWith<$Res> implements $CommuteStatusCopyWith<$Res> {
  factory $CommuteLoadedCopyWith(CommuteLoaded value, $Res Function(CommuteLoaded) _then) = _$CommuteLoadedCopyWithImpl;
@useResult
$Res call({
 CommuteResult result
});


$CommuteResultCopyWith<$Res> get result;

}
/// @nodoc
class _$CommuteLoadedCopyWithImpl<$Res>
    implements $CommuteLoadedCopyWith<$Res> {
  _$CommuteLoadedCopyWithImpl(this._self, this._then);

  final CommuteLoaded _self;
  final $Res Function(CommuteLoaded) _then;

/// Create a copy of CommuteStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,}) {
  return _then(CommuteLoaded(
null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as CommuteResult,
  ));
}

/// Create a copy of CommuteStatus
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


class CommuteFailed implements CommuteStatus {
  const CommuteFailed(this.failure);
  

 final  CommuteFailure failure;

/// Create a copy of CommuteStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteFailedCopyWith<CommuteFailed> get copyWith => _$CommuteFailedCopyWithImpl<CommuteFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CommuteStatus.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CommuteFailedCopyWith<$Res> implements $CommuteStatusCopyWith<$Res> {
  factory $CommuteFailedCopyWith(CommuteFailed value, $Res Function(CommuteFailed) _then) = _$CommuteFailedCopyWithImpl;
@useResult
$Res call({
 CommuteFailure failure
});


$CommuteFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CommuteFailedCopyWithImpl<$Res>
    implements $CommuteFailedCopyWith<$Res> {
  _$CommuteFailedCopyWithImpl(this._self, this._then);

  final CommuteFailed _self;
  final $Res Function(CommuteFailed) _then;

/// Create a copy of CommuteStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CommuteFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as CommuteFailure,
  ));
}

/// Create a copy of CommuteStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommuteFailureCopyWith<$Res> get failure {
  
  return $CommuteFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc
mixin _$CommuteState {

 CommuteDirection get direction; Place? get home; Place? get work; CommuteStatus get status; bool get locating;
/// Create a copy of CommuteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteStateCopyWith<CommuteState> get copyWith => _$CommuteStateCopyWithImpl<CommuteState>(this as CommuteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteState&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.home, home) || other.home == home)&&(identical(other.work, work) || other.work == work)&&(identical(other.status, status) || other.status == status)&&(identical(other.locating, locating) || other.locating == locating));
}


@override
int get hashCode => Object.hash(runtimeType,direction,home,work,status,locating);

@override
String toString() {
  return 'CommuteState(direction: $direction, home: $home, work: $work, status: $status, locating: $locating)';
}


}

/// @nodoc
abstract mixin class $CommuteStateCopyWith<$Res>  {
  factory $CommuteStateCopyWith(CommuteState value, $Res Function(CommuteState) _then) = _$CommuteStateCopyWithImpl;
@useResult
$Res call({
 CommuteDirection direction, Place? home, Place? work, CommuteStatus status, bool locating
});




}
/// @nodoc
class _$CommuteStateCopyWithImpl<$Res>
    implements $CommuteStateCopyWith<$Res> {
  _$CommuteStateCopyWithImpl(this._self, this._then);

  final CommuteState _self;
  final $Res Function(CommuteState) _then;

/// Create a copy of CommuteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direction = null,Object? home = freezed,Object? work = freezed,Object? status = null,Object? locating = null,}) {
  return _then(CommuteState(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CommuteDirection,home: freezed == home ? _self.home : home // ignore: cast_nullable_to_non_nullable
as Place?,work: freezed == work ? _self.work : work // ignore: cast_nullable_to_non_nullable
as Place?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CommuteStatus,locating: null == locating ? _self.locating : locating // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CommuteState].
extension CommuteStatePatterns on CommuteState {
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
