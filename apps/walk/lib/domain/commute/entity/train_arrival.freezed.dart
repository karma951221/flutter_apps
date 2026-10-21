// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'train_arrival.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrainArrival {

 int? get minutes; bool get estimated; int? get stationsAway; String get message; String? get destination;
/// Create a copy of TrainArrival
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainArrivalCopyWith<TrainArrival> get copyWith => _$TrainArrivalCopyWithImpl<TrainArrival>(this as TrainArrival, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainArrival&&(identical(other.minutes, minutes) || other.minutes == minutes)&&(identical(other.estimated, estimated) || other.estimated == estimated)&&(identical(other.stationsAway, stationsAway) || other.stationsAway == stationsAway)&&(identical(other.message, message) || other.message == message)&&(identical(other.destination, destination) || other.destination == destination));
}


@override
int get hashCode => Object.hash(runtimeType,minutes,estimated,stationsAway,message,destination);

@override
String toString() {
  return 'TrainArrival(minutes: $minutes, estimated: $estimated, stationsAway: $stationsAway, message: $message, destination: $destination)';
}


}

/// @nodoc
abstract mixin class $TrainArrivalCopyWith<$Res>  {
  factory $TrainArrivalCopyWith(TrainArrival value, $Res Function(TrainArrival) _then) = _$TrainArrivalCopyWithImpl;
@useResult
$Res call({
 int? minutes, bool estimated, int? stationsAway, String message, String? destination
});




}
/// @nodoc
class _$TrainArrivalCopyWithImpl<$Res>
    implements $TrainArrivalCopyWith<$Res> {
  _$TrainArrivalCopyWithImpl(this._self, this._then);

  final TrainArrival _self;
  final $Res Function(TrainArrival) _then;

/// Create a copy of TrainArrival
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minutes = freezed,Object? estimated = null,Object? stationsAway = freezed,Object? message = null,Object? destination = freezed,}) {
  return _then(TrainArrival(
minutes: freezed == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int?,estimated: null == estimated ? _self.estimated : estimated // ignore: cast_nullable_to_non_nullable
as bool,stationsAway: freezed == stationsAway ? _self.stationsAway : stationsAway // ignore: cast_nullable_to_non_nullable
as int?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,destination: freezed == destination ? _self.destination : destination // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrainArrival].
extension TrainArrivalPatterns on TrainArrival {
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
