// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_track_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkTrackPoint {

 GeoPoint get point; DateTime get recordedAt; double? get accuracy;
/// Create a copy of WalkTrackPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkTrackPointCopyWith<WalkTrackPoint> get copyWith => _$WalkTrackPointCopyWithImpl<WalkTrackPoint>(this as WalkTrackPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkTrackPoint&&(identical(other.point, point) || other.point == point)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.accuracy, accuracy) || other.accuracy == accuracy));
}


@override
int get hashCode => Object.hash(runtimeType,point,recordedAt,accuracy);

@override
String toString() {
  return 'WalkTrackPoint(point: $point, recordedAt: $recordedAt, accuracy: $accuracy)';
}


}

/// @nodoc
abstract mixin class $WalkTrackPointCopyWith<$Res>  {
  factory $WalkTrackPointCopyWith(WalkTrackPoint value, $Res Function(WalkTrackPoint) _then) = _$WalkTrackPointCopyWithImpl;
@useResult
$Res call({
 GeoPoint point, DateTime recordedAt, double? accuracy
});




}
/// @nodoc
class _$WalkTrackPointCopyWithImpl<$Res>
    implements $WalkTrackPointCopyWith<$Res> {
  _$WalkTrackPointCopyWithImpl(this._self, this._then);

  final WalkTrackPoint _self;
  final $Res Function(WalkTrackPoint) _then;

/// Create a copy of WalkTrackPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? point = null,Object? recordedAt = null,Object? accuracy = freezed,}) {
  return _then(WalkTrackPoint(
point: null == point ? _self.point : point // ignore: cast_nullable_to_non_nullable
as GeoPoint,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,accuracy: freezed == accuracy ? _self.accuracy : accuracy // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [WalkTrackPoint].
extension WalkTrackPointPatterns on WalkTrackPoint {
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
