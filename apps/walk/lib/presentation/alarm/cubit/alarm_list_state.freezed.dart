// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlarmListState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmListState()';
}


}

/// @nodoc
class $AlarmListStateCopyWith<$Res>  {
$AlarmListStateCopyWith(AlarmListState _, $Res Function(AlarmListState) __);
}


/// Adds pattern-matching-related methods to [AlarmListState].
extension AlarmListStatePatterns on AlarmListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AlarmListLoading value)?  loading,TResult Function( AlarmListLoaded value)?  loaded,TResult Function( AlarmListFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AlarmListLoading() when loading != null:
return loading(_that);case AlarmListLoaded() when loaded != null:
return loaded(_that);case AlarmListFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AlarmListLoading value)  loading,required TResult Function( AlarmListLoaded value)  loaded,required TResult Function( AlarmListFailure value)  failure,}){
final _that = this;
switch (_that) {
case AlarmListLoading():
return loading(_that);case AlarmListLoaded():
return loaded(_that);case AlarmListFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AlarmListLoading value)?  loading,TResult? Function( AlarmListLoaded value)?  loaded,TResult? Function( AlarmListFailure value)?  failure,}){
final _that = this;
switch (_that) {
case AlarmListLoading() when loading != null:
return loading(_that);case AlarmListLoaded() when loaded != null:
return loaded(_that);case AlarmListFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<Alarm> alarms,  Map<int, DateTime> nextAt,  DateTime now,  bool canRing,  Map<int, String> holidays,  AlarmPause? pause,  Set<int> pausedOut)?  loaded,TResult Function()?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AlarmListLoading() when loading != null:
return loading();case AlarmListLoaded() when loaded != null:
return loaded(_that.alarms,_that.nextAt,_that.now,_that.canRing,_that.holidays,_that.pause,_that.pausedOut);case AlarmListFailure() when failure != null:
return failure();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<Alarm> alarms,  Map<int, DateTime> nextAt,  DateTime now,  bool canRing,  Map<int, String> holidays,  AlarmPause? pause,  Set<int> pausedOut)  loaded,required TResult Function()  failure,}) {final _that = this;
switch (_that) {
case AlarmListLoading():
return loading();case AlarmListLoaded():
return loaded(_that.alarms,_that.nextAt,_that.now,_that.canRing,_that.holidays,_that.pause,_that.pausedOut);case AlarmListFailure():
return failure();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<Alarm> alarms,  Map<int, DateTime> nextAt,  DateTime now,  bool canRing,  Map<int, String> holidays,  AlarmPause? pause,  Set<int> pausedOut)?  loaded,TResult? Function()?  failure,}) {final _that = this;
switch (_that) {
case AlarmListLoading() when loading != null:
return loading();case AlarmListLoaded() when loaded != null:
return loaded(_that.alarms,_that.nextAt,_that.now,_that.canRing,_that.holidays,_that.pause,_that.pausedOut);case AlarmListFailure() when failure != null:
return failure();case _:
  return null;

}
}

}

/// @nodoc


class AlarmListLoading implements AlarmListState {
  const AlarmListLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmListLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmListState.loading()';
}


}




/// @nodoc


class AlarmListLoaded implements AlarmListState {
  const AlarmListLoaded({required final  List<Alarm> alarms, required final  Map<int, DateTime> nextAt, required this.now, this.canRing = true, final  Map<int, String> holidays = const <int, String>{}, this.pause, final  Set<int> pausedOut = const <int>{}}): _alarms = alarms,_nextAt = nextAt,_holidays = holidays,_pausedOut = pausedOut;
  

 final  List<Alarm> _alarms;
 List<Alarm> get alarms {
  if (_alarms is EqualUnmodifiableListView) return _alarms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alarms);
}

 final  Map<int, DateTime> _nextAt;
 Map<int, DateTime> get nextAt {
  if (_nextAt is EqualUnmodifiableMapView) return _nextAt;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nextAt);
}

 final  DateTime now;
@JsonKey() final  bool canRing;
 final  Map<int, String> _holidays;
@JsonKey() Map<int, String> get holidays {
  if (_holidays is EqualUnmodifiableMapView) return _holidays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_holidays);
}

 final  AlarmPause? pause;
 final  Set<int> _pausedOut;
@JsonKey() Set<int> get pausedOut {
  if (_pausedOut is EqualUnmodifiableSetView) return _pausedOut;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_pausedOut);
}


/// Create a copy of AlarmListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlarmListLoadedCopyWith<AlarmListLoaded> get copyWith => _$AlarmListLoadedCopyWithImpl<AlarmListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmListLoaded&&const DeepCollectionEquality().equals(other._alarms, _alarms)&&const DeepCollectionEquality().equals(other._nextAt, _nextAt)&&(identical(other.now, now) || other.now == now)&&(identical(other.canRing, canRing) || other.canRing == canRing)&&const DeepCollectionEquality().equals(other._holidays, _holidays)&&(identical(other.pause, pause) || other.pause == pause)&&const DeepCollectionEquality().equals(other._pausedOut, _pausedOut));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_alarms),const DeepCollectionEquality().hash(_nextAt),now,canRing,const DeepCollectionEquality().hash(_holidays),pause,const DeepCollectionEquality().hash(_pausedOut));

@override
String toString() {
  return 'AlarmListState.loaded(alarms: $alarms, nextAt: $nextAt, now: $now, canRing: $canRing, holidays: $holidays, pause: $pause, pausedOut: $pausedOut)';
}


}

/// @nodoc
abstract mixin class $AlarmListLoadedCopyWith<$Res> implements $AlarmListStateCopyWith<$Res> {
  factory $AlarmListLoadedCopyWith(AlarmListLoaded value, $Res Function(AlarmListLoaded) _then) = _$AlarmListLoadedCopyWithImpl;
@useResult
$Res call({
 List<Alarm> alarms, Map<int, DateTime> nextAt, DateTime now, bool canRing, Map<int, String> holidays, AlarmPause? pause, Set<int> pausedOut
});


$AlarmPauseCopyWith<$Res>? get pause;

}
/// @nodoc
class _$AlarmListLoadedCopyWithImpl<$Res>
    implements $AlarmListLoadedCopyWith<$Res> {
  _$AlarmListLoadedCopyWithImpl(this._self, this._then);

  final AlarmListLoaded _self;
  final $Res Function(AlarmListLoaded) _then;

/// Create a copy of AlarmListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? alarms = null,Object? nextAt = null,Object? now = null,Object? canRing = null,Object? holidays = null,Object? pause = freezed,Object? pausedOut = null,}) {
  return _then(AlarmListLoaded(
alarms: null == alarms ? _self._alarms : alarms // ignore: cast_nullable_to_non_nullable
as List<Alarm>,nextAt: null == nextAt ? _self._nextAt : nextAt // ignore: cast_nullable_to_non_nullable
as Map<int, DateTime>,now: null == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime,canRing: null == canRing ? _self.canRing : canRing // ignore: cast_nullable_to_non_nullable
as bool,holidays: null == holidays ? _self._holidays : holidays // ignore: cast_nullable_to_non_nullable
as Map<int, String>,pause: freezed == pause ? _self.pause : pause // ignore: cast_nullable_to_non_nullable
as AlarmPause?,pausedOut: null == pausedOut ? _self._pausedOut : pausedOut // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}

/// Create a copy of AlarmListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlarmPauseCopyWith<$Res>? get pause {
    if (_self.pause == null) {
    return null;
  }

  return $AlarmPauseCopyWith<$Res>(_self.pause!, (value) {
    return _then(_self.copyWith(pause: value));
  });
}
}

/// @nodoc


class AlarmListFailure implements AlarmListState {
  const AlarmListFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmListFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmListState.failure()';
}


}




// dart format on
