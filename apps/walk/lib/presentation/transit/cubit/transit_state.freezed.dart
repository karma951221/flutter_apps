// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transit_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransitStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransitStatus()';
}


}

/// @nodoc
class $TransitStatusCopyWith<$Res>  {
$TransitStatusCopyWith(TransitStatus _, $Res Function(TransitStatus) __);
}


/// Adds pattern-matching-related methods to [TransitStatus].
extension TransitStatusPatterns on TransitStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TransitIdle value)?  idle,TResult Function( TransitLoading value)?  loading,TResult Function( TransitLoaded value)?  loaded,TResult Function( TransitFailed value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TransitIdle() when idle != null:
return idle(_that);case TransitLoading() when loading != null:
return loading(_that);case TransitLoaded() when loaded != null:
return loaded(_that);case TransitFailed() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TransitIdle value)  idle,required TResult Function( TransitLoading value)  loading,required TResult Function( TransitLoaded value)  loaded,required TResult Function( TransitFailed value)  failure,}){
final _that = this;
switch (_that) {
case TransitIdle():
return idle(_that);case TransitLoading():
return loading(_that);case TransitLoaded():
return loaded(_that);case TransitFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TransitIdle value)?  idle,TResult? Function( TransitLoading value)?  loading,TResult? Function( TransitLoaded value)?  loaded,TResult? Function( TransitFailed value)?  failure,}){
final _that = this;
switch (_that) {
case TransitIdle() when idle != null:
return idle(_that);case TransitLoading() when loading != null:
return loading(_that);case TransitLoaded() when loaded != null:
return loaded(_that);case TransitFailed() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  loading,TResult Function( TransitRoutesResult result)?  loaded,TResult Function( TransitFailure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TransitIdle() when idle != null:
return idle();case TransitLoading() when loading != null:
return loading();case TransitLoaded() when loaded != null:
return loaded(_that.result);case TransitFailed() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  loading,required TResult Function( TransitRoutesResult result)  loaded,required TResult Function( TransitFailure failure)  failure,}) {final _that = this;
switch (_that) {
case TransitIdle():
return idle();case TransitLoading():
return loading();case TransitLoaded():
return loaded(_that.result);case TransitFailed():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  loading,TResult? Function( TransitRoutesResult result)?  loaded,TResult? Function( TransitFailure failure)?  failure,}) {final _that = this;
switch (_that) {
case TransitIdle() when idle != null:
return idle();case TransitLoading() when loading != null:
return loading();case TransitLoaded() when loaded != null:
return loaded(_that.result);case TransitFailed() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class TransitIdle implements TransitStatus {
  const TransitIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransitStatus.idle()';
}


}




/// @nodoc


class TransitLoading implements TransitStatus {
  const TransitLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TransitStatus.loading()';
}


}




/// @nodoc


class TransitLoaded implements TransitStatus {
  const TransitLoaded(this.result);
  

 final  TransitRoutesResult result;

/// Create a copy of TransitStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitLoadedCopyWith<TransitLoaded> get copyWith => _$TransitLoadedCopyWithImpl<TransitLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitLoaded&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString() {
  return 'TransitStatus.loaded(result: $result)';
}


}

/// @nodoc
abstract mixin class $TransitLoadedCopyWith<$Res> implements $TransitStatusCopyWith<$Res> {
  factory $TransitLoadedCopyWith(TransitLoaded value, $Res Function(TransitLoaded) _then) = _$TransitLoadedCopyWithImpl;
@useResult
$Res call({
 TransitRoutesResult result
});




}
/// @nodoc
class _$TransitLoadedCopyWithImpl<$Res>
    implements $TransitLoadedCopyWith<$Res> {
  _$TransitLoadedCopyWithImpl(this._self, this._then);

  final TransitLoaded _self;
  final $Res Function(TransitLoaded) _then;

/// Create a copy of TransitStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,}) {
  return _then(TransitLoaded(
null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TransitRoutesResult,
  ));
}


}

/// @nodoc


class TransitFailed implements TransitStatus {
  const TransitFailed(this.failure);
  

 final  TransitFailure failure;

/// Create a copy of TransitStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitFailedCopyWith<TransitFailed> get copyWith => _$TransitFailedCopyWithImpl<TransitFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TransitStatus.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TransitFailedCopyWith<$Res> implements $TransitStatusCopyWith<$Res> {
  factory $TransitFailedCopyWith(TransitFailed value, $Res Function(TransitFailed) _then) = _$TransitFailedCopyWithImpl;
@useResult
$Res call({
 TransitFailure failure
});


$TransitFailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$TransitFailedCopyWithImpl<$Res>
    implements $TransitFailedCopyWith<$Res> {
  _$TransitFailedCopyWithImpl(this._self, this._then);

  final TransitFailed _self;
  final $Res Function(TransitFailed) _then;

/// Create a copy of TransitStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TransitFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as TransitFailure,
  ));
}

/// Create a copy of TransitStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransitFailureCopyWith<$Res> get failure {
  
  return $TransitFailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc
mixin _$TransitState {

 TransitPoint? get from; TransitPoint? get to; bool get locating; bool get locationFailed; TransitStatus get status;
/// Create a copy of TransitState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitStateCopyWith<TransitState> get copyWith => _$TransitStateCopyWithImpl<TransitState>(this as TransitState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitState&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.locating, locating) || other.locating == locating)&&(identical(other.locationFailed, locationFailed) || other.locationFailed == locationFailed)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,from,to,locating,locationFailed,status);

@override
String toString() {
  return 'TransitState(from: $from, to: $to, locating: $locating, locationFailed: $locationFailed, status: $status)';
}


}

/// @nodoc
abstract mixin class $TransitStateCopyWith<$Res>  {
  factory $TransitStateCopyWith(TransitState value, $Res Function(TransitState) _then) = _$TransitStateCopyWithImpl;
@useResult
$Res call({
 TransitPoint? from, TransitPoint? to, bool locating, bool locationFailed, TransitStatus status
});




}
/// @nodoc
class _$TransitStateCopyWithImpl<$Res>
    implements $TransitStateCopyWith<$Res> {
  _$TransitStateCopyWithImpl(this._self, this._then);

  final TransitState _self;
  final $Res Function(TransitState) _then;

/// Create a copy of TransitState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = freezed,Object? to = freezed,Object? locating = null,Object? locationFailed = null,Object? status = null,}) {
  return _then(TransitState(
from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as TransitPoint?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as TransitPoint?,locating: null == locating ? _self.locating : locating // ignore: cast_nullable_to_non_nullable
as bool,locationFailed: null == locationFailed ? _self.locationFailed : locationFailed // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransitStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [TransitState].
extension TransitStatePatterns on TransitState {
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
