// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkDraft {

 DateTime get startedAt; DateTime get endedAt; double get distanceMeters; List<WalkTrackPoint> get points; List<String> get dogIds; String? get memo; List<String> get photoPaths;
/// Create a copy of WalkDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkDraftCopyWith<WalkDraft> get copyWith => _$WalkDraftCopyWithImpl<WalkDraft>(this as WalkDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkDraft&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&const DeepCollectionEquality().equals(other.points, points)&&const DeepCollectionEquality().equals(other.dogIds, dogIds)&&(identical(other.memo, memo) || other.memo == memo)&&const DeepCollectionEquality().equals(other.photoPaths, photoPaths));
}


@override
int get hashCode => Object.hash(runtimeType,startedAt,endedAt,distanceMeters,const DeepCollectionEquality().hash(points),const DeepCollectionEquality().hash(dogIds),memo,const DeepCollectionEquality().hash(photoPaths));

@override
String toString() {
  return 'WalkDraft(startedAt: $startedAt, endedAt: $endedAt, distanceMeters: $distanceMeters, points: $points, dogIds: $dogIds, memo: $memo, photoPaths: $photoPaths)';
}


}

/// @nodoc
abstract mixin class $WalkDraftCopyWith<$Res>  {
  factory $WalkDraftCopyWith(WalkDraft value, $Res Function(WalkDraft) _then) = _$WalkDraftCopyWithImpl;
@useResult
$Res call({
 DateTime startedAt, DateTime endedAt, double distanceMeters, List<WalkTrackPoint> points, List<String> dogIds, String? memo, List<String> photoPaths
});




}
/// @nodoc
class _$WalkDraftCopyWithImpl<$Res>
    implements $WalkDraftCopyWith<$Res> {
  _$WalkDraftCopyWithImpl(this._self, this._then);

  final WalkDraft _self;
  final $Res Function(WalkDraft) _then;

/// Create a copy of WalkDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startedAt = null,Object? endedAt = null,Object? distanceMeters = null,Object? points = null,Object? dogIds = null,Object? memo = freezed,Object? photoPaths = null,}) {
  return _then(WalkDraft(
startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: null == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<WalkTrackPoint>,dogIds: null == dogIds ? _self.dogIds : dogIds // ignore: cast_nullable_to_non_nullable
as List<String>,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,photoPaths: null == photoPaths ? _self.photoPaths : photoPaths // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [WalkDraft].
extension WalkDraftPatterns on WalkDraft {
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
