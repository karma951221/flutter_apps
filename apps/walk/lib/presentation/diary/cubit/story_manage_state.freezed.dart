// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story_manage_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StoryManageState {

 List<Story> get open; List<Story> get archived; bool get loading; bool get failed; DiaryFailure? get error; bool get actionFailed; Story? get created;
/// Create a copy of StoryManageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoryManageStateCopyWith<StoryManageState> get copyWith => _$StoryManageStateCopyWithImpl<StoryManageState>(this as StoryManageState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoryManageState&&const DeepCollectionEquality().equals(other.open, open)&&const DeepCollectionEquality().equals(other.archived, archived)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.failed, failed) || other.failed == failed)&&(identical(other.error, error) || other.error == error)&&(identical(other.actionFailed, actionFailed) || other.actionFailed == actionFailed)&&(identical(other.created, created) || other.created == created));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(open),const DeepCollectionEquality().hash(archived),loading,failed,error,actionFailed,created);

@override
String toString() {
  return 'StoryManageState(open: $open, archived: $archived, loading: $loading, failed: $failed, error: $error, actionFailed: $actionFailed, created: $created)';
}


}

/// @nodoc
abstract mixin class $StoryManageStateCopyWith<$Res>  {
  factory $StoryManageStateCopyWith(StoryManageState value, $Res Function(StoryManageState) _then) = _$StoryManageStateCopyWithImpl;
@useResult
$Res call({
 List<Story> open, List<Story> archived, bool loading, bool failed, DiaryFailure? error, bool actionFailed, Story? created
});




}
/// @nodoc
class _$StoryManageStateCopyWithImpl<$Res>
    implements $StoryManageStateCopyWith<$Res> {
  _$StoryManageStateCopyWithImpl(this._self, this._then);

  final StoryManageState _self;
  final $Res Function(StoryManageState) _then;

/// Create a copy of StoryManageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? open = null,Object? archived = null,Object? loading = null,Object? failed = null,Object? error = freezed,Object? actionFailed = null,Object? created = freezed,}) {
  return _then(StoryManageState(
open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as List<Story>,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as List<Story>,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,failed: null == failed ? _self.failed : failed // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as DiaryFailure?,actionFailed: null == actionFailed ? _self.actionFailed : actionFailed // ignore: cast_nullable_to_non_nullable
as bool,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as Story?,
  ));
}

}


/// Adds pattern-matching-related methods to [StoryManageState].
extension StoryManageStatePatterns on StoryManageState {
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
