// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draft_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DraftContext {

 String get memo; DateTime get occurredAt; String? get placeName; bool get autoPlace; DateTime? get now; String? get locale; int get photoCount; int get videoCount; DateTime? get photoTakenFrom; DateTime? get photoTakenTo; List<String> get tags;
/// Create a copy of DraftContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftContextCopyWith<DraftContext> get copyWith => _$DraftContextCopyWithImpl<DraftContext>(this as DraftContext, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftContext&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.placeName, placeName) || other.placeName == placeName)&&(identical(other.autoPlace, autoPlace) || other.autoPlace == autoPlace)&&(identical(other.now, now) || other.now == now)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.photoCount, photoCount) || other.photoCount == photoCount)&&(identical(other.videoCount, videoCount) || other.videoCount == videoCount)&&(identical(other.photoTakenFrom, photoTakenFrom) || other.photoTakenFrom == photoTakenFrom)&&(identical(other.photoTakenTo, photoTakenTo) || other.photoTakenTo == photoTakenTo)&&const DeepCollectionEquality().equals(other.tags, tags));
}


@override
int get hashCode => Object.hash(runtimeType,memo,occurredAt,placeName,autoPlace,now,locale,photoCount,videoCount,photoTakenFrom,photoTakenTo,const DeepCollectionEquality().hash(tags));



}

/// @nodoc
abstract mixin class $DraftContextCopyWith<$Res>  {
  factory $DraftContextCopyWith(DraftContext value, $Res Function(DraftContext) _then) = _$DraftContextCopyWithImpl;
@useResult
$Res call({
 String memo, DateTime occurredAt, String? placeName, bool autoPlace, DateTime? now, String? locale, int photoCount, int videoCount, DateTime? photoTakenFrom, DateTime? photoTakenTo, List<String> tags
});




}
/// @nodoc
class _$DraftContextCopyWithImpl<$Res>
    implements $DraftContextCopyWith<$Res> {
  _$DraftContextCopyWithImpl(this._self, this._then);

  final DraftContext _self;
  final $Res Function(DraftContext) _then;

/// Create a copy of DraftContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memo = null,Object? occurredAt = null,Object? placeName = freezed,Object? autoPlace = null,Object? now = freezed,Object? locale = freezed,Object? photoCount = null,Object? videoCount = null,Object? photoTakenFrom = freezed,Object? photoTakenTo = freezed,Object? tags = null,}) {
  return _then(DraftContext(
memo: null == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,placeName: freezed == placeName ? _self.placeName : placeName // ignore: cast_nullable_to_non_nullable
as String?,autoPlace: null == autoPlace ? _self.autoPlace : autoPlace // ignore: cast_nullable_to_non_nullable
as bool,now: freezed == now ? _self.now : now // ignore: cast_nullable_to_non_nullable
as DateTime?,locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String?,photoCount: null == photoCount ? _self.photoCount : photoCount // ignore: cast_nullable_to_non_nullable
as int,videoCount: null == videoCount ? _self.videoCount : videoCount // ignore: cast_nullable_to_non_nullable
as int,photoTakenFrom: freezed == photoTakenFrom ? _self.photoTakenFrom : photoTakenFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,photoTakenTo: freezed == photoTakenTo ? _self.photoTakenTo : photoTakenTo // ignore: cast_nullable_to_non_nullable
as DateTime?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [DraftContext].
extension DraftContextPatterns on DraftContext {
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
