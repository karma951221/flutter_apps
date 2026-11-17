// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_suggestions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatSuggestions {

 List<String> get questions; DateTime get generatedAt; DateTime get basedOnAskedAt;
/// Create a copy of ChatSuggestions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSuggestionsCopyWith<ChatSuggestions> get copyWith => _$ChatSuggestionsCopyWithImpl<ChatSuggestions>(this as ChatSuggestions, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSuggestions&&const DeepCollectionEquality().equals(other.questions, questions)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.basedOnAskedAt, basedOnAskedAt) || other.basedOnAskedAt == basedOnAskedAt));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(questions),generatedAt,basedOnAskedAt);

@override
String toString() {
  return 'ChatSuggestions(questions: $questions, generatedAt: $generatedAt, basedOnAskedAt: $basedOnAskedAt)';
}


}

/// @nodoc
abstract mixin class $ChatSuggestionsCopyWith<$Res>  {
  factory $ChatSuggestionsCopyWith(ChatSuggestions value, $Res Function(ChatSuggestions) _then) = _$ChatSuggestionsCopyWithImpl;
@useResult
$Res call({
 List<String> questions, DateTime generatedAt, DateTime basedOnAskedAt
});




}
/// @nodoc
class _$ChatSuggestionsCopyWithImpl<$Res>
    implements $ChatSuggestionsCopyWith<$Res> {
  _$ChatSuggestionsCopyWithImpl(this._self, this._then);

  final ChatSuggestions _self;
  final $Res Function(ChatSuggestions) _then;

/// Create a copy of ChatSuggestions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questions = null,Object? generatedAt = null,Object? basedOnAskedAt = null,}) {
  return _then(ChatSuggestions(
questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<String>,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,basedOnAskedAt: null == basedOnAskedAt ? _self.basedOnAskedAt : basedOnAskedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatSuggestions].
extension ChatSuggestionsPatterns on ChatSuggestions {
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
