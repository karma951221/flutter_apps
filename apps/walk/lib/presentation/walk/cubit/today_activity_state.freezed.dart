// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'today_activity_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TodayActivityState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayActivityState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TodayActivityState()';
}


}

/// @nodoc
class $TodayActivityStateCopyWith<$Res>  {
$TodayActivityStateCopyWith(TodayActivityState _, $Res Function(TodayActivityState) __);
}


/// Adds pattern-matching-related methods to [TodayActivityState].
extension TodayActivityStatePatterns on TodayActivityState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TodayActivityLoading value)?  loading,TResult Function( TodayActivityLoaded value)?  loaded,TResult Function( TodayActivityFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TodayActivityLoading() when loading != null:
return loading(_that);case TodayActivityLoaded() when loaded != null:
return loaded(_that);case TodayActivityFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TodayActivityLoading value)  loading,required TResult Function( TodayActivityLoaded value)  loaded,required TResult Function( TodayActivityFailure value)  failure,}){
final _that = this;
switch (_that) {
case TodayActivityLoading():
return loading(_that);case TodayActivityLoaded():
return loaded(_that);case TodayActivityFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TodayActivityLoading value)?  loading,TResult? Function( TodayActivityLoaded value)?  loaded,TResult? Function( TodayActivityFailure value)?  failure,}){
final _that = this;
switch (_that) {
case TodayActivityLoading() when loading != null:
return loading(_that);case TodayActivityLoaded() when loaded != null:
return loaded(_that);case TodayActivityFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( DailyActivity activity)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TodayActivityLoading() when loading != null:
return loading();case TodayActivityLoaded() when loaded != null:
return loaded(_that.activity);case TodayActivityFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( DailyActivity activity)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case TodayActivityLoading():
return loading();case TodayActivityLoaded():
return loaded(_that.activity);case TodayActivityFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( DailyActivity activity)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case TodayActivityLoading() when loading != null:
return loading();case TodayActivityLoaded() when loaded != null:
return loaded(_that.activity);case TodayActivityFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class TodayActivityLoading implements TodayActivityState {
  const TodayActivityLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayActivityLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TodayActivityState.loading()';
}


}




/// @nodoc


class TodayActivityLoaded implements TodayActivityState {
  const TodayActivityLoaded(this.activity);
  

 final  DailyActivity activity;

/// Create a copy of TodayActivityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodayActivityLoadedCopyWith<TodayActivityLoaded> get copyWith => _$TodayActivityLoadedCopyWithImpl<TodayActivityLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayActivityLoaded&&(identical(other.activity, activity) || other.activity == activity));
}


@override
int get hashCode => Object.hash(runtimeType,activity);

@override
String toString() {
  return 'TodayActivityState.loaded(activity: $activity)';
}


}

/// @nodoc
abstract mixin class $TodayActivityLoadedCopyWith<$Res> implements $TodayActivityStateCopyWith<$Res> {
  factory $TodayActivityLoadedCopyWith(TodayActivityLoaded value, $Res Function(TodayActivityLoaded) _then) = _$TodayActivityLoadedCopyWithImpl;
@useResult
$Res call({
 DailyActivity activity
});


$DailyActivityCopyWith<$Res> get activity;

}
/// @nodoc
class _$TodayActivityLoadedCopyWithImpl<$Res>
    implements $TodayActivityLoadedCopyWith<$Res> {
  _$TodayActivityLoadedCopyWithImpl(this._self, this._then);

  final TodayActivityLoaded _self;
  final $Res Function(TodayActivityLoaded) _then;

/// Create a copy of TodayActivityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? activity = null,}) {
  return _then(TodayActivityLoaded(
null == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as DailyActivity,
  ));
}

/// Create a copy of TodayActivityState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DailyActivityCopyWith<$Res> get activity {
  
  return $DailyActivityCopyWith<$Res>(_self.activity, (value) {
    return _then(_self.copyWith(activity: value));
  });
}
}

/// @nodoc


class TodayActivityFailure implements TodayActivityState {
  const TodayActivityFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of TodayActivityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodayActivityFailureCopyWith<TodayActivityFailure> get copyWith => _$TodayActivityFailureCopyWithImpl<TodayActivityFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayActivityFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TodayActivityState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TodayActivityFailureCopyWith<$Res> implements $TodayActivityStateCopyWith<$Res> {
  factory $TodayActivityFailureCopyWith(TodayActivityFailure value, $Res Function(TodayActivityFailure) _then) = _$TodayActivityFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$TodayActivityFailureCopyWithImpl<$Res>
    implements $TodayActivityFailureCopyWith<$Res> {
  _$TodayActivityFailureCopyWithImpl(this._self, this._then);

  final TodayActivityFailure _self;
  final $Res Function(TodayActivityFailure) _then;

/// Create a copy of TodayActivityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TodayActivityFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of TodayActivityState
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
