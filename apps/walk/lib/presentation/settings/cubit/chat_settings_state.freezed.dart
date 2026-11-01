// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatSettingsState {

 bool get loading; ChatConnection? get connection; ModelChipData? get model; bool get fastMode; bool get modelsUnavailable;
/// Create a copy of ChatSettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSettingsStateCopyWith<ChatSettingsState> get copyWith => _$ChatSettingsStateCopyWithImpl<ChatSettingsState>(this as ChatSettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSettingsState&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.connection, connection) || other.connection == connection)&&(identical(other.model, model) || other.model == model)&&(identical(other.fastMode, fastMode) || other.fastMode == fastMode)&&(identical(other.modelsUnavailable, modelsUnavailable) || other.modelsUnavailable == modelsUnavailable));
}


@override
int get hashCode => Object.hash(runtimeType,loading,connection,model,fastMode,modelsUnavailable);

@override
String toString() {
  return 'ChatSettingsState(loading: $loading, connection: $connection, model: $model, fastMode: $fastMode, modelsUnavailable: $modelsUnavailable)';
}


}

/// @nodoc
abstract mixin class $ChatSettingsStateCopyWith<$Res>  {
  factory $ChatSettingsStateCopyWith(ChatSettingsState value, $Res Function(ChatSettingsState) _then) = _$ChatSettingsStateCopyWithImpl;
@useResult
$Res call({
 bool loading, ChatConnection? connection, ModelChipData? model, bool fastMode, bool modelsUnavailable
});




}
/// @nodoc
class _$ChatSettingsStateCopyWithImpl<$Res>
    implements $ChatSettingsStateCopyWith<$Res> {
  _$ChatSettingsStateCopyWithImpl(this._self, this._then);

  final ChatSettingsState _self;
  final $Res Function(ChatSettingsState) _then;

/// Create a copy of ChatSettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loading = null,Object? connection = freezed,Object? model = freezed,Object? fastMode = null,Object? modelsUnavailable = null,}) {
  return _then(ChatSettingsState(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,connection: freezed == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as ChatConnection?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as ModelChipData?,fastMode: null == fastMode ? _self.fastMode : fastMode // ignore: cast_nullable_to_non_nullable
as bool,modelsUnavailable: null == modelsUnavailable ? _self.modelsUnavailable : modelsUnavailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatSettingsState].
extension ChatSettingsStatePatterns on ChatSettingsState {
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
