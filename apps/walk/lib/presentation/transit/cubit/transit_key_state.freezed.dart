// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transit_key_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransitKeyState {

 bool get loading; String? get keyPreview; TransitKeyStatus? get status; bool get busy; String? get rejectedMessage;
/// Create a copy of TransitKeyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitKeyStateCopyWith<TransitKeyState> get copyWith => _$TransitKeyStateCopyWithImpl<TransitKeyState>(this as TransitKeyState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitKeyState&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.keyPreview, keyPreview) || other.keyPreview == keyPreview)&&(identical(other.status, status) || other.status == status)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.rejectedMessage, rejectedMessage) || other.rejectedMessage == rejectedMessage));
}


@override
int get hashCode => Object.hash(runtimeType,loading,keyPreview,status,busy,rejectedMessage);

@override
String toString() {
  return 'TransitKeyState(loading: $loading, keyPreview: $keyPreview, status: $status, busy: $busy, rejectedMessage: $rejectedMessage)';
}


}

/// @nodoc
abstract mixin class $TransitKeyStateCopyWith<$Res>  {
  factory $TransitKeyStateCopyWith(TransitKeyState value, $Res Function(TransitKeyState) _then) = _$TransitKeyStateCopyWithImpl;
@useResult
$Res call({
 bool loading, String? keyPreview, TransitKeyStatus? status, bool busy, String? rejectedMessage
});




}
/// @nodoc
class _$TransitKeyStateCopyWithImpl<$Res>
    implements $TransitKeyStateCopyWith<$Res> {
  _$TransitKeyStateCopyWithImpl(this._self, this._then);

  final TransitKeyState _self;
  final $Res Function(TransitKeyState) _then;

/// Create a copy of TransitKeyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loading = null,Object? keyPreview = freezed,Object? status = freezed,Object? busy = null,Object? rejectedMessage = freezed,}) {
  return _then(TransitKeyState(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,keyPreview: freezed == keyPreview ? _self.keyPreview : keyPreview // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransitKeyStatus?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,rejectedMessage: freezed == rejectedMessage ? _self.rejectedMessage : rejectedMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransitKeyState].
extension TransitKeyStatePatterns on TransitKeyState {
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
