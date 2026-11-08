// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DayTrack {

 List<TrackSegment> get segments; List<Stay> get stays;
/// Create a copy of DayTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayTrackCopyWith<DayTrack> get copyWith => _$DayTrackCopyWithImpl<DayTrack>(this as DayTrack, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayTrack&&const DeepCollectionEquality().equals(other.segments, segments)&&const DeepCollectionEquality().equals(other.stays, stays));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(segments),const DeepCollectionEquality().hash(stays));

@override
String toString() {
  return 'DayTrack(segments: $segments, stays: $stays)';
}


}

/// @nodoc
abstract mixin class $DayTrackCopyWith<$Res>  {
  factory $DayTrackCopyWith(DayTrack value, $Res Function(DayTrack) _then) = _$DayTrackCopyWithImpl;
@useResult
$Res call({
 List<TrackSegment> segments, List<Stay> stays
});




}
/// @nodoc
class _$DayTrackCopyWithImpl<$Res>
    implements $DayTrackCopyWith<$Res> {
  _$DayTrackCopyWithImpl(this._self, this._then);

  final DayTrack _self;
  final $Res Function(DayTrack) _then;

/// Create a copy of DayTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? segments = null,Object? stays = null,}) {
  return _then(DayTrack(
segments: null == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as List<TrackSegment>,stays: null == stays ? _self.stays : stays // ignore: cast_nullable_to_non_nullable
as List<Stay>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayTrack].
extension DayTrackPatterns on DayTrack {
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
