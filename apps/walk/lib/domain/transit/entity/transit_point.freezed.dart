// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transit_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransitPoint {

 double get lat; double get lng; String get label; TransitPointSource get source;
/// Create a copy of TransitPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitPointCopyWith<TransitPoint> get copyWith => _$TransitPointCopyWithImpl<TransitPoint>(this as TransitPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.label, label) || other.label == label)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,lat,lng,label,source);

@override
String toString() {
  return 'TransitPoint(lat: $lat, lng: $lng, label: $label, source: $source)';
}


}

/// @nodoc
abstract mixin class $TransitPointCopyWith<$Res>  {
  factory $TransitPointCopyWith(TransitPoint value, $Res Function(TransitPoint) _then) = _$TransitPointCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, String label, TransitPointSource source
});




}
/// @nodoc
class _$TransitPointCopyWithImpl<$Res>
    implements $TransitPointCopyWith<$Res> {
  _$TransitPointCopyWithImpl(this._self, this._then);

  final TransitPoint _self;
  final $Res Function(TransitPoint) _then;

/// Create a copy of TransitPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? label = null,Object? source = null,}) {
  return _then(TransitPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TransitPointSource,
  ));
}

}


/// Adds pattern-matching-related methods to [TransitPoint].
extension TransitPointPatterns on TransitPoint {
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
