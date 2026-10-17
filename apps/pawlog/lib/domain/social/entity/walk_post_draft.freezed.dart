// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_post_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalkPostDraft {

 String get localWalkId; DateTime get startedAt; Duration get duration; double get distanceMeters; List<String> get dogNames; String? get memo; List<GeoPoint> get routePreview;
/// Create a copy of WalkPostDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkPostDraftCopyWith<WalkPostDraft> get copyWith => _$WalkPostDraftCopyWithImpl<WalkPostDraft>(this as WalkPostDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkPostDraft&&(identical(other.localWalkId, localWalkId) || other.localWalkId == localWalkId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&const DeepCollectionEquality().equals(other.dogNames, dogNames)&&(identical(other.memo, memo) || other.memo == memo)&&const DeepCollectionEquality().equals(other.routePreview, routePreview));
}


@override
int get hashCode => Object.hash(runtimeType,localWalkId,startedAt,duration,distanceMeters,const DeepCollectionEquality().hash(dogNames),memo,const DeepCollectionEquality().hash(routePreview));

@override
String toString() {
  return 'WalkPostDraft(localWalkId: $localWalkId, startedAt: $startedAt, duration: $duration, distanceMeters: $distanceMeters, dogNames: $dogNames, memo: $memo, routePreview: $routePreview)';
}


}

/// @nodoc
abstract mixin class $WalkPostDraftCopyWith<$Res>  {
  factory $WalkPostDraftCopyWith(WalkPostDraft value, $Res Function(WalkPostDraft) _then) = _$WalkPostDraftCopyWithImpl;
@useResult
$Res call({
 String localWalkId, DateTime startedAt, Duration duration, double distanceMeters, List<String> dogNames, String? memo, List<GeoPoint> routePreview
});




}
/// @nodoc
class _$WalkPostDraftCopyWithImpl<$Res>
    implements $WalkPostDraftCopyWith<$Res> {
  _$WalkPostDraftCopyWithImpl(this._self, this._then);

  final WalkPostDraft _self;
  final $Res Function(WalkPostDraft) _then;

/// Create a copy of WalkPostDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localWalkId = null,Object? startedAt = null,Object? duration = null,Object? distanceMeters = null,Object? dogNames = null,Object? memo = freezed,Object? routePreview = null,}) {
  return _then(WalkPostDraft(
localWalkId: null == localWalkId ? _self.localWalkId : localWalkId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,dogNames: null == dogNames ? _self.dogNames : dogNames // ignore: cast_nullable_to_non_nullable
as List<String>,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,routePreview: null == routePreview ? _self.routePreview : routePreview // ignore: cast_nullable_to_non_nullable
as List<GeoPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [WalkPostDraft].
extension WalkPostDraftPatterns on WalkPostDraft {
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
