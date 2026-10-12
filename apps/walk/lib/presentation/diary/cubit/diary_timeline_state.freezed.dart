// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary_timeline_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiaryTimelineState {

 List<Story> get openStories; List<Story> get archived; String? get selectedStoryId; DiaryViewMode get viewMode; List<DiaryEntry> get entries; bool get loading;
/// Create a copy of DiaryTimelineState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiaryTimelineStateCopyWith<DiaryTimelineState> get copyWith => _$DiaryTimelineStateCopyWithImpl<DiaryTimelineState>(this as DiaryTimelineState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiaryTimelineState&&const DeepCollectionEquality().equals(other.openStories, openStories)&&const DeepCollectionEquality().equals(other.archived, archived)&&(identical(other.selectedStoryId, selectedStoryId) || other.selectedStoryId == selectedStoryId)&&(identical(other.viewMode, viewMode) || other.viewMode == viewMode)&&const DeepCollectionEquality().equals(other.entries, entries)&&(identical(other.loading, loading) || other.loading == loading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(openStories),const DeepCollectionEquality().hash(archived),selectedStoryId,viewMode,const DeepCollectionEquality().hash(entries),loading);

@override
String toString() {
  return 'DiaryTimelineState(openStories: $openStories, archived: $archived, selectedStoryId: $selectedStoryId, viewMode: $viewMode, entries: $entries, loading: $loading)';
}


}

/// @nodoc
abstract mixin class $DiaryTimelineStateCopyWith<$Res>  {
  factory $DiaryTimelineStateCopyWith(DiaryTimelineState value, $Res Function(DiaryTimelineState) _then) = _$DiaryTimelineStateCopyWithImpl;
@useResult
$Res call({
 List<Story> openStories, List<Story> archived, String? selectedStoryId, DiaryViewMode viewMode, List<DiaryEntry> entries, bool loading
});




}
/// @nodoc
class _$DiaryTimelineStateCopyWithImpl<$Res>
    implements $DiaryTimelineStateCopyWith<$Res> {
  _$DiaryTimelineStateCopyWithImpl(this._self, this._then);

  final DiaryTimelineState _self;
  final $Res Function(DiaryTimelineState) _then;

/// Create a copy of DiaryTimelineState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? openStories = null,Object? archived = null,Object? selectedStoryId = freezed,Object? viewMode = null,Object? entries = null,Object? loading = null,}) {
  return _then(DiaryTimelineState(
openStories: null == openStories ? _self.openStories : openStories // ignore: cast_nullable_to_non_nullable
as List<Story>,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as List<Story>,selectedStoryId: freezed == selectedStoryId ? _self.selectedStoryId : selectedStoryId // ignore: cast_nullable_to_non_nullable
as String?,viewMode: null == viewMode ? _self.viewMode : viewMode // ignore: cast_nullable_to_non_nullable
as DiaryViewMode,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<DiaryEntry>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DiaryTimelineState].
extension DiaryTimelineStatePatterns on DiaryTimelineState {
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
