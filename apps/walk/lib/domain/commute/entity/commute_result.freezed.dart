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

 CommuteDirection get direction; TransitRoute get route; List<TransitRoute> get alternatives; List<TrainArrival> get arrivals; RealtimeStatus get realtime; CatchVerdict get verdict; DateTime get eta; bool get etaFromRealtime; DateTime get queriedAt;
/// Create a copy of CommuteResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommuteResultCopyWith<CommuteResult> get copyWith => _$CommuteResultCopyWithImpl<CommuteResult>(this as CommuteResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommuteResult&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.route, route) || other.route == route)&&const DeepCollectionEquality().equals(other.alternatives, alternatives)&&const DeepCollectionEquality().equals(other.arrivals, arrivals)&&(identical(other.realtime, realtime) || other.realtime == realtime)&&(identical(other.verdict, verdict) || other.verdict == verdict)&&(identical(other.eta, eta) || other.eta == eta)&&(identical(other.etaFromRealtime, etaFromRealtime) || other.etaFromRealtime == etaFromRealtime)&&(identical(other.queriedAt, queriedAt) || other.queriedAt == queriedAt));
}


@override
int get hashCode => Object.hash(runtimeType,direction,route,const DeepCollectionEquality().hash(alternatives),const DeepCollectionEquality().hash(arrivals),realtime,verdict,eta,etaFromRealtime,queriedAt);

@override
String toString() {
  return 'CommuteResult(direction: $direction, route: $route, alternatives: $alternatives, arrivals: $arrivals, realtime: $realtime, verdict: $verdict, eta: $eta, etaFromRealtime: $etaFromRealtime, queriedAt: $queriedAt)';
}


}

/// @nodoc
abstract mixin class $CommuteResultCopyWith<$Res>  {
  factory $CommuteResultCopyWith(CommuteResult value, $Res Function(CommuteResult) _then) = _$CommuteResultCopyWithImpl;
@useResult
$Res call({
 CommuteDirection direction, TransitRoute route, List<TransitRoute> alternatives, List<TrainArrival> arrivals, RealtimeStatus realtime, CatchVerdict verdict, DateTime eta, bool etaFromRealtime, DateTime queriedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? direction = null,Object? route = null,Object? alternatives = null,Object? arrivals = null,Object? realtime = null,Object? verdict = null,Object? eta = null,Object? etaFromRealtime = null,Object? queriedAt = null,}) {
  return _then(CommuteResult(
direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CommuteDirection,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as TransitRoute,alternatives: null == alternatives ? _self.alternatives : alternatives // ignore: cast_nullable_to_non_nullable
as List<TransitRoute>,arrivals: null == arrivals ? _self.arrivals : arrivals // ignore: cast_nullable_to_non_nullable
as List<TrainArrival>,realtime: null == realtime ? _self.realtime : realtime // ignore: cast_nullable_to_non_nullable
as RealtimeStatus,verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as CatchVerdict,eta: null == eta ? _self.eta : eta // ignore: cast_nullable_to_non_nullable
as DateTime,etaFromRealtime: null == etaFromRealtime ? _self.etaFromRealtime : etaFromRealtime // ignore: cast_nullable_to_non_nullable
as bool,queriedAt: null == queriedAt ? _self.queriedAt : queriedAt // ignore: cast_nullable_to_non_nullable
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
