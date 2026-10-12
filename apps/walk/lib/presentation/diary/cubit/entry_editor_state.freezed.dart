// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entry_editor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EntryEditorState {

 String? get editingId; EntryDraft get draft; DateTime get createdAt; List<Story> get openStories; List<Story> get stories; bool get locating; bool get manualPlace; bool get saving; bool get importing; List<EntryMedia> get newMedia; DiaryFailure? get error; bool get failed; bool get saved;
/// Create a copy of EntryEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryEditorStateCopyWith<EntryEditorState> get copyWith => _$EntryEditorStateCopyWithImpl<EntryEditorState>(this as EntryEditorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryEditorState&&(identical(other.editingId, editingId) || other.editingId == editingId)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.openStories, openStories)&&const DeepCollectionEquality().equals(other.stories, stories)&&(identical(other.locating, locating) || other.locating == locating)&&(identical(other.manualPlace, manualPlace) || other.manualPlace == manualPlace)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.importing, importing) || other.importing == importing)&&const DeepCollectionEquality().equals(other.newMedia, newMedia)&&(identical(other.error, error) || other.error == error)&&(identical(other.failed, failed) || other.failed == failed)&&(identical(other.saved, saved) || other.saved == saved));
}


@override
int get hashCode => Object.hash(runtimeType,editingId,draft,createdAt,const DeepCollectionEquality().hash(openStories),const DeepCollectionEquality().hash(stories),locating,manualPlace,saving,importing,const DeepCollectionEquality().hash(newMedia),error,failed,saved);

@override
String toString() {
  return 'EntryEditorState(editingId: $editingId, draft: $draft, createdAt: $createdAt, openStories: $openStories, stories: $stories, locating: $locating, manualPlace: $manualPlace, saving: $saving, importing: $importing, newMedia: $newMedia, error: $error, failed: $failed, saved: $saved)';
}


}

/// @nodoc
abstract mixin class $EntryEditorStateCopyWith<$Res>  {
  factory $EntryEditorStateCopyWith(EntryEditorState value, $Res Function(EntryEditorState) _then) = _$EntryEditorStateCopyWithImpl;
@useResult
$Res call({
 String? editingId, EntryDraft draft, DateTime createdAt, List<Story> openStories, List<Story> stories, bool locating, bool manualPlace, bool saving, bool importing, List<EntryMedia> newMedia, DiaryFailure? error, bool failed, bool saved
});




}
/// @nodoc
class _$EntryEditorStateCopyWithImpl<$Res>
    implements $EntryEditorStateCopyWith<$Res> {
  _$EntryEditorStateCopyWithImpl(this._self, this._then);

  final EntryEditorState _self;
  final $Res Function(EntryEditorState) _then;

/// Create a copy of EntryEditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? editingId = freezed,Object? draft = null,Object? createdAt = null,Object? openStories = null,Object? stories = null,Object? locating = null,Object? manualPlace = null,Object? saving = null,Object? importing = null,Object? newMedia = null,Object? error = freezed,Object? failed = null,Object? saved = null,}) {
  return _then(EntryEditorState(
editingId: freezed == editingId ? _self.editingId : editingId // ignore: cast_nullable_to_non_nullable
as String?,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as EntryDraft,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,openStories: null == openStories ? _self.openStories : openStories // ignore: cast_nullable_to_non_nullable
as List<Story>,stories: null == stories ? _self.stories : stories // ignore: cast_nullable_to_non_nullable
as List<Story>,locating: null == locating ? _self.locating : locating // ignore: cast_nullable_to_non_nullable
as bool,manualPlace: null == manualPlace ? _self.manualPlace : manualPlace // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,importing: null == importing ? _self.importing : importing // ignore: cast_nullable_to_non_nullable
as bool,newMedia: null == newMedia ? _self.newMedia : newMedia // ignore: cast_nullable_to_non_nullable
as List<EntryMedia>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as DiaryFailure?,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,saved: null == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EntryEditorState].
extension EntryEditorStatePatterns on EntryEditorState {
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
