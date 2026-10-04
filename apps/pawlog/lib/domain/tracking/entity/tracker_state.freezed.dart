// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerState()';
}


}

/// @nodoc
class $TrackerStateCopyWith<$Res>  {
$TrackerStateCopyWith(TrackerState _, $Res Function(TrackerState) __);
}


/// Adds pattern-matching-related methods to [TrackerState].
extension TrackerStatePatterns on TrackerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TrackerIdle value)?  idle,TResult Function( TrackerTracking value)?  tracking,TResult Function( TrackerFinished value)?  finished,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TrackerIdle() when idle != null:
return idle(_that);case TrackerTracking() when tracking != null:
return tracking(_that);case TrackerFinished() when finished != null:
return finished(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TrackerIdle value)  idle,required TResult Function( TrackerTracking value)  tracking,required TResult Function( TrackerFinished value)  finished,}){
final _that = this;
switch (_that) {
case TrackerIdle():
return idle(_that);case TrackerTracking():
return tracking(_that);case TrackerFinished():
return finished(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TrackerIdle value)?  idle,TResult? Function( TrackerTracking value)?  tracking,TResult? Function( TrackerFinished value)?  finished,}){
final _that = this;
switch (_that) {
case TrackerIdle() when idle != null:
return idle(_that);case TrackerTracking() when tracking != null:
return tracking(_that);case TrackerFinished() when finished != null:
return finished(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( WalkSession session)?  tracking,TResult Function( WalkSession session)?  finished,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TrackerIdle() when idle != null:
return idle();case TrackerTracking() when tracking != null:
return tracking(_that.session);case TrackerFinished() when finished != null:
return finished(_that.session);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( WalkSession session)  tracking,required TResult Function( WalkSession session)  finished,}) {final _that = this;
switch (_that) {
case TrackerIdle():
return idle();case TrackerTracking():
return tracking(_that.session);case TrackerFinished():
return finished(_that.session);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( WalkSession session)?  tracking,TResult? Function( WalkSession session)?  finished,}) {final _that = this;
switch (_that) {
case TrackerIdle() when idle != null:
return idle();case TrackerTracking() when tracking != null:
return tracking(_that.session);case TrackerFinished() when finished != null:
return finished(_that.session);case _:
  return null;

}
}

}

/// @nodoc


class TrackerIdle implements TrackerState {
  const TrackerIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerState.idle()';
}


}




/// @nodoc


class TrackerTracking implements TrackerState {
  const TrackerTracking(this.session);
  

 final  WalkSession session;

/// Create a copy of TrackerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackerTrackingCopyWith<TrackerTracking> get copyWith => _$TrackerTrackingCopyWithImpl<TrackerTracking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerTracking&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString() {
  return 'TrackerState.tracking(session: $session)';
}


}

/// @nodoc
abstract mixin class $TrackerTrackingCopyWith<$Res> implements $TrackerStateCopyWith<$Res> {
  factory $TrackerTrackingCopyWith(TrackerTracking value, $Res Function(TrackerTracking) _then) = _$TrackerTrackingCopyWithImpl;
@useResult
$Res call({
 WalkSession session
});


$WalkSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$TrackerTrackingCopyWithImpl<$Res>
    implements $TrackerTrackingCopyWith<$Res> {
  _$TrackerTrackingCopyWithImpl(this._self, this._then);

  final TrackerTracking _self;
  final $Res Function(TrackerTracking) _then;

/// Create a copy of TrackerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(TrackerTracking(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WalkSession,
  ));
}

/// Create a copy of TrackerState
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


class TrackerFinished implements TrackerState {
  const TrackerFinished(this.session);
  

 final  WalkSession session;

/// Create a copy of TrackerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackerFinishedCopyWith<TrackerFinished> get copyWith => _$TrackerFinishedCopyWithImpl<TrackerFinished>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerFinished&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString() {
  return 'TrackerState.finished(session: $session)';
}


}

/// @nodoc
abstract mixin class $TrackerFinishedCopyWith<$Res> implements $TrackerStateCopyWith<$Res> {
  factory $TrackerFinishedCopyWith(TrackerFinished value, $Res Function(TrackerFinished) _then) = _$TrackerFinishedCopyWithImpl;
@useResult
$Res call({
 WalkSession session
});


$WalkSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$TrackerFinishedCopyWithImpl<$Res>
    implements $TrackerFinishedCopyWith<$Res> {
  _$TrackerFinishedCopyWithImpl(this._self, this._then);

  final TrackerFinished _self;
  final $Res Function(TrackerFinished) _then;

/// Create a copy of TrackerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(TrackerFinished(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WalkSession,
  ));
}

/// Create a copy of TrackerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalkSessionCopyWith<$Res> get session {
  
  return $WalkSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

// dart format on
