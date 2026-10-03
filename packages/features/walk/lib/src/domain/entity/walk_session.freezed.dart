// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkSession {

 List<String> get dogIds; DateTime get startedAt; DateTime? get endedAt; List<WalkTrackPoint> get points; double get distanceMeters;
/// Create a copy of WalkSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkSessionCopyWith<WalkSession> get copyWith => _$WalkSessionCopyWithImpl<WalkSession>(this as WalkSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkSession&&const DeepCollectionEquality().equals(other.dogIds, dogIds)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&const DeepCollectionEquality().equals(other.points, points)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(dogIds),startedAt,endedAt,const DeepCollectionEquality().hash(points),distanceMeters);

@override
String toString() {
  return 'WalkSession(dogIds: $dogIds, startedAt: $startedAt, endedAt: $endedAt, points: $points, distanceMeters: $distanceMeters)';
}


}

/// @nodoc
abstract mixin class $WalkSessionCopyWith<$Res>  {
  factory $WalkSessionCopyWith(WalkSession value, $Res Function(WalkSession) _then) = _$WalkSessionCopyWithImpl;
@useResult
$Res call({
 List<String> dogIds, DateTime startedAt, DateTime? endedAt, List<WalkTrackPoint> points, double distanceMeters
});




}
/// @nodoc
class _$WalkSessionCopyWithImpl<$Res>
    implements $WalkSessionCopyWith<$Res> {
  _$WalkSessionCopyWithImpl(this._self, this._then);

  final WalkSession _self;
  final $Res Function(WalkSession) _then;

/// Create a copy of WalkSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dogIds = null,Object? startedAt = null,Object? endedAt = freezed,Object? points = null,Object? distanceMeters = null,}) {
  return _then(WalkSession(
dogIds: null == dogIds ? _self.dogIds : dogIds // ignore: cast_nullable_to_non_nullable
as List<String>,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<WalkTrackPoint>,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [WalkSession].
extension WalkSessionPatterns on WalkSession {
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
