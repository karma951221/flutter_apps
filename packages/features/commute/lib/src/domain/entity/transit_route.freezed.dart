// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transit_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransitRoute {

 TransitMode get mode; Duration get duration; int get transferCount; List<TransitLeg> get legs;
/// Create a copy of TransitRoute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitRouteCopyWith<TransitRoute> get copyWith => _$TransitRouteCopyWithImpl<TransitRoute>(this as TransitRoute, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitRoute&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.transferCount, transferCount) || other.transferCount == transferCount)&&const DeepCollectionEquality().equals(other.legs, legs));
}


@override
int get hashCode => Object.hash(runtimeType,mode,duration,transferCount,const DeepCollectionEquality().hash(legs));

@override
String toString() {
  return 'TransitRoute(mode: $mode, duration: $duration, transferCount: $transferCount, legs: $legs)';
}


}

/// @nodoc
abstract mixin class $TransitRouteCopyWith<$Res>  {
  factory $TransitRouteCopyWith(TransitRoute value, $Res Function(TransitRoute) _then) = _$TransitRouteCopyWithImpl;
@useResult
$Res call({
 TransitMode mode, Duration duration, int transferCount, List<TransitLeg> legs
});




}
/// @nodoc
class _$TransitRouteCopyWithImpl<$Res>
    implements $TransitRouteCopyWith<$Res> {
  _$TransitRouteCopyWithImpl(this._self, this._then);

  final TransitRoute _self;
  final $Res Function(TransitRoute) _then;

/// Create a copy of TransitRoute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? duration = null,Object? transferCount = null,Object? legs = null,}) {
  return _then(TransitRoute(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as TransitMode,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,transferCount: null == transferCount ? _self.transferCount : transferCount // ignore: cast_nullable_to_non_nullable
as int,legs: null == legs ? _self.legs : legs // ignore: cast_nullable_to_non_nullable
as List<TransitLeg>,
  ));
}

}


/// Adds pattern-matching-related methods to [TransitRoute].
extension TransitRoutePatterns on TransitRoute {
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
