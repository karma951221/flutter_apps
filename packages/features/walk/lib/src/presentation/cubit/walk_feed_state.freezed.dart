// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_feed_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkFeedState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkFeedState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkFeedState()';
}


}

/// @nodoc
class $WalkFeedStateCopyWith<$Res>  {
$WalkFeedStateCopyWith(WalkFeedState _, $Res Function(WalkFeedState) __);
}


/// Adds pattern-matching-related methods to [WalkFeedState].
extension WalkFeedStatePatterns on WalkFeedState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WalkFeedLoading value)?  loading,TResult Function( WalkFeedLoaded value)?  loaded,TResult Function( WalkFeedFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WalkFeedLoading() when loading != null:
return loading(_that);case WalkFeedLoaded() when loaded != null:
return loaded(_that);case WalkFeedFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WalkFeedLoading value)  loading,required TResult Function( WalkFeedLoaded value)  loaded,required TResult Function( WalkFeedFailure value)  failure,}){
final _that = this;
switch (_that) {
case WalkFeedLoading():
return loading(_that);case WalkFeedLoaded():
return loaded(_that);case WalkFeedFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WalkFeedLoading value)?  loading,TResult? Function( WalkFeedLoaded value)?  loaded,TResult? Function( WalkFeedFailure value)?  failure,}){
final _that = this;
switch (_that) {
case WalkFeedLoading() when loading != null:
return loading(_that);case WalkFeedLoaded() when loaded != null:
return loaded(_that);case WalkFeedFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<Walk> walks,  TrackerState tracker)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WalkFeedLoading() when loading != null:
return loading();case WalkFeedLoaded() when loaded != null:
return loaded(_that.walks,_that.tracker);case WalkFeedFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<Walk> walks,  TrackerState tracker)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case WalkFeedLoading():
return loading();case WalkFeedLoaded():
return loaded(_that.walks,_that.tracker);case WalkFeedFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<Walk> walks,  TrackerState tracker)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case WalkFeedLoading() when loading != null:
return loading();case WalkFeedLoaded() when loaded != null:
return loaded(_that.walks,_that.tracker);case WalkFeedFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class WalkFeedLoading implements WalkFeedState {
  const WalkFeedLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkFeedLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WalkFeedState.loading()';
}


}




/// @nodoc


class WalkFeedLoaded implements WalkFeedState {
  const WalkFeedLoaded({required final  List<Walk> walks, required this.tracker}): _walks = walks;
  

 final  List<Walk> _walks;
 List<Walk> get walks {
  if (_walks is EqualUnmodifiableListView) return _walks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_walks);
}

 final  TrackerState tracker;

/// Create a copy of WalkFeedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkFeedLoadedCopyWith<WalkFeedLoaded> get copyWith => _$WalkFeedLoadedCopyWithImpl<WalkFeedLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkFeedLoaded&&const DeepCollectionEquality().equals(other._walks, _walks)&&(identical(other.tracker, tracker) || other.tracker == tracker));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_walks),tracker);

@override
String toString() {
  return 'WalkFeedState.loaded(walks: $walks, tracker: $tracker)';
}


}

/// @nodoc
abstract mixin class $WalkFeedLoadedCopyWith<$Res> implements $WalkFeedStateCopyWith<$Res> {
  factory $WalkFeedLoadedCopyWith(WalkFeedLoaded value, $Res Function(WalkFeedLoaded) _then) = _$WalkFeedLoadedCopyWithImpl;
@useResult
$Res call({
 List<Walk> walks, TrackerState tracker
});


$TrackerStateCopyWith<$Res> get tracker;

}
/// @nodoc
class _$WalkFeedLoadedCopyWithImpl<$Res>
    implements $WalkFeedLoadedCopyWith<$Res> {
  _$WalkFeedLoadedCopyWithImpl(this._self, this._then);

  final WalkFeedLoaded _self;
  final $Res Function(WalkFeedLoaded) _then;

/// Create a copy of WalkFeedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? walks = null,Object? tracker = null,}) {
  return _then(WalkFeedLoaded(
walks: null == walks ? _self._walks : walks // ignore: cast_nullable_to_non_nullable
as List<Walk>,tracker: null == tracker ? _self.tracker : tracker // ignore: cast_nullable_to_non_nullable
as TrackerState,
  ));
}

/// Create a copy of WalkFeedState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackerStateCopyWith<$Res> get tracker {
  
  return $TrackerStateCopyWith<$Res>(_self.tracker, (value) {
    return _then(_self.copyWith(tracker: value));
  });
}
}

/// @nodoc


class WalkFeedFailure implements WalkFeedState {
  const WalkFeedFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of WalkFeedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkFeedFailureCopyWith<WalkFeedFailure> get copyWith => _$WalkFeedFailureCopyWithImpl<WalkFeedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkFeedFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'WalkFeedState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $WalkFeedFailureCopyWith<$Res> implements $WalkFeedStateCopyWith<$Res> {
  factory $WalkFeedFailureCopyWith(WalkFeedFailure value, $Res Function(WalkFeedFailure) _then) = _$WalkFeedFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$WalkFeedFailureCopyWithImpl<$Res>
    implements $WalkFeedFailureCopyWith<$Res> {
  _$WalkFeedFailureCopyWithImpl(this._self, this._then);

  final WalkFeedFailure _self;
  final $Res Function(WalkFeedFailure) _then;

/// Create a copy of WalkFeedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(WalkFeedFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of WalkFeedState
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
