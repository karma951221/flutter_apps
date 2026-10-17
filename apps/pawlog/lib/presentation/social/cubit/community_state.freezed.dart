// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommunityState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommunityState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommunityState()';
}


}

/// @nodoc
class $CommunityStateCopyWith<$Res>  {
$CommunityStateCopyWith(CommunityState _, $Res Function(CommunityState) __);
}


/// Adds pattern-matching-related methods to [CommunityState].
extension CommunityStatePatterns on CommunityState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CommunityUnavailable value)?  unavailable,TResult Function( CommunityLoading value)?  loading,TResult Function( CommunityLoaded value)?  loaded,TResult Function( CommunityFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CommunityUnavailable() when unavailable != null:
return unavailable(_that);case CommunityLoading() when loading != null:
return loading(_that);case CommunityLoaded() when loaded != null:
return loaded(_that);case CommunityFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CommunityUnavailable value)  unavailable,required TResult Function( CommunityLoading value)  loading,required TResult Function( CommunityLoaded value)  loaded,required TResult Function( CommunityFailure value)  failure,}){
final _that = this;
switch (_that) {
case CommunityUnavailable():
return unavailable(_that);case CommunityLoading():
return loading(_that);case CommunityLoaded():
return loaded(_that);case CommunityFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CommunityUnavailable value)?  unavailable,TResult? Function( CommunityLoading value)?  loading,TResult? Function( CommunityLoaded value)?  loaded,TResult? Function( CommunityFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CommunityUnavailable() when unavailable != null:
return unavailable(_that);case CommunityLoading() when loading != null:
return loading(_that);case CommunityLoaded() when loaded != null:
return loaded(_that);case CommunityFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  unavailable,TResult Function( bool isSignedIn)?  loading,TResult Function( List<WalkPost> posts,  bool isSignedIn,  String? nextCursor,  bool isLoadingMore,  Failure? failure)?  loaded,TResult Function( Failure failure,  bool isSignedIn)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CommunityUnavailable() when unavailable != null:
return unavailable();case CommunityLoading() when loading != null:
return loading(_that.isSignedIn);case CommunityLoaded() when loaded != null:
return loaded(_that.posts,_that.isSignedIn,_that.nextCursor,_that.isLoadingMore,_that.failure);case CommunityFailure() when failure != null:
return failure(_that.failure,_that.isSignedIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  unavailable,required TResult Function( bool isSignedIn)  loading,required TResult Function( List<WalkPost> posts,  bool isSignedIn,  String? nextCursor,  bool isLoadingMore,  Failure? failure)  loaded,required TResult Function( Failure failure,  bool isSignedIn)  failure,}) {final _that = this;
switch (_that) {
case CommunityUnavailable():
return unavailable();case CommunityLoading():
return loading(_that.isSignedIn);case CommunityLoaded():
return loaded(_that.posts,_that.isSignedIn,_that.nextCursor,_that.isLoadingMore,_that.failure);case CommunityFailure():
return failure(_that.failure,_that.isSignedIn);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  unavailable,TResult? Function( bool isSignedIn)?  loading,TResult? Function( List<WalkPost> posts,  bool isSignedIn,  String? nextCursor,  bool isLoadingMore,  Failure? failure)?  loaded,TResult? Function( Failure failure,  bool isSignedIn)?  failure,}) {final _that = this;
switch (_that) {
case CommunityUnavailable() when unavailable != null:
return unavailable();case CommunityLoading() when loading != null:
return loading(_that.isSignedIn);case CommunityLoaded() when loaded != null:
return loaded(_that.posts,_that.isSignedIn,_that.nextCursor,_that.isLoadingMore,_that.failure);case CommunityFailure() when failure != null:
return failure(_that.failure,_that.isSignedIn);case _:
  return null;

}
}

}

/// @nodoc


class CommunityUnavailable implements CommunityState {
  const CommunityUnavailable();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommunityUnavailable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommunityState.unavailable()';
}


}




/// @nodoc


class CommunityLoading implements CommunityState {
  const CommunityLoading({required this.isSignedIn});
  

 final  bool isSignedIn;

/// Create a copy of CommunityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommunityLoadingCopyWith<CommunityLoading> get copyWith => _$CommunityLoadingCopyWithImpl<CommunityLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommunityLoading&&(identical(other.isSignedIn, isSignedIn) || other.isSignedIn == isSignedIn));
}


@override
int get hashCode => Object.hash(runtimeType,isSignedIn);

@override
String toString() {
  return 'CommunityState.loading(isSignedIn: $isSignedIn)';
}


}

/// @nodoc
abstract mixin class $CommunityLoadingCopyWith<$Res> implements $CommunityStateCopyWith<$Res> {
  factory $CommunityLoadingCopyWith(CommunityLoading value, $Res Function(CommunityLoading) _then) = _$CommunityLoadingCopyWithImpl;
@useResult
$Res call({
 bool isSignedIn
});




}
/// @nodoc
class _$CommunityLoadingCopyWithImpl<$Res>
    implements $CommunityLoadingCopyWith<$Res> {
  _$CommunityLoadingCopyWithImpl(this._self, this._then);

  final CommunityLoading _self;
  final $Res Function(CommunityLoading) _then;

/// Create a copy of CommunityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isSignedIn = null,}) {
  return _then(CommunityLoading(
isSignedIn: null == isSignedIn ? _self.isSignedIn : isSignedIn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class CommunityLoaded implements CommunityState {
  const CommunityLoaded({required final  List<WalkPost> posts, required this.isSignedIn, this.nextCursor, this.isLoadingMore = false, this.failure}): _posts = posts;
  

 final  List<WalkPost> _posts;
 List<WalkPost> get posts {
  if (_posts is EqualUnmodifiableListView) return _posts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_posts);
}

 final  bool isSignedIn;
 final  String? nextCursor;
@JsonKey() final  bool isLoadingMore;
 final  Failure? failure;

/// Create a copy of CommunityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommunityLoadedCopyWith<CommunityLoaded> get copyWith => _$CommunityLoadedCopyWithImpl<CommunityLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommunityLoaded&&const DeepCollectionEquality().equals(other._posts, _posts)&&(identical(other.isSignedIn, isSignedIn) || other.isSignedIn == isSignedIn)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_posts),isSignedIn,nextCursor,isLoadingMore,failure);

@override
String toString() {
  return 'CommunityState.loaded(posts: $posts, isSignedIn: $isSignedIn, nextCursor: $nextCursor, isLoadingMore: $isLoadingMore, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CommunityLoadedCopyWith<$Res> implements $CommunityStateCopyWith<$Res> {
  factory $CommunityLoadedCopyWith(CommunityLoaded value, $Res Function(CommunityLoaded) _then) = _$CommunityLoadedCopyWithImpl;
@useResult
$Res call({
 List<WalkPost> posts, bool isSignedIn, String? nextCursor, bool isLoadingMore, Failure? failure
});


$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$CommunityLoadedCopyWithImpl<$Res>
    implements $CommunityLoadedCopyWith<$Res> {
  _$CommunityLoadedCopyWithImpl(this._self, this._then);

  final CommunityLoaded _self;
  final $Res Function(CommunityLoaded) _then;

/// Create a copy of CommunityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? posts = null,Object? isSignedIn = null,Object? nextCursor = freezed,Object? isLoadingMore = null,Object? failure = freezed,}) {
  return _then(CommunityLoaded(
posts: null == posts ? _self._posts : posts // ignore: cast_nullable_to_non_nullable
as List<WalkPost>,isSignedIn: null == isSignedIn ? _self.isSignedIn : isSignedIn // ignore: cast_nullable_to_non_nullable
as bool,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of CommunityState
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


class CommunityFailure implements CommunityState {
  const CommunityFailure(this.failure, {required this.isSignedIn});
  

 final  Failure failure;
 final  bool isSignedIn;

/// Create a copy of CommunityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommunityFailureCopyWith<CommunityFailure> get copyWith => _$CommunityFailureCopyWithImpl<CommunityFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommunityFailure&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.isSignedIn, isSignedIn) || other.isSignedIn == isSignedIn));
}


@override
int get hashCode => Object.hash(runtimeType,failure,isSignedIn);

@override
String toString() {
  return 'CommunityState.failure(failure: $failure, isSignedIn: $isSignedIn)';
}


}

/// @nodoc
abstract mixin class $CommunityFailureCopyWith<$Res> implements $CommunityStateCopyWith<$Res> {
  factory $CommunityFailureCopyWith(CommunityFailure value, $Res Function(CommunityFailure) _then) = _$CommunityFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure, bool isSignedIn
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CommunityFailureCopyWithImpl<$Res>
    implements $CommunityFailureCopyWith<$Res> {
  _$CommunityFailureCopyWithImpl(this._self, this._then);

  final CommunityFailure _self;
  final $Res Function(CommunityFailure) _then;

/// Create a copy of CommunityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? isSignedIn = null,}) {
  return _then(CommunityFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,isSignedIn: null == isSignedIn ? _self.isSignedIn : isSignedIn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CommunityState
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
