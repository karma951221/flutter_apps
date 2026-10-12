// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diary_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiarySearchState {

 SearchScope get scope; String get query; String get searched; List<NamedCount> get suggestions; List<({Story story, int count})> get stories; List<DiaryEntry> get bodyResults; bool get loading; bool get failed;
/// Create a copy of DiarySearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiarySearchStateCopyWith<DiarySearchState> get copyWith => _$DiarySearchStateCopyWithImpl<DiarySearchState>(this as DiarySearchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiarySearchState&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.query, query) || other.query == query)&&(identical(other.searched, searched) || other.searched == searched)&&const DeepCollectionEquality().equals(other.suggestions, suggestions)&&const DeepCollectionEquality().equals(other.stories, stories)&&const DeepCollectionEquality().equals(other.bodyResults, bodyResults)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,scope,query,searched,const DeepCollectionEquality().hash(suggestions),const DeepCollectionEquality().hash(stories),const DeepCollectionEquality().hash(bodyResults),loading,failed);

@override
String toString() {
  return 'DiarySearchState(scope: $scope, query: $query, searched: $searched, suggestions: $suggestions, stories: $stories, bodyResults: $bodyResults, loading: $loading, failed: $failed)';
}


}

/// @nodoc
abstract mixin class $DiarySearchStateCopyWith<$Res>  {
  factory $DiarySearchStateCopyWith(DiarySearchState value, $Res Function(DiarySearchState) _then) = _$DiarySearchStateCopyWithImpl;
@useResult
$Res call({
 SearchScope scope, String query, String searched, List<NamedCount> suggestions, List<({int count, Story story})> stories, List<DiaryEntry> bodyResults, bool loading, bool failed
});




}
/// @nodoc
class _$DiarySearchStateCopyWithImpl<$Res>
    implements $DiarySearchStateCopyWith<$Res> {
  _$DiarySearchStateCopyWithImpl(this._self, this._then);

  final DiarySearchState _self;
  final $Res Function(DiarySearchState) _then;

/// Create a copy of DiarySearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scope = null,Object? query = null,Object? searched = null,Object? suggestions = null,Object? stories = null,Object? bodyResults = null,Object? loading = null,Object? failed = null,}) {
  return _then(DiarySearchState(
scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as SearchScope,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,searched: null == searched ? _self.searched : searched // ignore: cast_nullable_to_non_nullable
as String,suggestions: null == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<NamedCount>,stories: null == stories ? _self.stories : stories // ignore: cast_nullable_to_non_nullable
as List<({int count, Story story})>,bodyResults: null == bodyResults ? _self.bodyResults : bodyResults // ignore: cast_nullable_to_non_nullable
as List<DiaryEntry>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DiarySearchState].
extension DiarySearchStatePatterns on DiarySearchState {
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
