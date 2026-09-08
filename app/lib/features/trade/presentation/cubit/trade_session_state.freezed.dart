// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TradeSessionState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeSessionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TradeSessionState()';
}


}

/// @nodoc
class $TradeSessionStateCopyWith<$Res>  {
$TradeSessionStateCopyWith(TradeSessionState _, $Res Function(TradeSessionState) __);
}


/// Adds pattern-matching-related methods to [TradeSessionState].
extension TradeSessionStatePatterns on TradeSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TradeSessionLoading value)?  loading,TResult Function( TradeSessionLoaded value)?  loaded,TResult Function( TradeSessionFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TradeSessionLoading() when loading != null:
return loading(_that);case TradeSessionLoaded() when loaded != null:
return loaded(_that);case TradeSessionFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TradeSessionLoading value)  loading,required TResult Function( TradeSessionLoaded value)  loaded,required TResult Function( TradeSessionFailure value)  failure,}){
final _that = this;
switch (_that) {
case TradeSessionLoading():
return loading(_that);case TradeSessionLoaded():
return loaded(_that);case TradeSessionFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TradeSessionLoading value)?  loading,TResult? Function( TradeSessionLoaded value)?  loaded,TResult? Function( TradeSessionFailure value)?  failure,}){
final _that = this;
switch (_that) {
case TradeSessionLoading() when loading != null:
return loading(_that);case TradeSessionLoaded() when loaded != null:
return loaded(_that);case TradeSessionFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( TradeSession session,  bool isSubmitting)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TradeSessionLoading() when loading != null:
return loading();case TradeSessionLoaded() when loaded != null:
return loaded(_that.session,_that.isSubmitting);case TradeSessionFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( TradeSession session,  bool isSubmitting)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case TradeSessionLoading():
return loading();case TradeSessionLoaded():
return loaded(_that.session,_that.isSubmitting);case TradeSessionFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( TradeSession session,  bool isSubmitting)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case TradeSessionLoading() when loading != null:
return loading();case TradeSessionLoaded() when loaded != null:
return loaded(_that.session,_that.isSubmitting);case TradeSessionFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class TradeSessionLoading implements TradeSessionState {
  const TradeSessionLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeSessionLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TradeSessionState.loading()';
}


}




/// @nodoc


class TradeSessionLoaded implements TradeSessionState {
  const TradeSessionLoaded({required this.session, this.isSubmitting = false});
  

 final  TradeSession session;
@JsonKey() final  bool isSubmitting;

/// Create a copy of TradeSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeSessionLoadedCopyWith<TradeSessionLoaded> get copyWith => _$TradeSessionLoadedCopyWithImpl<TradeSessionLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeSessionLoaded&&(identical(other.session, session) || other.session == session)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,session,isSubmitting);

@override
String toString() {
  return 'TradeSessionState.loaded(session: $session, isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class $TradeSessionLoadedCopyWith<$Res> implements $TradeSessionStateCopyWith<$Res> {
  factory $TradeSessionLoadedCopyWith(TradeSessionLoaded value, $Res Function(TradeSessionLoaded) _then) = _$TradeSessionLoadedCopyWithImpl;
@useResult
$Res call({
 TradeSession session, bool isSubmitting
});


$TradeSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$TradeSessionLoadedCopyWithImpl<$Res>
    implements $TradeSessionLoadedCopyWith<$Res> {
  _$TradeSessionLoadedCopyWithImpl(this._self, this._then);

  final TradeSessionLoaded _self;
  final $Res Function(TradeSessionLoaded) _then;

/// Create a copy of TradeSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,Object? isSubmitting = null,}) {
  return _then(TradeSessionLoaded(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as TradeSession,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TradeSessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TradeSessionCopyWith<$Res> get session {
  
  return $TradeSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class TradeSessionFailure implements TradeSessionState {
  const TradeSessionFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of TradeSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeSessionFailureCopyWith<TradeSessionFailure> get copyWith => _$TradeSessionFailureCopyWithImpl<TradeSessionFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeSessionFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TradeSessionState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TradeSessionFailureCopyWith<$Res> implements $TradeSessionStateCopyWith<$Res> {
  factory $TradeSessionFailureCopyWith(TradeSessionFailure value, $Res Function(TradeSessionFailure) _then) = _$TradeSessionFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$TradeSessionFailureCopyWithImpl<$Res>
    implements $TradeSessionFailureCopyWith<$Res> {
  _$TradeSessionFailureCopyWithImpl(this._self, this._then);

  final TradeSessionFailure _self;
  final $Res Function(TradeSessionFailure) _then;

/// Create a copy of TradeSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TradeSessionFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of TradeSessionState
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
