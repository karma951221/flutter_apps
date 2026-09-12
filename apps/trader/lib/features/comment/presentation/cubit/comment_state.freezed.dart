// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommentState {

 CommentStatus get status; List<PostComment> get items; bool get isLoadingMore; String? get nextCursor; Failure? get failure; Map<String, List<PostComment>> get replies; Set<String> get expandedParentIds; Set<String> get loadingParentIds; Map<String, String?> get replyCursors; bool get isSubmitting; int get countDelta;
/// Create a copy of CommentState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentStateCopyWith<CommentState> get copyWith => _$CommentStateCopyWithImpl<CommentState>(this as CommentState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.failure, failure) || other.failure == failure)&&const DeepCollectionEquality().equals(other.replies, replies)&&const DeepCollectionEquality().equals(other.expandedParentIds, expandedParentIds)&&const DeepCollectionEquality().equals(other.loadingParentIds, loadingParentIds)&&const DeepCollectionEquality().equals(other.replyCursors, replyCursors)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.countDelta, countDelta) || other.countDelta == countDelta));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(items),isLoadingMore,nextCursor,failure,const DeepCollectionEquality().hash(replies),const DeepCollectionEquality().hash(expandedParentIds),const DeepCollectionEquality().hash(loadingParentIds),const DeepCollectionEquality().hash(replyCursors),isSubmitting,countDelta);

@override
String toString() {
  return 'CommentState(status: $status, items: $items, isLoadingMore: $isLoadingMore, nextCursor: $nextCursor, failure: $failure, replies: $replies, expandedParentIds: $expandedParentIds, loadingParentIds: $loadingParentIds, replyCursors: $replyCursors, isSubmitting: $isSubmitting, countDelta: $countDelta)';
}


}

/// @nodoc
abstract mixin class $CommentStateCopyWith<$Res>  {
  factory $CommentStateCopyWith(CommentState value, $Res Function(CommentState) _then) = _$CommentStateCopyWithImpl;
@useResult
$Res call({
 CommentStatus status, List<PostComment> items, bool isLoadingMore, String? nextCursor, Failure? failure, Map<String, List<PostComment>> replies, Set<String> expandedParentIds, Set<String> loadingParentIds, Map<String, String?> replyCursors, bool isSubmitting, int countDelta
});




}
/// @nodoc
class _$CommentStateCopyWithImpl<$Res>
    implements $CommentStateCopyWith<$Res> {
  _$CommentStateCopyWithImpl(this._self, this._then);

  final CommentState _self;
  final $Res Function(CommentState) _then;

/// Create a copy of CommentState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? items = null,Object? isLoadingMore = null,Object? nextCursor = freezed,Object? failure = freezed,Object? replies = null,Object? expandedParentIds = null,Object? loadingParentIds = null,Object? replyCursors = null,Object? isSubmitting = null,Object? countDelta = null,}) {
  return _then(CommentState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CommentStatus,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PostComment>,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,replies: null == replies ? _self.replies : replies // ignore: cast_nullable_to_non_nullable
as Map<String, List<PostComment>>,expandedParentIds: null == expandedParentIds ? _self.expandedParentIds : expandedParentIds // ignore: cast_nullable_to_non_nullable
as Set<String>,loadingParentIds: null == loadingParentIds ? _self.loadingParentIds : loadingParentIds // ignore: cast_nullable_to_non_nullable
as Set<String>,replyCursors: null == replyCursors ? _self.replyCursors : replyCursors // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,countDelta: null == countDelta ? _self.countDelta : countDelta // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentState].
extension CommentStatePatterns on CommentState {
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
