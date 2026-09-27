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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AlarmListLoading value)?  loading,TResult Function( AlarmListLoaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AlarmListLoading() when loading != null:
return loading(_that);case AlarmListLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AlarmListLoading value)  loading,required TResult Function( AlarmListLoaded value)  loaded,}){
final _that = this;
switch (_that) {
case AlarmListLoading():
return loading(_that);case AlarmListLoaded():
return loaded(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AlarmListLoading value)?  loading,TResult? Function( AlarmListLoaded value)?  loaded,}){
final _that = this;
switch (_that) {
case AlarmListLoading() when loading != null:
return loading(_that);case AlarmListLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<Alarm> alarms,  Duration? untilNext,  bool canRing)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AlarmListLoading() when loading != null:
return loading();case AlarmListLoaded() when loaded != null:
return loaded(_that.alarms,_that.untilNext,_that.canRing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<Alarm> alarms,  Duration? untilNext,  bool canRing)  loaded,}) {final _that = this;
switch (_that) {
case AlarmListLoading():
return loading();case AlarmListLoaded():
return loaded(_that.alarms,_that.untilNext,_that.canRing);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<Alarm> alarms,  Duration? untilNext,  bool canRing)?  loaded,}) {final _that = this;
switch (_that) {
case AlarmListLoading() when loading != null:
return loading();case AlarmListLoaded() when loaded != null:
return loaded(_that.alarms,_that.untilNext,_that.canRing);case _:
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
  const AlarmListLoaded({required final  List<Alarm> alarms, this.untilNext, this.canRing = true}): _alarms = alarms;
  

 final  List<Alarm> _alarms;
 List<Alarm> get alarms {
  if (_alarms is EqualUnmodifiableListView) return _alarms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alarms);
}

 final  Duration? untilNext;
@JsonKey() final  bool canRing;

/// Create a copy of AlarmListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlarmListLoadedCopyWith<AlarmListLoaded> get copyWith => _$AlarmListLoadedCopyWithImpl<AlarmListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmListLoaded&&const DeepCollectionEquality().equals(other._alarms, _alarms)&&(identical(other.untilNext, untilNext) || other.untilNext == untilNext)&&(identical(other.canRing, canRing) || other.canRing == canRing));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_alarms),untilNext,canRing);

@override
String toString() {
  return 'AlarmListState.loaded(alarms: $alarms, untilNext: $untilNext, canRing: $canRing)';
}


}

/// @nodoc
abstract mixin class $AlarmListLoadedCopyWith<$Res> implements $AlarmListStateCopyWith<$Res> {
  factory $AlarmListLoadedCopyWith(AlarmListLoaded value, $Res Function(AlarmListLoaded) _then) = _$AlarmListLoadedCopyWithImpl;
@useResult
$Res call({
 List<Alarm> alarms, Duration? untilNext, bool canRing
});




}
/// @nodoc
class _$AlarmListLoadedCopyWithImpl<$Res>
    implements $AlarmListLoadedCopyWith<$Res> {
  _$AlarmListLoadedCopyWithImpl(this._self, this._then);

  final AlarmListLoaded _self;
  final $Res Function(AlarmListLoaded) _then;

/// Create a copy of AlarmListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? alarms = null,Object? untilNext = freezed,Object? canRing = null,}) {
  return _then(AlarmListLoaded(
alarms: null == alarms ? _self._alarms : alarms // ignore: cast_nullable_to_non_nullable
as List<Alarm>,untilNext: freezed == untilNext ? _self.untilNext : untilNext // ignore: cast_nullable_to_non_nullable
as Duration?,canRing: null == canRing ? _self.canRing : canRing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
