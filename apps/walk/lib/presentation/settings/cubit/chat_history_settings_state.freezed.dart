// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_history_settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatHistorySettingsState {

 ChatRetention get retention; int get conversationCount; WikiIndexSize get wikiIndexSize; int get wikiCount; int get wikiIndexChars;
/// Create a copy of ChatHistorySettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatHistorySettingsStateCopyWith<ChatHistorySettingsState> get copyWith => _$ChatHistorySettingsStateCopyWithImpl<ChatHistorySettingsState>(this as ChatHistorySettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatHistorySettingsState&&(identical(other.retention, retention) || other.retention == retention)&&(identical(other.conversationCount, conversationCount) || other.conversationCount == conversationCount)&&(identical(other.wikiIndexSize, wikiIndexSize) || other.wikiIndexSize == wikiIndexSize)&&(identical(other.wikiCount, wikiCount) || other.wikiCount == wikiCount)&&(identical(other.wikiIndexChars, wikiIndexChars) || other.wikiIndexChars == wikiIndexChars));
}


@override
int get hashCode => Object.hash(runtimeType,retention,conversationCount,wikiIndexSize,wikiCount,wikiIndexChars);

@override
String toString() {
  return 'ChatHistorySettingsState(retention: $retention, conversationCount: $conversationCount, wikiIndexSize: $wikiIndexSize, wikiCount: $wikiCount, wikiIndexChars: $wikiIndexChars)';
}


}

/// @nodoc
abstract mixin class $ChatHistorySettingsStateCopyWith<$Res>  {
  factory $ChatHistorySettingsStateCopyWith(ChatHistorySettingsState value, $Res Function(ChatHistorySettingsState) _then) = _$ChatHistorySettingsStateCopyWithImpl;
@useResult
$Res call({
 ChatRetention retention, int conversationCount, WikiIndexSize wikiIndexSize, int wikiCount, int wikiIndexChars
});




}
/// @nodoc
class _$ChatHistorySettingsStateCopyWithImpl<$Res>
    implements $ChatHistorySettingsStateCopyWith<$Res> {
  _$ChatHistorySettingsStateCopyWithImpl(this._self, this._then);

  final ChatHistorySettingsState _self;
  final $Res Function(ChatHistorySettingsState) _then;

/// Create a copy of ChatHistorySettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? retention = null,Object? conversationCount = null,Object? wikiIndexSize = null,Object? wikiCount = null,Object? wikiIndexChars = null,}) {
  return _then(ChatHistorySettingsState(
retention: null == retention ? _self.retention : retention // ignore: cast_nullable_to_non_nullable
as ChatRetention,conversationCount: null == conversationCount ? _self.conversationCount : conversationCount // ignore: cast_nullable_to_non_nullable
as int,wikiIndexSize: null == wikiIndexSize ? _self.wikiIndexSize : wikiIndexSize // ignore: cast_nullable_to_non_nullable
as WikiIndexSize,wikiCount: null == wikiCount ? _self.wikiCount : wikiCount // ignore: cast_nullable_to_non_nullable
as int,wikiIndexChars: null == wikiIndexChars ? _self.wikiIndexChars : wikiIndexChars // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatHistorySettingsState].
extension ChatHistorySettingsStatePatterns on ChatHistorySettingsState {
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
