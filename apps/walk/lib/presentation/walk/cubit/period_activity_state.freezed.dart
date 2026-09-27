// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_activity_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PeriodActivityState {

 int get offset;
/// Create a copy of PeriodActivityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodActivityStateCopyWith<PeriodActivityState> get copyWith => _$PeriodActivityStateCopyWithImpl<PeriodActivityState>(this as PeriodActivityState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodActivityState&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,offset);

@override
String toString() {
  return 'PeriodActivityState(offset: $offset)';
}


}

/// @nodoc
abstract mixin class $PeriodActivityStateCopyWith<$Res>  {
  factory $PeriodActivityStateCopyWith(PeriodActivityState value, $Res Function(PeriodActivityState) _then) = _$PeriodActivityStateCopyWithImpl;
@useResult
$Res call({
 int offset
});




}
/// @nodoc
class _$PeriodActivityStateCopyWithImpl<$Res>
    implements $PeriodActivityStateCopyWith<$Res> {
  _$PeriodActivityStateCopyWithImpl(this._self, this._then);

  final PeriodActivityState _self;
  final $Res Function(PeriodActivityState) _then;

/// Create a copy of PeriodActivityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? offset = null,}) {
  return _then(_self.copyWith(
offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodActivityState].
extension PeriodActivityStatePatterns on PeriodActivityState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PeriodActivityLoading value)?  loading,TResult Function( PeriodActivityLoaded value)?  loaded,TResult Function( PeriodActivityFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PeriodActivityLoading() when loading != null:
return loading(_that);case PeriodActivityLoaded() when loaded != null:
return loaded(_that);case PeriodActivityFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PeriodActivityLoading value)  loading,required TResult Function( PeriodActivityLoaded value)  loaded,required TResult Function( PeriodActivityFailure value)  failure,}){
final _that = this;
switch (_that) {
case PeriodActivityLoading():
return loading(_that);case PeriodActivityLoaded():
return loaded(_that);case PeriodActivityFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PeriodActivityLoading value)?  loading,TResult? Function( PeriodActivityLoaded value)?  loaded,TResult? Function( PeriodActivityFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PeriodActivityLoading() when loading != null:
return loading(_that);case PeriodActivityLoaded() when loaded != null:
return loaded(_that);case PeriodActivityFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int offset)?  loading,TResult Function( int offset,  ActivityPeriod period)?  loaded,TResult Function( int offset,  Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PeriodActivityLoading() when loading != null:
return loading(_that.offset);case PeriodActivityLoaded() when loaded != null:
return loaded(_that.offset,_that.period);case PeriodActivityFailure() when failure != null:
return failure(_that.offset,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int offset)  loading,required TResult Function( int offset,  ActivityPeriod period)  loaded,required TResult Function( int offset,  Failure failure)  failure,}) {final _that = this;
switch (_that) {
case PeriodActivityLoading():
return loading(_that.offset);case PeriodActivityLoaded():
return loaded(_that.offset,_that.period);case PeriodActivityFailure():
return failure(_that.offset,_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int offset)?  loading,TResult? Function( int offset,  ActivityPeriod period)?  loaded,TResult? Function( int offset,  Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case PeriodActivityLoading() when loading != null:
return loading(_that.offset);case PeriodActivityLoaded() when loaded != null:
return loaded(_that.offset,_that.period);case PeriodActivityFailure() when failure != null:
return failure(_that.offset,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PeriodActivityLoading implements PeriodActivityState {
  const PeriodActivityLoading(this.offset);
  

@override final  int offset;

/// Create a copy of PeriodActivityState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodActivityLoadingCopyWith<PeriodActivityLoading> get copyWith => _$PeriodActivityLoadingCopyWithImpl<PeriodActivityLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodActivityLoading&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,offset);

@override
String toString() {
  return 'PeriodActivityState.loading(offset: $offset)';
}


}

/// @nodoc
abstract mixin class $PeriodActivityLoadingCopyWith<$Res> implements $PeriodActivityStateCopyWith<$Res> {
  factory $PeriodActivityLoadingCopyWith(PeriodActivityLoading value, $Res Function(PeriodActivityLoading) _then) = _$PeriodActivityLoadingCopyWithImpl;
@override @useResult
$Res call({
 int offset
});




}
/// @nodoc
class _$PeriodActivityLoadingCopyWithImpl<$Res>
    implements $PeriodActivityLoadingCopyWith<$Res> {
  _$PeriodActivityLoadingCopyWithImpl(this._self, this._then);

  final PeriodActivityLoading _self;
  final $Res Function(PeriodActivityLoading) _then;

/// Create a copy of PeriodActivityState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? offset = null,}) {
  return _then(PeriodActivityLoading(
null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class PeriodActivityLoaded implements PeriodActivityState {
  const PeriodActivityLoaded(this.offset, this.period);
  

@override final  int offset;
 final  ActivityPeriod period;

/// Create a copy of PeriodActivityState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodActivityLoadedCopyWith<PeriodActivityLoaded> get copyWith => _$PeriodActivityLoadedCopyWithImpl<PeriodActivityLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodActivityLoaded&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.period, period) || other.period == period));
}


@override
int get hashCode => Object.hash(runtimeType,offset,period);

@override
String toString() {
  return 'PeriodActivityState.loaded(offset: $offset, period: $period)';
}


}

/// @nodoc
abstract mixin class $PeriodActivityLoadedCopyWith<$Res> implements $PeriodActivityStateCopyWith<$Res> {
  factory $PeriodActivityLoadedCopyWith(PeriodActivityLoaded value, $Res Function(PeriodActivityLoaded) _then) = _$PeriodActivityLoadedCopyWithImpl;
@override @useResult
$Res call({
 int offset, ActivityPeriod period
});


$ActivityPeriodCopyWith<$Res> get period;

}
/// @nodoc
class _$PeriodActivityLoadedCopyWithImpl<$Res>
    implements $PeriodActivityLoadedCopyWith<$Res> {
  _$PeriodActivityLoadedCopyWithImpl(this._self, this._then);

  final PeriodActivityLoaded _self;
  final $Res Function(PeriodActivityLoaded) _then;

/// Create a copy of PeriodActivityState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? offset = null,Object? period = null,}) {
  return _then(PeriodActivityLoaded(
null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as ActivityPeriod,
  ));
}

/// Create a copy of PeriodActivityState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityPeriodCopyWith<$Res> get period {
  
  return $ActivityPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}
}

/// @nodoc


class PeriodActivityFailure implements PeriodActivityState {
  const PeriodActivityFailure(this.offset, this.failure);
  

@override final  int offset;
 final  Failure failure;

/// Create a copy of PeriodActivityState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodActivityFailureCopyWith<PeriodActivityFailure> get copyWith => _$PeriodActivityFailureCopyWithImpl<PeriodActivityFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodActivityFailure&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,offset,failure);

@override
String toString() {
  return 'PeriodActivityState.failure(offset: $offset, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PeriodActivityFailureCopyWith<$Res> implements $PeriodActivityStateCopyWith<$Res> {
  factory $PeriodActivityFailureCopyWith(PeriodActivityFailure value, $Res Function(PeriodActivityFailure) _then) = _$PeriodActivityFailureCopyWithImpl;
@override @useResult
$Res call({
 int offset, Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PeriodActivityFailureCopyWithImpl<$Res>
    implements $PeriodActivityFailureCopyWith<$Res> {
  _$PeriodActivityFailureCopyWithImpl(this._self, this._then);

  final PeriodActivityFailure _self;
  final $Res Function(PeriodActivityFailure) _then;

/// Create a copy of PeriodActivityState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? offset = null,Object? failure = null,}) {
  return _then(PeriodActivityFailure(
null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PeriodActivityState
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
