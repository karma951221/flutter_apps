// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatBubble {

 ChatRole get role; String get text; List<DiaryEntry> get cited; ChatFailure? get failure; bool get stopped; int? get seq;
/// Create a copy of ChatBubble
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatBubbleCopyWith<ChatBubble> get copyWith => _$ChatBubbleCopyWithImpl<ChatBubble>(this as ChatBubble, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatBubble&&(identical(other.role, role) || other.role == role)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.cited, cited)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.stopped, stopped) || other.stopped == stopped)&&(identical(other.seq, seq) || other.seq == seq));
}


@override
int get hashCode => Object.hash(runtimeType,role,text,const DeepCollectionEquality().hash(cited),failure,stopped,seq);

@override
String toString() {
  return 'ChatBubble(role: $role, text: $text, cited: $cited, failure: $failure, stopped: $stopped, seq: $seq)';
}


}

/// @nodoc
abstract mixin class $ChatBubbleCopyWith<$Res>  {
  factory $ChatBubbleCopyWith(ChatBubble value, $Res Function(ChatBubble) _then) = _$ChatBubbleCopyWithImpl;
@useResult
$Res call({
 ChatRole role, String text, List<DiaryEntry> cited, ChatFailure? failure, bool stopped, int? seq
});




}
/// @nodoc
class _$ChatBubbleCopyWithImpl<$Res>
    implements $ChatBubbleCopyWith<$Res> {
  _$ChatBubbleCopyWithImpl(this._self, this._then);

  final ChatBubble _self;
  final $Res Function(ChatBubble) _then;

/// Create a copy of ChatBubble
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? text = null,Object? cited = null,Object? failure = freezed,Object? stopped = null,Object? seq = freezed,}) {
  return _then(ChatBubble(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ChatRole,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,cited: null == cited ? _self.cited : cited // ignore: cast_nullable_to_non_nullable
as List<DiaryEntry>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ChatFailure?,stopped: null == stopped ? _self.stopped : stopped // ignore: cast_nullable_to_non_nullable
as bool,seq: freezed == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatBubble].
extension ChatBubblePatterns on ChatBubble {
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

/// @nodoc
mixin _$ChatState {

 ChatAccess get access; List<ChatBubble> get bubbles; bool get busy; String? get activeTool; String? get restoredDraft; String? get conversationId; bool get temporary; ChatVendor get vendor;
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStateCopyWith<ChatState> get copyWith => _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatState&&(identical(other.access, access) || other.access == access)&&const DeepCollectionEquality().equals(other.bubbles, bubbles)&&(identical(other.busy, busy) || other.busy == busy)&&(identical(other.activeTool, activeTool) || other.activeTool == activeTool)&&(identical(other.restoredDraft, restoredDraft) || other.restoredDraft == restoredDraft)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.temporary, temporary) || other.temporary == temporary)&&(identical(other.vendor, vendor) || other.vendor == vendor));
}


@override
int get hashCode => Object.hash(runtimeType,access,const DeepCollectionEquality().hash(bubbles),busy,activeTool,restoredDraft,conversationId,temporary,vendor);

@override
String toString() {
  return 'ChatState(access: $access, bubbles: $bubbles, busy: $busy, activeTool: $activeTool, restoredDraft: $restoredDraft, conversationId: $conversationId, temporary: $temporary, vendor: $vendor)';
}


}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res>  {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) = _$ChatStateCopyWithImpl;
@useResult
$Res call({
 ChatAccess access, List<ChatBubble> bubbles, bool busy, String? activeTool, String? restoredDraft, String? conversationId, bool temporary, ChatVendor vendor
});




}
/// @nodoc
class _$ChatStateCopyWithImpl<$Res>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._self, this._then);

  final ChatState _self;
  final $Res Function(ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? access = null,Object? bubbles = null,Object? busy = null,Object? activeTool = freezed,Object? restoredDraft = freezed,Object? conversationId = freezed,Object? temporary = null,Object? vendor = null,}) {
  return _then(ChatState(
access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as ChatAccess,bubbles: null == bubbles ? _self.bubbles : bubbles // ignore: cast_nullable_to_non_nullable
as List<ChatBubble>,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,activeTool: freezed == activeTool ? _self.activeTool : activeTool // ignore: cast_nullable_to_non_nullable
as String?,restoredDraft: freezed == restoredDraft ? _self.restoredDraft : restoredDraft // ignore: cast_nullable_to_non_nullable
as String?,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,temporary: null == temporary ? _self.temporary : temporary // ignore: cast_nullable_to_non_nullable
as bool,vendor: null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as ChatVendor,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatState].
extension ChatStatePatterns on ChatState {
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
