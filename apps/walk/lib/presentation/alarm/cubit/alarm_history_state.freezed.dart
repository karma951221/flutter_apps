// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlarmHistoryState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmHistoryState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmHistoryState()';
}


}

/// @nodoc
class $AlarmHistoryStateCopyWith<$Res>  {
$AlarmHistoryStateCopyWith(AlarmHistoryState _, $Res Function(AlarmHistoryState) __);
}


/// Adds pattern-matching-related methods to [AlarmHistoryState].
extension AlarmHistoryStatePatterns on AlarmHistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AlarmHistoryLoading value)?  loading,TResult Function( AlarmHistoryLoaded value)?  loaded,TResult Function( AlarmHistoryFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AlarmHistoryLoading() when loading != null:
return loading(_that);case AlarmHistoryLoaded() when loaded != null:
return loaded(_that);case AlarmHistoryFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AlarmHistoryLoading value)  loading,required TResult Function( AlarmHistoryLoaded value)  loaded,required TResult Function( AlarmHistoryFailure value)  failure,}){
final _that = this;
switch (_that) {
case AlarmHistoryLoading():
return loading(_that);case AlarmHistoryLoaded():
return loaded(_that);case AlarmHistoryFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AlarmHistoryLoading value)?  loading,TResult? Function( AlarmHistoryLoaded value)?  loaded,TResult? Function( AlarmHistoryFailure value)?  failure,}){
final _that = this;
switch (_that) {
case AlarmHistoryLoading() when loading != null:
return loading(_that);case AlarmHistoryLoaded() when loaded != null:
return loaded(_that);case AlarmHistoryFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<RingLogGroup> groups,  DateTime now)?  loaded,TResult Function()?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AlarmHistoryLoading() when loading != null:
return loading();case AlarmHistoryLoaded() when loaded != null:
return loaded(_that.groups,_that.now);case AlarmHistoryFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<RingLogGroup> groups,  DateTime now)  loaded,required TResult Function()  failure,}) {final _that = this;
switch (_that) {
case AlarmHistoryLoading():
return loading();case AlarmHistoryLoaded():
return loaded(_that.groups,_that.now);case AlarmHistoryFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<RingLogGroup> groups,  DateTime now)?  loaded,TResult? Function()?  failure,}) {final _that = this;
switch (_that) {
case AlarmHistoryLoading() when loading != null:
return loading();case AlarmHistoryLoaded() when loaded != null:
return loaded(_that.groups,_that.now);case AlarmHistoryFailure() when failure != null:
return failure();case _:
  return null;

}
}

}

/// @nodoc


class AlarmHistoryLoading implements AlarmHistoryState {
  const AlarmHistoryLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmHistoryLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmHistoryState.loading()';
}


}




/// @nodoc


class AlarmHistoryLoaded implements AlarmHistoryState {
  const AlarmHistoryLoaded({required final  List<RingLogGroup> groups, required this.now}): _groups = groups;
  

 final  List<RingLogGroup> _groups;
 List<RingLogGroup> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

 final  DateTime now;

/// Create a copy of AlarmHistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlarmHistoryLoadedCopyWith<AlarmHistoryLoaded> get copyWith => _$AlarmHistoryLoadedCopyWithImpl<AlarmHistoryLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmHistoryLoaded&&const DeepCollectionEquality().equals(other._groups, _groups)&&(identical(other.now, now) || other.now == now));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_groups),now);

@override
String toString() {
  return 'AlarmHistoryState.loaded(groups: $groups, now: $now)';
}


}

/// @nodoc
abstract mixin class $AlarmHistoryLoadedCopyWith<$Res> implements $AlarmHistoryStateCopyWith<$Res> {
  factory $AlarmHistoryLoadedCopyWith(AlarmHistoryLoaded value, $Res Function(AlarmHistoryLoaded) _then) = _$AlarmHistoryLoadedCopyWithImpl;
@useResult
$Res call({
 List<RingLogGroup> groups, DateTime now
});




}
/// @nodoc
class _$AlarmHistoryLoadedCopyWithImpl<$Res>
    implements $AlarmHistoryLoadedCopyWith<$Res> {
  _$AlarmHistoryLoadedCopyWithImpl(this._self, this._then);

  final AlarmHistoryLoaded _self;
  final $Res Function(AlarmHistoryLoaded) _then;

/// Create a copy of AlarmHistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? groups = null,Object? now = null,}) {
  return _then(AlarmHistoryLoaded(
groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<RingLogGroup>,now: null == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class AlarmHistoryFailure implements AlarmHistoryState {
  const AlarmHistoryFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmHistoryFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlarmHistoryState.failure()';
}


}




// dart format on
