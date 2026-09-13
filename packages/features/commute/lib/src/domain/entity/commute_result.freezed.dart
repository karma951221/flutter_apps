// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commute_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommuteResult {

 CommuteDirection get direction; Origin get origin; Station get destination; List<TransitRoute> get routes; DateTime get searchedAt;
/// Create a copy of CommuteResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteResultCopyWith<CommuteResult> get copyWith => _$CommuteResultCopyWithImpl<CommuteResult>(this as CommuteResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteResult&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.destination, destination) || other.destination == destination)&&const DeepCollectionEquality().equals(other.routes, routes)&&(identical(other.searchedAt, searchedAt) || other.searchedAt == searchedAt));
}


@override
int get hashCode => Object.hash(runtimeType,direction,origin,destination,const DeepCollectionEquality().hash(routes),searchedAt);

@override
String toString() {
  return 'CommuteResult(direction: $direction, origin: $origin, destination: $destination, routes: $routes, searchedAt: $searchedAt)';
}


}

/// @nodoc
abstract mixin class $CommuteResultCopyWith<$Res>  {
  factory $CommuteResultCopyWith(CommuteResult value, $Res Function(CommuteResult) _then) = _$CommuteResultCopyWithImpl;
@useResult
$Res call({
 CommuteDirection direction, Origin origin, Station destination, List<TransitRoute> routes, DateTime searchedAt
});




}
/// @nodoc
class _$CommuteResultCopyWithImpl<$Res>
    implements $CommuteResultCopyWith<$Res> {
  _$CommuteResultCopyWithImpl(this._self, this._then);

  final CommuteResult _self;
  final $Res Function(CommuteResult) _then;

/// Create a copy of CommuteResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? direction = null,Object? origin = null,Object? destination = null,Object? routes = null,Object? searchedAt = null,}) {
  return _then(CommuteResult(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CommuteDirection,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as Origin,destination: null == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as Station,routes: null == routes ? _self.routes : routes // ignore: cast_nullable_to_non_nullable
as List<TransitRoute>,searchedAt: null == searchedAt ? _self.searchedAt : searchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CommuteResult].
extension CommuteResultPatterns on CommuteResult {
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
