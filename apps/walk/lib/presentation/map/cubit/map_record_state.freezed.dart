// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_record_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MapRecordState {

 RecorderStatus get status; bool get busy; AlwaysAccess? get access; RecordRetention get retention; bool? get activityRecognition; bool? get notification; bool? get hasPoints; bool get loaded;
/// Create a copy of MapRecordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapRecordStateCopyWith<MapRecordState> get copyWith => _$MapRecordStateCopyWithImpl<MapRecordState>(this as MapRecordState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapRecordState&&(identical(other.status, status) || other.status == status)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.access, access) || other.access == access)&&(identical(other.retention, retention) || other.retention == retention)&&(identical(other.activityRecognition, activityRecognition) || other.activityRecognition == activityRecognition)&&(identical(other.notification, notification) || other.notification == notification)&&(identical(other.hasPoints, hasPoints) || other.hasPoints == hasPoints)&&(identical(other.loaded, loaded) || other.loaded == loaded));
}


@override
int get hashCode => Object.hash(runtimeType,status,busy,access,retention,activityRecognition,notification,hasPoints,loaded);

@override
String toString() {
  return 'MapRecordState(status: $status, busy: $busy, access: $access, retention: $retention, activityRecognition: $activityRecognition, notification: $notification, hasPoints: $hasPoints, loaded: $loaded)';
}


}

/// @nodoc
abstract mixin class $MapRecordStateCopyWith<$Res>  {
  factory $MapRecordStateCopyWith(MapRecordState value, $Res Function(MapRecordState) _then) = _$MapRecordStateCopyWithImpl;
@useResult
$Res call({
 RecorderStatus status, bool busy, AlwaysAccess? access, RecordRetention retention, bool? activityRecognition, bool? notification, bool? hasPoints, bool loaded
});




}
/// @nodoc
class _$MapRecordStateCopyWithImpl<$Res>
    implements $MapRecordStateCopyWith<$Res> {
  _$MapRecordStateCopyWithImpl(this._self, this._then);

  final MapRecordState _self;
  final $Res Function(MapRecordState) _then;

/// Create a copy of MapRecordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? busy = null,Object? access = freezed,Object? retention = null,Object? activityRecognition = freezed,Object? notification = freezed,Object? hasPoints = freezed,Object? loaded = null,}) {
  return _then(MapRecordState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecorderStatus,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,access: freezed == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as AlwaysAccess?,retention: null == retention ? _self.retention : retention // ignore: cast_nullable_to_non_nullable
as RecordRetention,activityRecognition: freezed == activityRecognition ? _self.activityRecognition : activityRecognition // ignore: cast_nullable_to_non_nullable
as bool?,notification: freezed == notification ? _self.notification : notification // ignore: cast_nullable_to_non_nullable
as bool?,hasPoints: freezed == hasPoints ? _self.hasPoints : hasPoints // ignore: cast_nullable_to_non_nullable
as bool?,loaded: null == loaded ? _self.loaded : loaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MapRecordState].
extension MapRecordStatePatterns on MapRecordState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
