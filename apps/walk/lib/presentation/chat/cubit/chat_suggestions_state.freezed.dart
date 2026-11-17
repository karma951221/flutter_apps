// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_suggestions_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatSuggestionsState {

 List<String>? get questions; bool get canRefresh; bool get refreshing;
/// Create a copy of ChatSuggestionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSuggestionsStateCopyWith<ChatSuggestionsState> get copyWith => _$ChatSuggestionsStateCopyWithImpl<ChatSuggestionsState>(this as ChatSuggestionsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSuggestionsState&&const DeepCollectionEquality().equals(other.questions, questions)&&(identical(other.canRefresh, canRefresh) || other.canRefresh == canRefresh)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(questions),canRefresh,refreshing);

@override
String toString() {
  return 'ChatSuggestionsState(questions: $questions, canRefresh: $canRefresh, refreshing: $refreshing)';
}


}

/// @nodoc
abstract mixin class $ChatSuggestionsStateCopyWith<$Res>  {
  factory $ChatSuggestionsStateCopyWith(ChatSuggestionsState value, $Res Function(ChatSuggestionsState) _then) = _$ChatSuggestionsStateCopyWithImpl;
@useResult
$Res call({
 List<String>? questions, bool canRefresh, bool refreshing
});




}
/// @nodoc
class _$ChatSuggestionsStateCopyWithImpl<$Res>
    implements $ChatSuggestionsStateCopyWith<$Res> {
  _$ChatSuggestionsStateCopyWithImpl(this._self, this._then);

  final ChatSuggestionsState _self;
  final $Res Function(ChatSuggestionsState) _then;

/// Create a copy of ChatSuggestionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questions = freezed,Object? canRefresh = null,Object? refreshing = null,}) {
  return _then(ChatSuggestionsState(
questions: freezed == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<String>?,canRefresh: null == canRefresh ? _self.canRefresh : canRefresh // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatSuggestionsState].
extension ChatSuggestionsStatePatterns on ChatSuggestionsState {
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
