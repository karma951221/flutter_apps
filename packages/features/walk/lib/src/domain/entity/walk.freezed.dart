// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Walk {

 String get id; DateTime get startedAt; DateTime get endedAt; Duration get duration; double get distanceMeters; String? get memo; List<Dog> get dogs; List<WalkPhoto> get photos; List<GeoPoint> get previewPoints; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Walk
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkCopyWith<Walk> get copyWith => _$WalkCopyWithImpl<Walk>(this as Walk, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Walk&&(identical(other.id, id) || other.id == id)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.memo, memo) || other.memo == memo)&&const DeepCollectionEquality().equals(other.dogs, dogs)&&const DeepCollectionEquality().equals(other.photos, photos)&&const DeepCollectionEquality().equals(other.previewPoints, previewPoints)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,startedAt,endedAt,duration,distanceMeters,memo,const DeepCollectionEquality().hash(dogs),const DeepCollectionEquality().hash(photos),const DeepCollectionEquality().hash(previewPoints),createdAt,updatedAt);

@override
String toString() {
  return 'Walk(id: $id, startedAt: $startedAt, endedAt: $endedAt, duration: $duration, distanceMeters: $distanceMeters, memo: $memo, dogs: $dogs, photos: $photos, previewPoints: $previewPoints, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WalkCopyWith<$Res>  {
  factory $WalkCopyWith(Walk value, $Res Function(Walk) _then) = _$WalkCopyWithImpl;
@useResult
$Res call({
 String id, DateTime startedAt, DateTime endedAt, Duration duration, double distanceMeters, String? memo, List<Dog> dogs, List<WalkPhoto> photos, List<GeoPoint> previewPoints, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$WalkCopyWithImpl<$Res>
    implements $WalkCopyWith<$Res> {
  _$WalkCopyWithImpl(this._self, this._then);

  final Walk _self;
  final $Res Function(Walk) _then;

/// Create a copy of Walk
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startedAt = null,Object? endedAt = null,Object? duration = null,Object? distanceMeters = null,Object? memo = freezed,Object? dogs = null,Object? photos = null,Object? previewPoints = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Walk(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,dogs: null == dogs ? _self.dogs : dogs // ignore: cast_nullable_to_non_nullable
as List<Dog>,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<WalkPhoto>,previewPoints: null == previewPoints ? _self.previewPoints : previewPoints // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Walk].
extension WalkPatterns on Walk {
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
