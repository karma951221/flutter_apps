// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkDetailState()';
}


}

/// @nodoc
class $WalkDetailStateCopyWith<$Res>  {
$WalkDetailStateCopyWith(WalkDetailState _, $Res Function(WalkDetailState) __);
}


/// Adds pattern-matching-related methods to [WalkDetailState].
extension WalkDetailStatePatterns on WalkDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WalkDetailLoading value)?  loading,TResult Function( WalkDetailLoaded value)?  loaded,TResult Function( WalkDetailDeleting value)?  deleting,TResult Function( WalkDetailDeleted value)?  deleted,TResult Function( WalkDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WalkDetailLoading() when loading != null:
return loading(_that);case WalkDetailLoaded() when loaded != null:
return loaded(_that);case WalkDetailDeleting() when deleting != null:
return deleting(_that);case WalkDetailDeleted() when deleted != null:
return deleted(_that);case WalkDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WalkDetailLoading value)  loading,required TResult Function( WalkDetailLoaded value)  loaded,required TResult Function( WalkDetailDeleting value)  deleting,required TResult Function( WalkDetailDeleted value)  deleted,required TResult Function( WalkDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case WalkDetailLoading():
return loading(_that);case WalkDetailLoaded():
return loaded(_that);case WalkDetailDeleting():
return deleting(_that);case WalkDetailDeleted():
return deleted(_that);case WalkDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WalkDetailLoading value)?  loading,TResult? Function( WalkDetailLoaded value)?  loaded,TResult? Function( WalkDetailDeleting value)?  deleting,TResult? Function( WalkDetailDeleted value)?  deleted,TResult? Function( WalkDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case WalkDetailLoading() when loading != null:
return loading(_that);case WalkDetailLoaded() when loaded != null:
return loaded(_that);case WalkDetailDeleting() when deleting != null:
return deleting(_that);case WalkDetailDeleted() when deleted != null:
return deleted(_that);case WalkDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Walk walk,  List<WalkTrackPoint> track,  Failure? failure)?  loaded,TResult Function( Walk walk,  List<WalkTrackPoint> track)?  deleting,TResult Function()?  deleted,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WalkDetailLoading() when loading != null:
return loading();case WalkDetailLoaded() when loaded != null:
return loaded(_that.walk,_that.track,_that.failure);case WalkDetailDeleting() when deleting != null:
return deleting(_that.walk,_that.track);case WalkDetailDeleted() when deleted != null:
return deleted();case WalkDetailFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Walk walk,  List<WalkTrackPoint> track,  Failure? failure)  loaded,required TResult Function( Walk walk,  List<WalkTrackPoint> track)  deleting,required TResult Function()  deleted,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case WalkDetailLoading():
return loading();case WalkDetailLoaded():
return loaded(_that.walk,_that.track,_that.failure);case WalkDetailDeleting():
return deleting(_that.walk,_that.track);case WalkDetailDeleted():
return deleted();case WalkDetailFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Walk walk,  List<WalkTrackPoint> track,  Failure? failure)?  loaded,TResult? Function( Walk walk,  List<WalkTrackPoint> track)?  deleting,TResult? Function()?  deleted,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case WalkDetailLoading() when loading != null:
return loading();case WalkDetailLoaded() when loaded != null:
return loaded(_that.walk,_that.track,_that.failure);case WalkDetailDeleting() when deleting != null:
return deleting(_that.walk,_that.track);case WalkDetailDeleted() when deleted != null:
return deleted();case WalkDetailFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class WalkDetailLoading implements WalkDetailState {
  const WalkDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkDetailState.loading()';
}


}




/// @nodoc


class WalkDetailLoaded implements WalkDetailState {
  const WalkDetailLoaded({required this.walk, required final  List<WalkTrackPoint> track, this.failure}): _track = track;
  

 final  Walk walk;
 final  List<WalkTrackPoint> _track;
 List<WalkTrackPoint> get track {
  if (_track is EqualUnmodifiableListView) return _track;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_track);
}

 final  Failure? failure;

/// Create a copy of WalkDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkDetailLoadedCopyWith<WalkDetailLoaded> get copyWith => _$WalkDetailLoadedCopyWithImpl<WalkDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkDetailLoaded&&(identical(other.walk, walk) || other.walk == walk)&&const DeepCollectionEquality().equals(other._track, _track)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,walk,const DeepCollectionEquality().hash(_track),failure);

@override
String toString() {
  return 'WalkDetailState.loaded(walk: $walk, track: $track, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $WalkDetailLoadedCopyWith<$Res> implements $WalkDetailStateCopyWith<$Res> {
  factory $WalkDetailLoadedCopyWith(WalkDetailLoaded value, $Res Function(WalkDetailLoaded) _then) = _$WalkDetailLoadedCopyWithImpl;
@useResult
$Res call({
 Walk walk, List<WalkTrackPoint> track, Failure? failure
});


$WalkCopyWith<$Res> get walk;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$WalkDetailLoadedCopyWithImpl<$Res>
    implements $WalkDetailLoadedCopyWith<$Res> {
  _$WalkDetailLoadedCopyWithImpl(this._self, this._then);

  final WalkDetailLoaded _self;
  final $Res Function(WalkDetailLoaded) _then;

/// Create a copy of WalkDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? walk = null,Object? track = null,Object? failure = freezed,}) {
  return _then(WalkDetailLoaded(
walk: null == walk ? _self.walk : walk // ignore: cast_nullable_to_non_nullable
as Walk,track: null == track ? _self._track : track // ignore: cast_nullable_to_non_nullable
as List<WalkTrackPoint>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of WalkDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalkCopyWith<$Res> get walk {
  
  return $WalkCopyWith<$Res>(_self.walk, (value) {
    return _then(_self.copyWith(walk: value));
  });
}/// Create a copy of WalkDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class WalkDetailDeleting implements WalkDetailState {
  const WalkDetailDeleting({required this.walk, required final  List<WalkTrackPoint> track}): _track = track;
  

 final  Walk walk;
 final  List<WalkTrackPoint> _track;
 List<WalkTrackPoint> get track {
  if (_track is EqualUnmodifiableListView) return _track;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_track);
}


/// Create a copy of WalkDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkDetailDeletingCopyWith<WalkDetailDeleting> get copyWith => _$WalkDetailDeletingCopyWithImpl<WalkDetailDeleting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkDetailDeleting&&(identical(other.walk, walk) || other.walk == walk)&&const DeepCollectionEquality().equals(other._track, _track));
}


@override
int get hashCode => Object.hash(runtimeType,walk,const DeepCollectionEquality().hash(_track));

@override
String toString() {
  return 'WalkDetailState.deleting(walk: $walk, track: $track)';
}


}

/// @nodoc
abstract mixin class $WalkDetailDeletingCopyWith<$Res> implements $WalkDetailStateCopyWith<$Res> {
  factory $WalkDetailDeletingCopyWith(WalkDetailDeleting value, $Res Function(WalkDetailDeleting) _then) = _$WalkDetailDeletingCopyWithImpl;
@useResult
$Res call({
 Walk walk, List<WalkTrackPoint> track
});


$WalkCopyWith<$Res> get walk;

}
/// @nodoc
class _$WalkDetailDeletingCopyWithImpl<$Res>
    implements $WalkDetailDeletingCopyWith<$Res> {
  _$WalkDetailDeletingCopyWithImpl(this._self, this._then);

  final WalkDetailDeleting _self;
  final $Res Function(WalkDetailDeleting) _then;

/// Create a copy of WalkDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? walk = null,Object? track = null,}) {
  return _then(WalkDetailDeleting(
walk: null == walk ? _self.walk : walk // ignore: cast_nullable_to_non_nullable
as Walk,track: null == track ? _self._track : track // ignore: cast_nullable_to_non_nullable
as List<WalkTrackPoint>,
  ));
}

/// Create a copy of WalkDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalkCopyWith<$Res> get walk {
  
  return $WalkCopyWith<$Res>(_self.walk, (value) {
    return _then(_self.copyWith(walk: value));
  });
}
}

/// @nodoc


class WalkDetailDeleted implements WalkDetailState {
  const WalkDetailDeleted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkDetailDeleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkDetailState.deleted()';
}


}




/// @nodoc


class WalkDetailFailure implements WalkDetailState {
  const WalkDetailFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of WalkDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkDetailFailureCopyWith<WalkDetailFailure> get copyWith => _$WalkDetailFailureCopyWithImpl<WalkDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkDetailFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'WalkDetailState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $WalkDetailFailureCopyWith<$Res> implements $WalkDetailStateCopyWith<$Res> {
  factory $WalkDetailFailureCopyWith(WalkDetailFailure value, $Res Function(WalkDetailFailure) _then) = _$WalkDetailFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$WalkDetailFailureCopyWithImpl<$Res>
    implements $WalkDetailFailureCopyWith<$Res> {
  _$WalkDetailFailureCopyWithImpl(this._self, this._then);

  final WalkDetailFailure _self;
  final $Res Function(WalkDetailFailure) _then;

/// Create a copy of WalkDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(WalkDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of WalkDetailState
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
