// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filtered_entries_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FilteredEntriesState {

 List<DiaryEntry> get entries; List<Story> get stories; DiaryViewMode get viewMode; bool get loading; bool get failed;
/// Create a copy of FilteredEntriesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilteredEntriesStateCopyWith<FilteredEntriesState> get copyWith => _$FilteredEntriesStateCopyWithImpl<FilteredEntriesState>(this as FilteredEntriesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilteredEntriesState&&const DeepCollectionEquality().equals(other.entries, entries)&&const DeepCollectionEquality().equals(other.stories, stories)&&(identical(other.viewMode, viewMode) || other.viewMode == viewMode)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entries),const DeepCollectionEquality().hash(stories),viewMode,loading,failed);

@override
String toString() {
  return 'FilteredEntriesState(entries: $entries, stories: $stories, viewMode: $viewMode, loading: $loading, failed: $failed)';
}


}

/// @nodoc
abstract mixin class $FilteredEntriesStateCopyWith<$Res>  {
  factory $FilteredEntriesStateCopyWith(FilteredEntriesState value, $Res Function(FilteredEntriesState) _then) = _$FilteredEntriesStateCopyWithImpl;
@useResult
$Res call({
 List<DiaryEntry> entries, List<Story> stories, DiaryViewMode viewMode, bool loading, bool failed
});




}
/// @nodoc
class _$FilteredEntriesStateCopyWithImpl<$Res>
    implements $FilteredEntriesStateCopyWith<$Res> {
  _$FilteredEntriesStateCopyWithImpl(this._self, this._then);

  final FilteredEntriesState _self;
  final $Res Function(FilteredEntriesState) _then;

/// Create a copy of FilteredEntriesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,Object? stories = null,Object? viewMode = null,Object? loading = null,Object? failed = null,}) {
  return _then(FilteredEntriesState(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<DiaryEntry>,stories: null == stories ? _self.stories : stories // ignore: cast_nullable_to_non_nullable
as List<Story>,viewMode: null == viewMode ? _self.viewMode : viewMode // ignore: cast_nullable_to_non_nullable
as DiaryViewMode,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FilteredEntriesState].
extension FilteredEntriesStatePatterns on FilteredEntriesState {
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
