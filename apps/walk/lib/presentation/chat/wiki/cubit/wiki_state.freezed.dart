// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wiki_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WikiState {

 bool get loading; List<WikiNote> get notes; bool get hasMore; bool get loadingMore; String get query; String get searched; int get total; Set<int> get indexedIds; int get indexChars; WikiIndexSize get size; bool get failed;
/// Create a copy of WikiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WikiStateCopyWith<WikiState> get copyWith => _$WikiStateCopyWithImpl<WikiState>(this as WikiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WikiState&&(identical(other.loading, loading) || other.loading == loading)&&const DeepCollectionEquality().equals(other.notes, notes)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.query, query) || other.query == query)&&(identical(other.searched, searched) || other.searched == searched)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.indexedIds, indexedIds)&&(identical(other.indexChars, indexChars) || other.indexChars == indexChars)&&(identical(other.size, size) || other.size == size)&&(identical(other.failed, failed) || other.failed == failed));
}


@override
int get hashCode => Object.hash(runtimeType,loading,const DeepCollectionEquality().hash(notes),hasMore,loadingMore,query,searched,total,const DeepCollectionEquality().hash(indexedIds),indexChars,size,failed);



}

/// @nodoc
abstract mixin class $WikiStateCopyWith<$Res>  {
  factory $WikiStateCopyWith(WikiState value, $Res Function(WikiState) _then) = _$WikiStateCopyWithImpl;
@useResult
$Res call({
 bool loading, List<WikiNote> notes, bool hasMore, bool loadingMore, String query, String searched, int total, Set<int> indexedIds, int indexChars, WikiIndexSize size, bool failed
});




}
/// @nodoc
class _$WikiStateCopyWithImpl<$Res>
    implements $WikiStateCopyWith<$Res> {
  _$WikiStateCopyWithImpl(this._self, this._then);

  final WikiState _self;
  final $Res Function(WikiState) _then;

/// Create a copy of WikiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loading = null,Object? notes = null,Object? hasMore = null,Object? loadingMore = null,Object? query = null,Object? searched = null,Object? total = null,Object? indexedIds = null,Object? indexChars = null,Object? size = null,Object? failed = null,}) {
  return _then(WikiState(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<WikiNote>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,searched: null == searched ? _self.searched : searched // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,indexedIds: null == indexedIds ? _self.indexedIds : indexedIds // ignore: cast_nullable_to_non_nullable
as Set<int>,indexChars: null == indexChars ? _self.indexChars : indexChars // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as WikiIndexSize,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WikiState].
extension WikiStatePatterns on WikiState {
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
