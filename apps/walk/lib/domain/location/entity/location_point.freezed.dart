// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocationPoint {

 DateTime get recordedAt; double get lat; double get lng; double? get accuracyM; RecordMode get mode; bool get stillStart;
/// Create a copy of LocationPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationPointCopyWith<LocationPoint> get copyWith => _$LocationPointCopyWithImpl<LocationPoint>(this as LocationPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationPoint&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracyM, accuracyM) || other.accuracyM == accuracyM)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.stillStart, stillStart) || other.stillStart == stillStart));
}


@override
int get hashCode => Object.hash(runtimeType,recordedAt,lat,lng,accuracyM,mode,stillStart);

@override
String toString() {
  return 'LocationPoint(recordedAt: $recordedAt, lat: $lat, lng: $lng, accuracyM: $accuracyM, mode: $mode, stillStart: $stillStart)';
}


}

/// @nodoc
abstract mixin class $LocationPointCopyWith<$Res>  {
  factory $LocationPointCopyWith(LocationPoint value, $Res Function(LocationPoint) _then) = _$LocationPointCopyWithImpl;
@useResult
$Res call({
 DateTime recordedAt, double lat, double lng, double? accuracyM, RecordMode mode, bool stillStart
});




}
/// @nodoc
class _$LocationPointCopyWithImpl<$Res>
    implements $LocationPointCopyWith<$Res> {
  _$LocationPointCopyWithImpl(this._self, this._then);

  final LocationPoint _self;
  final $Res Function(LocationPoint) _then;

/// Create a copy of LocationPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recordedAt = null,Object? lat = null,Object? lng = null,Object? accuracyM = freezed,Object? mode = null,Object? stillStart = null,}) {
  return _then(LocationPoint(
recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracyM: freezed == accuracyM ? _self.accuracyM : accuracyM // ignore: cast_nullable_to_non_nullable
as double?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RecordMode,stillStart: null == stillStart ? _self.stillStart : stillStart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LocationPoint].
extension LocationPointPatterns on LocationPoint {
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
