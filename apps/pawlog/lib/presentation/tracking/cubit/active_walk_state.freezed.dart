// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_walk_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActiveWalkState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveWalkState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ActiveWalkState()';
}


}

/// @nodoc
class $ActiveWalkStateCopyWith<$Res>  {
$ActiveWalkStateCopyWith(ActiveWalkState _, $Res Function(ActiveWalkState) __);
}


/// Adds pattern-matching-related methods to [ActiveWalkState].
extension ActiveWalkStatePatterns on ActiveWalkState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ActiveWalkLoading value)?  loading,TResult Function( ActiveWalkSelectingDogs value)?  selectingDogs,TResult Function( ActiveWalkStarting value)?  starting,TResult Function( ActiveWalkTracking value)?  tracking,TResult Function( ActiveWalkStopped value)?  stopped,TResult Function( ActiveWalkFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ActiveWalkLoading() when loading != null:
return loading(_that);case ActiveWalkSelectingDogs() when selectingDogs != null:
return selectingDogs(_that);case ActiveWalkStarting() when starting != null:
return starting(_that);case ActiveWalkTracking() when tracking != null:
return tracking(_that);case ActiveWalkStopped() when stopped != null:
return stopped(_that);case ActiveWalkFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ActiveWalkLoading value)  loading,required TResult Function( ActiveWalkSelectingDogs value)  selectingDogs,required TResult Function( ActiveWalkStarting value)  starting,required TResult Function( ActiveWalkTracking value)  tracking,required TResult Function( ActiveWalkStopped value)  stopped,required TResult Function( ActiveWalkFailure value)  failure,}){
final _that = this;
switch (_that) {
case ActiveWalkLoading():
return loading(_that);case ActiveWalkSelectingDogs():
return selectingDogs(_that);case ActiveWalkStarting():
return starting(_that);case ActiveWalkTracking():
return tracking(_that);case ActiveWalkStopped():
return stopped(_that);case ActiveWalkFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ActiveWalkLoading value)?  loading,TResult? Function( ActiveWalkSelectingDogs value)?  selectingDogs,TResult? Function( ActiveWalkStarting value)?  starting,TResult? Function( ActiveWalkTracking value)?  tracking,TResult? Function( ActiveWalkStopped value)?  stopped,TResult? Function( ActiveWalkFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ActiveWalkLoading() when loading != null:
return loading(_that);case ActiveWalkSelectingDogs() when selectingDogs != null:
return selectingDogs(_that);case ActiveWalkStarting() when starting != null:
return starting(_that);case ActiveWalkTracking() when tracking != null:
return tracking(_that);case ActiveWalkStopped() when stopped != null:
return stopped(_that);case ActiveWalkFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<Dog> dogs,  Set<String> selectedIds)?  selectingDogs,TResult Function( List<Dog> dogs,  Set<String> selectedIds)?  starting,TResult Function( WalkSession session,  Duration elapsed)?  tracking,TResult Function( WalkSession session)?  stopped,TResult Function( Failure failure,  List<Dog> dogs,  Set<String> selectedIds)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ActiveWalkLoading() when loading != null:
return loading();case ActiveWalkSelectingDogs() when selectingDogs != null:
return selectingDogs(_that.dogs,_that.selectedIds);case ActiveWalkStarting() when starting != null:
return starting(_that.dogs,_that.selectedIds);case ActiveWalkTracking() when tracking != null:
return tracking(_that.session,_that.elapsed);case ActiveWalkStopped() when stopped != null:
return stopped(_that.session);case ActiveWalkFailure() when failure != null:
return failure(_that.failure,_that.dogs,_that.selectedIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<Dog> dogs,  Set<String> selectedIds)  selectingDogs,required TResult Function( List<Dog> dogs,  Set<String> selectedIds)  starting,required TResult Function( WalkSession session,  Duration elapsed)  tracking,required TResult Function( WalkSession session)  stopped,required TResult Function( Failure failure,  List<Dog> dogs,  Set<String> selectedIds)  failure,}) {final _that = this;
switch (_that) {
case ActiveWalkLoading():
return loading();case ActiveWalkSelectingDogs():
return selectingDogs(_that.dogs,_that.selectedIds);case ActiveWalkStarting():
return starting(_that.dogs,_that.selectedIds);case ActiveWalkTracking():
return tracking(_that.session,_that.elapsed);case ActiveWalkStopped():
return stopped(_that.session);case ActiveWalkFailure():
return failure(_that.failure,_that.dogs,_that.selectedIds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<Dog> dogs,  Set<String> selectedIds)?  selectingDogs,TResult? Function( List<Dog> dogs,  Set<String> selectedIds)?  starting,TResult? Function( WalkSession session,  Duration elapsed)?  tracking,TResult? Function( WalkSession session)?  stopped,TResult? Function( Failure failure,  List<Dog> dogs,  Set<String> selectedIds)?  failure,}) {final _that = this;
switch (_that) {
case ActiveWalkLoading() when loading != null:
return loading();case ActiveWalkSelectingDogs() when selectingDogs != null:
return selectingDogs(_that.dogs,_that.selectedIds);case ActiveWalkStarting() when starting != null:
return starting(_that.dogs,_that.selectedIds);case ActiveWalkTracking() when tracking != null:
return tracking(_that.session,_that.elapsed);case ActiveWalkStopped() when stopped != null:
return stopped(_that.session);case ActiveWalkFailure() when failure != null:
return failure(_that.failure,_that.dogs,_that.selectedIds);case _:
  return null;

}
}

}

/// @nodoc


class ActiveWalkLoading implements ActiveWalkState {
  const ActiveWalkLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveWalkLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ActiveWalkState.loading()';
}


}




/// @nodoc


class ActiveWalkSelectingDogs implements ActiveWalkState {
  const ActiveWalkSelectingDogs({required final  List<Dog> dogs, required final  Set<String> selectedIds}): _dogs = dogs,_selectedIds = selectedIds;
  

 final  List<Dog> _dogs;
 List<Dog> get dogs {
  if (_dogs is EqualUnmodifiableListView) return _dogs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dogs);
}

 final  Set<String> _selectedIds;
 Set<String> get selectedIds {
  if (_selectedIds is EqualUnmodifiableSetView) return _selectedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedIds);
}


/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveWalkSelectingDogsCopyWith<ActiveWalkSelectingDogs> get copyWith => _$ActiveWalkSelectingDogsCopyWithImpl<ActiveWalkSelectingDogs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveWalkSelectingDogs&&const DeepCollectionEquality().equals(other._dogs, _dogs)&&const DeepCollectionEquality().equals(other._selectedIds, _selectedIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_dogs),const DeepCollectionEquality().hash(_selectedIds));

@override
String toString() {
  return 'ActiveWalkState.selectingDogs(dogs: $dogs, selectedIds: $selectedIds)';
}


}

/// @nodoc
abstract mixin class $ActiveWalkSelectingDogsCopyWith<$Res> implements $ActiveWalkStateCopyWith<$Res> {
  factory $ActiveWalkSelectingDogsCopyWith(ActiveWalkSelectingDogs value, $Res Function(ActiveWalkSelectingDogs) _then) = _$ActiveWalkSelectingDogsCopyWithImpl;
@useResult
$Res call({
 List<Dog> dogs, Set<String> selectedIds
});




}
/// @nodoc
class _$ActiveWalkSelectingDogsCopyWithImpl<$Res>
    implements $ActiveWalkSelectingDogsCopyWith<$Res> {
  _$ActiveWalkSelectingDogsCopyWithImpl(this._self, this._then);

  final ActiveWalkSelectingDogs _self;
  final $Res Function(ActiveWalkSelectingDogs) _then;

/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dogs = null,Object? selectedIds = null,}) {
  return _then(ActiveWalkSelectingDogs(
dogs: null == dogs ? _self._dogs : dogs // ignore: cast_nullable_to_non_nullable
as List<Dog>,selectedIds: null == selectedIds ? _self._selectedIds : selectedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc


class ActiveWalkStarting implements ActiveWalkState {
  const ActiveWalkStarting({required final  List<Dog> dogs, required final  Set<String> selectedIds}): _dogs = dogs,_selectedIds = selectedIds;
  

 final  List<Dog> _dogs;
 List<Dog> get dogs {
  if (_dogs is EqualUnmodifiableListView) return _dogs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dogs);
}

 final  Set<String> _selectedIds;
 Set<String> get selectedIds {
  if (_selectedIds is EqualUnmodifiableSetView) return _selectedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedIds);
}


/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveWalkStartingCopyWith<ActiveWalkStarting> get copyWith => _$ActiveWalkStartingCopyWithImpl<ActiveWalkStarting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveWalkStarting&&const DeepCollectionEquality().equals(other._dogs, _dogs)&&const DeepCollectionEquality().equals(other._selectedIds, _selectedIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_dogs),const DeepCollectionEquality().hash(_selectedIds));

@override
String toString() {
  return 'ActiveWalkState.starting(dogs: $dogs, selectedIds: $selectedIds)';
}


}

/// @nodoc
abstract mixin class $ActiveWalkStartingCopyWith<$Res> implements $ActiveWalkStateCopyWith<$Res> {
  factory $ActiveWalkStartingCopyWith(ActiveWalkStarting value, $Res Function(ActiveWalkStarting) _then) = _$ActiveWalkStartingCopyWithImpl;
@useResult
$Res call({
 List<Dog> dogs, Set<String> selectedIds
});




}
/// @nodoc
class _$ActiveWalkStartingCopyWithImpl<$Res>
    implements $ActiveWalkStartingCopyWith<$Res> {
  _$ActiveWalkStartingCopyWithImpl(this._self, this._then);

  final ActiveWalkStarting _self;
  final $Res Function(ActiveWalkStarting) _then;

/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dogs = null,Object? selectedIds = null,}) {
  return _then(ActiveWalkStarting(
dogs: null == dogs ? _self._dogs : dogs // ignore: cast_nullable_to_non_nullable
as List<Dog>,selectedIds: null == selectedIds ? _self._selectedIds : selectedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc


class ActiveWalkTracking implements ActiveWalkState {
  const ActiveWalkTracking({required this.session, required this.elapsed});
  

 final  WalkSession session;
 final  Duration elapsed;

/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveWalkTrackingCopyWith<ActiveWalkTracking> get copyWith => _$ActiveWalkTrackingCopyWithImpl<ActiveWalkTracking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveWalkTracking&&(identical(other.session, session) || other.session == session)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed));
}


@override
int get hashCode => Object.hash(runtimeType,session,elapsed);

@override
String toString() {
  return 'ActiveWalkState.tracking(session: $session, elapsed: $elapsed)';
}


}

/// @nodoc
abstract mixin class $ActiveWalkTrackingCopyWith<$Res> implements $ActiveWalkStateCopyWith<$Res> {
  factory $ActiveWalkTrackingCopyWith(ActiveWalkTracking value, $Res Function(ActiveWalkTracking) _then) = _$ActiveWalkTrackingCopyWithImpl;
@useResult
$Res call({
 WalkSession session, Duration elapsed
});


$WalkSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$ActiveWalkTrackingCopyWithImpl<$Res>
    implements $ActiveWalkTrackingCopyWith<$Res> {
  _$ActiveWalkTrackingCopyWithImpl(this._self, this._then);

  final ActiveWalkTracking _self;
  final $Res Function(ActiveWalkTracking) _then;

/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,Object? elapsed = null,}) {
  return _then(ActiveWalkTracking(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WalkSession,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalkSessionCopyWith<$Res> get session {
  
  return $WalkSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class ActiveWalkStopped implements ActiveWalkState {
  const ActiveWalkStopped(this.session);
  

 final  WalkSession session;

/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveWalkStoppedCopyWith<ActiveWalkStopped> get copyWith => _$ActiveWalkStoppedCopyWithImpl<ActiveWalkStopped>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveWalkStopped&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString() {
  return 'ActiveWalkState.stopped(session: $session)';
}


}

/// @nodoc
abstract mixin class $ActiveWalkStoppedCopyWith<$Res> implements $ActiveWalkStateCopyWith<$Res> {
  factory $ActiveWalkStoppedCopyWith(ActiveWalkStopped value, $Res Function(ActiveWalkStopped) _then) = _$ActiveWalkStoppedCopyWithImpl;
@useResult
$Res call({
 WalkSession session
});


$WalkSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$ActiveWalkStoppedCopyWithImpl<$Res>
    implements $ActiveWalkStoppedCopyWith<$Res> {
  _$ActiveWalkStoppedCopyWithImpl(this._self, this._then);

  final ActiveWalkStopped _self;
  final $Res Function(ActiveWalkStopped) _then;

/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(ActiveWalkStopped(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WalkSession,
  ));
}

/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalkSessionCopyWith<$Res> get session {
  
  return $WalkSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class ActiveWalkFailure implements ActiveWalkState {
  const ActiveWalkFailure({required this.failure, required final  List<Dog> dogs, required final  Set<String> selectedIds}): _dogs = dogs,_selectedIds = selectedIds;
  

 final  Failure failure;
 final  List<Dog> _dogs;
 List<Dog> get dogs {
  if (_dogs is EqualUnmodifiableListView) return _dogs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dogs);
}

 final  Set<String> _selectedIds;
 Set<String> get selectedIds {
  if (_selectedIds is EqualUnmodifiableSetView) return _selectedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedIds);
}


/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveWalkFailureCopyWith<ActiveWalkFailure> get copyWith => _$ActiveWalkFailureCopyWithImpl<ActiveWalkFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveWalkFailure&&(identical(other.failure, failure) || other.failure == failure)&&const DeepCollectionEquality().equals(other._dogs, _dogs)&&const DeepCollectionEquality().equals(other._selectedIds, _selectedIds));
}


@override
int get hashCode => Object.hash(runtimeType,failure,const DeepCollectionEquality().hash(_dogs),const DeepCollectionEquality().hash(_selectedIds));

@override
String toString() {
  return 'ActiveWalkState.failure(failure: $failure, dogs: $dogs, selectedIds: $selectedIds)';
}


}

/// @nodoc
abstract mixin class $ActiveWalkFailureCopyWith<$Res> implements $ActiveWalkStateCopyWith<$Res> {
  factory $ActiveWalkFailureCopyWith(ActiveWalkFailure value, $Res Function(ActiveWalkFailure) _then) = _$ActiveWalkFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure, List<Dog> dogs, Set<String> selectedIds
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ActiveWalkFailureCopyWithImpl<$Res>
    implements $ActiveWalkFailureCopyWith<$Res> {
  _$ActiveWalkFailureCopyWithImpl(this._self, this._then);

  final ActiveWalkFailure _self;
  final $Res Function(ActiveWalkFailure) _then;

/// Create a copy of ActiveWalkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? dogs = null,Object? selectedIds = null,}) {
  return _then(ActiveWalkFailure(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,dogs: null == dogs ? _self._dogs : dogs // ignore: cast_nullable_to_non_nullable
as List<Dog>,selectedIds: null == selectedIds ? _self._selectedIds : selectedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

/// Create a copy of ActiveWalkState
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
