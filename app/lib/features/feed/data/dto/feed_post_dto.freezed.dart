// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_post_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeedPostDto {

 String get id; String get authorId; String get content; DateTime get createdAt; DateTime get updatedAt; String get authorNickname; String? get authorAvatarUrl; List<FeedPostImageDto> get images;
/// Create a copy of FeedPostDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedPostDtoCopyWith<FeedPostDto> get copyWith => _$FeedPostDtoCopyWithImpl<FeedPostDto>(this as FeedPostDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedPostDto&&(identical(other.id, id) || other.id == id)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.authorNickname, authorNickname) || other.authorNickname == authorNickname)&&(identical(other.authorAvatarUrl, authorAvatarUrl) || other.authorAvatarUrl == authorAvatarUrl)&&const DeepCollectionEquality().equals(other.images, images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorId,content,createdAt,updatedAt,authorNickname,authorAvatarUrl,const DeepCollectionEquality().hash(images));

@override
String toString() {
  return 'FeedPostDto(id: $id, authorId: $authorId, content: $content, createdAt: $createdAt, updatedAt: $updatedAt, authorNickname: $authorNickname, authorAvatarUrl: $authorAvatarUrl, images: $images)';
}


}

/// @nodoc
abstract mixin class $FeedPostDtoCopyWith<$Res>  {
  factory $FeedPostDtoCopyWith(FeedPostDto value, $Res Function(FeedPostDto) _then) = _$FeedPostDtoCopyWithImpl;
@useResult
$Res call({
 String id, String authorId, String content, DateTime createdAt, DateTime updatedAt, String authorNickname, String? authorAvatarUrl, List<FeedPostImageDto> images
});




}
/// @nodoc
class _$FeedPostDtoCopyWithImpl<$Res>
    implements $FeedPostDtoCopyWith<$Res> {
  _$FeedPostDtoCopyWithImpl(this._self, this._then);

  final FeedPostDto _self;
  final $Res Function(FeedPostDto) _then;

/// Create a copy of FeedPostDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorId = null,Object? content = null,Object? createdAt = null,Object? updatedAt = null,Object? authorNickname = null,Object? authorAvatarUrl = freezed,Object? images = null,}) {
  return _then(FeedPostDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,authorNickname: null == authorNickname ? _self.authorNickname : authorNickname // ignore: cast_nullable_to_non_nullable
as String,authorAvatarUrl: freezed == authorAvatarUrl ? _self.authorAvatarUrl : authorAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<FeedPostImageDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedPostDto].
extension FeedPostDtoPatterns on FeedPostDto {
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
