// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wiki_note_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WikiNoteState {

 bool get loading; WikiNote? get note; Map<int, WikiNote> get linkedNotes; Map<String, DiaryEntry> get linkedEntries; List<WikiNote> get backlinks; bool get sourceExists; bool get deleted; bool get failed;
/// Create a copy of WikiNoteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiNoteStateCopyWith<WikiNoteState> get copyWith => _$WikiNoteStateCopyWithImpl<WikiNoteState>(this as WikiNoteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiNoteState&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.linkedNotes, linkedNotes)&&const DeepCollectionEquality().equals(other.linkedEntries, linkedEntries)&&const DeepCollectionEquality().equals(other.backlinks, backlinks)&&(identical(other.sourceExists, sourceExists) || other.sourceExists == sourceExists)&&(identical(other.deleted, deleted) || other.deleted == deleted)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,loading,note,const DeepCollectionEquality().hash(linkedNotes),const DeepCollectionEquality().hash(linkedEntries),const DeepCollectionEquality().hash(backlinks),sourceExists,deleted,failed);



}

/// @nodoc
abstract mixin class $WikiNoteStateCopyWith<$Res>  {
  factory $WikiNoteStateCopyWith(WikiNoteState value, $Res Function(WikiNoteState) _then) = _$WikiNoteStateCopyWithImpl;
@useResult
$Res call({
 bool loading, WikiNote? note, Map<int, WikiNote> linkedNotes, Map<String, DiaryEntry> linkedEntries, List<WikiNote> backlinks, bool sourceExists, bool deleted, bool failed
});




}
/// @nodoc
class _$WikiNoteStateCopyWithImpl<$Res>
    implements $WikiNoteStateCopyWith<$Res> {
  _$WikiNoteStateCopyWithImpl(this._self, this._then);

  final WikiNoteState _self;
  final $Res Function(WikiNoteState) _then;

/// Create a copy of WikiNoteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loading = null,Object? note = freezed,Object? linkedNotes = null,Object? linkedEntries = null,Object? backlinks = null,Object? sourceExists = null,Object? deleted = null,Object? failed = null,}) {
  return _then(WikiNoteState(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as WikiNote?,linkedNotes: null == linkedNotes ? _self.linkedNotes : linkedNotes // ignore: cast_nullable_to_non_nullable
as Map<int, WikiNote>,linkedEntries: null == linkedEntries ? _self.linkedEntries : linkedEntries // ignore: cast_nullable_to_non_nullable
as Map<String, DiaryEntry>,backlinks: null == backlinks ? _self.backlinks : backlinks // ignore: cast_nullable_to_non_nullable
as List<WikiNote>,sourceExists: null == sourceExists ? _self.sourceExists : sourceExists // ignore: cast_nullable_to_non_nullable
as bool,deleted: null == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WikiNoteState].
extension WikiNoteStatePatterns on WikiNoteState {
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
