// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatMessage {

 String get id; String get roomId; ChatMessageType get type; DateTime get createdAt; String? get senderId; String? get content; String? get imagePath; ChatSystemEvent? get systemEvent; String? get senderNickname; ChatMessageDelivery get delivery;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.systemEvent, systemEvent) || other.systemEvent == systemEvent)&&(identical(other.senderNickname, senderNickname) || other.senderNickname == senderNickname)&&(identical(other.delivery, delivery) || other.delivery == delivery));
}


@override
int get hashCode => Object.hash(runtimeType,id,roomId,type,createdAt,senderId,content,imagePath,systemEvent,senderNickname,delivery);

@override
String toString() {
  return 'ChatMessage(id: $id, roomId: $roomId, type: $type, createdAt: $createdAt, senderId: $senderId, content: $content, imagePath: $imagePath, systemEvent: $systemEvent, senderNickname: $senderNickname, delivery: $delivery)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String roomId, ChatMessageType type, DateTime createdAt, String? senderId, String? content, String? imagePath, ChatSystemEvent? systemEvent, String? senderNickname, ChatMessageDelivery delivery
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomId = null,Object? type = null,Object? createdAt = null,Object? senderId = freezed,Object? content = freezed,Object? imagePath = freezed,Object? systemEvent = freezed,Object? senderNickname = freezed,Object? delivery = null,}) {
  return _then(ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ChatMessageType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,senderId: freezed == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,imagePath: freezed == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String?,systemEvent: freezed == systemEvent ? _self.systemEvent : systemEvent // ignore: cast_nullable_to_non_nullable
as ChatSystemEvent?,senderNickname: freezed == senderNickname ? _self.senderNickname : senderNickname // ignore: cast_nullable_to_non_nullable
as String?,delivery: null == delivery ? _self.delivery : delivery // ignore: cast_nullable_to_non_nullable
as ChatMessageDelivery,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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
