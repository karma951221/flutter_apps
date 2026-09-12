// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TradeHomeState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeHomeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TradeHomeState()';
}


}

/// @nodoc
class $TradeHomeStateCopyWith<$Res>  {
$TradeHomeStateCopyWith(TradeHomeState _, $Res Function(TradeHomeState) __);
}


/// Adds pattern-matching-related methods to [TradeHomeState].
extension TradeHomeStatePatterns on TradeHomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TradeHomeLoading value)?  loading,TResult Function( TradeHomeLoaded value)?  loaded,TResult Function( TradeHomeFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TradeHomeLoading() when loading != null:
return loading(_that);case TradeHomeLoaded() when loaded != null:
return loaded(_that);case TradeHomeFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TradeHomeLoading value)  loading,required TResult Function( TradeHomeLoaded value)  loaded,required TResult Function( TradeHomeFailure value)  failure,}){
final _that = this;
switch (_that) {
case TradeHomeLoading():
return loading(_that);case TradeHomeLoaded():
return loaded(_that);case TradeHomeFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TradeHomeLoading value)?  loading,TResult? Function( TradeHomeLoaded value)?  loaded,TResult? Function( TradeHomeFailure value)?  failure,}){
final _that = this;
switch (_that) {
case TradeHomeLoading() when loading != null:
return loading(_that);case TradeHomeLoaded() when loaded != null:
return loaded(_that);case TradeHomeFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( TradeSession? active,  List<TradeSessionSummary> past,  String? nextCursor,  bool isLoadingMore,  bool isStarting)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TradeHomeLoading() when loading != null:
return loading();case TradeHomeLoaded() when loaded != null:
return loaded(_that.active,_that.past,_that.nextCursor,_that.isLoadingMore,_that.isStarting);case TradeHomeFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( TradeSession? active,  List<TradeSessionSummary> past,  String? nextCursor,  bool isLoadingMore,  bool isStarting)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case TradeHomeLoading():
return loading();case TradeHomeLoaded():
return loaded(_that.active,_that.past,_that.nextCursor,_that.isLoadingMore,_that.isStarting);case TradeHomeFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( TradeSession? active,  List<TradeSessionSummary> past,  String? nextCursor,  bool isLoadingMore,  bool isStarting)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case TradeHomeLoading() when loading != null:
return loading();case TradeHomeLoaded() when loaded != null:
return loaded(_that.active,_that.past,_that.nextCursor,_that.isLoadingMore,_that.isStarting);case TradeHomeFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class TradeHomeLoading extends TradeHomeState {
  const TradeHomeLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeHomeLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TradeHomeState.loading()';
}


}




/// @nodoc


class TradeHomeLoaded extends TradeHomeState {
  const TradeHomeLoaded({this.active, final  List<TradeSessionSummary> past = const <TradeSessionSummary>[], this.nextCursor, this.isLoadingMore = false, this.isStarting = false}): _past = past,super._();
  

 final  TradeSession? active;
 final  List<TradeSessionSummary> _past;
@JsonKey() List<TradeSessionSummary> get past {
  if (_past is EqualUnmodifiableListView) return _past;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_past);
}

 final  String? nextCursor;
@JsonKey() final  bool isLoadingMore;
@JsonKey() final  bool isStarting;

/// Create a copy of TradeHomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeHomeLoadedCopyWith<TradeHomeLoaded> get copyWith => _$TradeHomeLoadedCopyWithImpl<TradeHomeLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeHomeLoaded&&(identical(other.active, active) || other.active == active)&&const DeepCollectionEquality().equals(other._past, _past)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.isStarting, isStarting) || other.isStarting == isStarting));
}


@override
int get hashCode => Object.hash(runtimeType,active,const DeepCollectionEquality().hash(_past),nextCursor,isLoadingMore,isStarting);

@override
String toString() {
  return 'TradeHomeState.loaded(active: $active, past: $past, nextCursor: $nextCursor, isLoadingMore: $isLoadingMore, isStarting: $isStarting)';
}


}

/// @nodoc
abstract mixin class $TradeHomeLoadedCopyWith<$Res> implements $TradeHomeStateCopyWith<$Res> {
  factory $TradeHomeLoadedCopyWith(TradeHomeLoaded value, $Res Function(TradeHomeLoaded) _then) = _$TradeHomeLoadedCopyWithImpl;
@useResult
$Res call({
 TradeSession? active, List<TradeSessionSummary> past, String? nextCursor, bool isLoadingMore, bool isStarting
});


$TradeSessionCopyWith<$Res>? get active;

}
/// @nodoc
class _$TradeHomeLoadedCopyWithImpl<$Res>
    implements $TradeHomeLoadedCopyWith<$Res> {
  _$TradeHomeLoadedCopyWithImpl(this._self, this._then);

  final TradeHomeLoaded _self;
  final $Res Function(TradeHomeLoaded) _then;

/// Create a copy of TradeHomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? active = freezed,Object? past = null,Object? nextCursor = freezed,Object? isLoadingMore = null,Object? isStarting = null,}) {
  return _then(TradeHomeLoaded(
active: freezed == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as TradeSession?,past: null == past ? _self._past : past // ignore: cast_nullable_to_non_nullable
as List<TradeSessionSummary>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,isStarting: null == isStarting ? _self.isStarting : isStarting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TradeHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TradeSessionCopyWith<$Res>? get active {
    if (_self.active == null) {
    return null;
  }

  return $TradeSessionCopyWith<$Res>(_self.active!, (value) {
    return _then(_self.copyWith(active: value));
  });
}
}

/// @nodoc


class TradeHomeFailure extends TradeHomeState {
  const TradeHomeFailure(this.failure): super._();
  

 final  Failure failure;

/// Create a copy of TradeHomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeHomeFailureCopyWith<TradeHomeFailure> get copyWith => _$TradeHomeFailureCopyWithImpl<TradeHomeFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeHomeFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TradeHomeState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TradeHomeFailureCopyWith<$Res> implements $TradeHomeStateCopyWith<$Res> {
  factory $TradeHomeFailureCopyWith(TradeHomeFailure value, $Res Function(TradeHomeFailure) _then) = _$TradeHomeFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$TradeHomeFailureCopyWithImpl<$Res>
    implements $TradeHomeFailureCopyWith<$Res> {
  _$TradeHomeFailureCopyWithImpl(this._self, this._then);

  final TradeHomeFailure _self;
  final $Res Function(TradeHomeFailure) _then;

/// Create a copy of TradeHomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TradeHomeFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of TradeHomeState
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
