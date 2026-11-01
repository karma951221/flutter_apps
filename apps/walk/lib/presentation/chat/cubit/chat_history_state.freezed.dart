// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatHistoryState {

 bool get loading; List<Conversation> get conversations;
/// Create a copy of ChatHistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatHistoryStateCopyWith<ChatHistoryState> get copyWith => _$ChatHistoryStateCopyWithImpl<ChatHistoryState>(this as ChatHistoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatHistoryState&&(identical(other.loading, loading) || other.loading == loading)&&const DeepCollectionEquality().equals(other.conversations, conversations));
}


@override
int get hashCode => Object.hash(runtimeType,loading,const DeepCollectionEquality().hash(conversations));

@override
String toString() {
  return 'ChatHistoryState(loading: $loading, conversations: $conversations)';
}


}

/// @nodoc
abstract mixin class $ChatHistoryStateCopyWith<$Res>  {
  factory $ChatHistoryStateCopyWith(ChatHistoryState value, $Res Function(ChatHistoryState) _then) = _$ChatHistoryStateCopyWithImpl;
@useResult
$Res call({
 bool loading, List<Conversation> conversations
});




}
/// @nodoc
class _$ChatHistoryStateCopyWithImpl<$Res>
    implements $ChatHistoryStateCopyWith<$Res> {
  _$ChatHistoryStateCopyWithImpl(this._self, this._then);

  final ChatHistoryState _self;
  final $Res Function(ChatHistoryState) _then;

/// Create a copy of ChatHistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loading = null,Object? conversations = null,}) {
  return _then(ChatHistoryState(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,conversations: null == conversations ? _self.conversations : conversations // ignore: cast_nullable_to_non_nullable
as List<Conversation>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatHistoryState].
extension ChatHistoryStatePatterns on ChatHistoryState {
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
