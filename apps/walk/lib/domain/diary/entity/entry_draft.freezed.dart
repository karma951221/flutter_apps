// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entry_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EntryDraft {

 String get storyId; String get body; DateTime get occurredAt; EntryLocation? get location; List<EntryMedia> get media; List<String> get tags;
/// Create a copy of EntryDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryDraftCopyWith<EntryDraft> get copyWith => _$EntryDraftCopyWithImpl<EntryDraft>(this as EntryDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryDraft&&(identical(other.storyId, storyId) || other.storyId == storyId)&&(identical(other.body, body) || other.body == body)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.media, media)&&const DeepCollectionEquality().equals(other.tags, tags));
}


@override
int get hashCode => Object.hash(runtimeType,storyId,body,occurredAt,location,const DeepCollectionEquality().hash(media),const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'EntryDraft(storyId: $storyId, body: $body, occurredAt: $occurredAt, location: $location, media: $media, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $EntryDraftCopyWith<$Res>  {
  factory $EntryDraftCopyWith(EntryDraft value, $Res Function(EntryDraft) _then) = _$EntryDraftCopyWithImpl;
@useResult
$Res call({
 String storyId, String body, DateTime occurredAt, EntryLocation? location, List<EntryMedia> media, List<String> tags
});




}
/// @nodoc
class _$EntryDraftCopyWithImpl<$Res>
    implements $EntryDraftCopyWith<$Res> {
  _$EntryDraftCopyWithImpl(this._self, this._then);

  final EntryDraft _self;
  final $Res Function(EntryDraft) _then;

/// Create a copy of EntryDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? storyId = null,Object? body = null,Object? occurredAt = null,Object? location = freezed,Object? media = null,Object? tags = null,}) {
  return _then(EntryDraft(
storyId: null == storyId ? _self.storyId : storyId // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as EntryLocation?,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as List<EntryMedia>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [EntryDraft].
extension EntryDraftPatterns on EntryDraft {
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
