// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_room_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatRoomEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatRoomEvent()';
}


}

/// @nodoc
class $ChatRoomEventCopyWith<$Res>  {
$ChatRoomEventCopyWith(ChatRoomEvent _, $Res Function(ChatRoomEvent) __);
}


/// Adds pattern-matching-related methods to [ChatRoomEvent].
extension ChatRoomEventPatterns on ChatRoomEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatRoomStarted value)?  started,TResult Function( ChatRoomMessageReceived value)?  messageReceived,TResult Function( ChatRoomSendRequested value)?  sendRequested,TResult Function( ChatRoomImageSendRequested value)?  imageSendRequested,TResult Function( ChatRoomRetryRequested value)?  retryRequested,TResult Function( ChatRoomMoreRequested value)?  moreRequested,TResult Function( ChatRoomDeleteRequested value)?  deleteRequested,TResult Function( ChatRoomParticipantsRefreshed value)?  participantsRefreshed,TResult Function( ChatRoomReadConfirmed value)?  readConfirmed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatRoomStarted() when started != null:
return started(_that);case ChatRoomMessageReceived() when messageReceived != null:
return messageReceived(_that);case ChatRoomSendRequested() when sendRequested != null:
return sendRequested(_that);case ChatRoomImageSendRequested() when imageSendRequested != null:
return imageSendRequested(_that);case ChatRoomRetryRequested() when retryRequested != null:
return retryRequested(_that);case ChatRoomMoreRequested() when moreRequested != null:
return moreRequested(_that);case ChatRoomDeleteRequested() when deleteRequested != null:
return deleteRequested(_that);case ChatRoomParticipantsRefreshed() when participantsRefreshed != null:
return participantsRefreshed(_that);case ChatRoomReadConfirmed() when readConfirmed != null:
return readConfirmed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatRoomStarted value)  started,required TResult Function( ChatRoomMessageReceived value)  messageReceived,required TResult Function( ChatRoomSendRequested value)  sendRequested,required TResult Function( ChatRoomImageSendRequested value)  imageSendRequested,required TResult Function( ChatRoomRetryRequested value)  retryRequested,required TResult Function( ChatRoomMoreRequested value)  moreRequested,required TResult Function( ChatRoomDeleteRequested value)  deleteRequested,required TResult Function( ChatRoomParticipantsRefreshed value)  participantsRefreshed,required TResult Function( ChatRoomReadConfirmed value)  readConfirmed,}){
final _that = this;
switch (_that) {
case ChatRoomStarted():
return started(_that);case ChatRoomMessageReceived():
return messageReceived(_that);case ChatRoomSendRequested():
return sendRequested(_that);case ChatRoomImageSendRequested():
return imageSendRequested(_that);case ChatRoomRetryRequested():
return retryRequested(_that);case ChatRoomMoreRequested():
return moreRequested(_that);case ChatRoomDeleteRequested():
return deleteRequested(_that);case ChatRoomParticipantsRefreshed():
return participantsRefreshed(_that);case ChatRoomReadConfirmed():
return readConfirmed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatRoomStarted value)?  started,TResult? Function( ChatRoomMessageReceived value)?  messageReceived,TResult? Function( ChatRoomSendRequested value)?  sendRequested,TResult? Function( ChatRoomImageSendRequested value)?  imageSendRequested,TResult? Function( ChatRoomRetryRequested value)?  retryRequested,TResult? Function( ChatRoomMoreRequested value)?  moreRequested,TResult? Function( ChatRoomDeleteRequested value)?  deleteRequested,TResult? Function( ChatRoomParticipantsRefreshed value)?  participantsRefreshed,TResult? Function( ChatRoomReadConfirmed value)?  readConfirmed,}){
final _that = this;
switch (_that) {
case ChatRoomStarted() when started != null:
return started(_that);case ChatRoomMessageReceived() when messageReceived != null:
return messageReceived(_that);case ChatRoomSendRequested() when sendRequested != null:
return sendRequested(_that);case ChatRoomImageSendRequested() when imageSendRequested != null:
return imageSendRequested(_that);case ChatRoomRetryRequested() when retryRequested != null:
return retryRequested(_that);case ChatRoomMoreRequested() when moreRequested != null:
return moreRequested(_that);case ChatRoomDeleteRequested() when deleteRequested != null:
return deleteRequested(_that);case ChatRoomParticipantsRefreshed() when participantsRefreshed != null:
return participantsRefreshed(_that);case ChatRoomReadConfirmed() when readConfirmed != null:
return readConfirmed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String roomId)?  started,TResult Function( ChatMessage message)?  messageReceived,TResult Function( String text)?  sendRequested,TResult Function( ChatImageDraft image)?  imageSendRequested,TResult Function( String messageId)?  retryRequested,TResult Function()?  moreRequested,TResult Function( String messageId)?  deleteRequested,TResult Function()?  participantsRefreshed,TResult Function()?  readConfirmed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatRoomStarted() when started != null:
return started(_that.roomId);case ChatRoomMessageReceived() when messageReceived != null:
return messageReceived(_that.message);case ChatRoomSendRequested() when sendRequested != null:
return sendRequested(_that.text);case ChatRoomImageSendRequested() when imageSendRequested != null:
return imageSendRequested(_that.image);case ChatRoomRetryRequested() when retryRequested != null:
return retryRequested(_that.messageId);case ChatRoomMoreRequested() when moreRequested != null:
return moreRequested();case ChatRoomDeleteRequested() when deleteRequested != null:
return deleteRequested(_that.messageId);case ChatRoomParticipantsRefreshed() when participantsRefreshed != null:
return participantsRefreshed();case ChatRoomReadConfirmed() when readConfirmed != null:
return readConfirmed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String roomId)  started,required TResult Function( ChatMessage message)  messageReceived,required TResult Function( String text)  sendRequested,required TResult Function( ChatImageDraft image)  imageSendRequested,required TResult Function( String messageId)  retryRequested,required TResult Function()  moreRequested,required TResult Function( String messageId)  deleteRequested,required TResult Function()  participantsRefreshed,required TResult Function()  readConfirmed,}) {final _that = this;
switch (_that) {
case ChatRoomStarted():
return started(_that.roomId);case ChatRoomMessageReceived():
return messageReceived(_that.message);case ChatRoomSendRequested():
return sendRequested(_that.text);case ChatRoomImageSendRequested():
return imageSendRequested(_that.image);case ChatRoomRetryRequested():
return retryRequested(_that.messageId);case ChatRoomMoreRequested():
return moreRequested();case ChatRoomDeleteRequested():
return deleteRequested(_that.messageId);case ChatRoomParticipantsRefreshed():
return participantsRefreshed();case ChatRoomReadConfirmed():
return readConfirmed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String roomId)?  started,TResult? Function( ChatMessage message)?  messageReceived,TResult? Function( String text)?  sendRequested,TResult? Function( ChatImageDraft image)?  imageSendRequested,TResult? Function( String messageId)?  retryRequested,TResult? Function()?  moreRequested,TResult? Function( String messageId)?  deleteRequested,TResult? Function()?  participantsRefreshed,TResult? Function()?  readConfirmed,}) {final _that = this;
switch (_that) {
case ChatRoomStarted() when started != null:
return started(_that.roomId);case ChatRoomMessageReceived() when messageReceived != null:
return messageReceived(_that.message);case ChatRoomSendRequested() when sendRequested != null:
return sendRequested(_that.text);case ChatRoomImageSendRequested() when imageSendRequested != null:
return imageSendRequested(_that.image);case ChatRoomRetryRequested() when retryRequested != null:
return retryRequested(_that.messageId);case ChatRoomMoreRequested() when moreRequested != null:
return moreRequested();case ChatRoomDeleteRequested() when deleteRequested != null:
return deleteRequested(_that.messageId);case ChatRoomParticipantsRefreshed() when participantsRefreshed != null:
return participantsRefreshed();case ChatRoomReadConfirmed() when readConfirmed != null:
return readConfirmed();case _:
  return null;

}
}

}

/// @nodoc


class ChatRoomStarted implements ChatRoomEvent {
  const ChatRoomStarted(this.roomId);
  

 final  String roomId;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRoomStartedCopyWith<ChatRoomStarted> get copyWith => _$ChatRoomStartedCopyWithImpl<ChatRoomStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomStarted&&(identical(other.roomId, roomId) || other.roomId == roomId));
}


@override
int get hashCode => Object.hash(runtimeType,roomId);

@override
String toString() {
  return 'ChatRoomEvent.started(roomId: $roomId)';
}


}

/// @nodoc
abstract mixin class $ChatRoomStartedCopyWith<$Res> implements $ChatRoomEventCopyWith<$Res> {
  factory $ChatRoomStartedCopyWith(ChatRoomStarted value, $Res Function(ChatRoomStarted) _then) = _$ChatRoomStartedCopyWithImpl;
@useResult
$Res call({
 String roomId
});




}
/// @nodoc
class _$ChatRoomStartedCopyWithImpl<$Res>
    implements $ChatRoomStartedCopyWith<$Res> {
  _$ChatRoomStartedCopyWithImpl(this._self, this._then);

  final ChatRoomStarted _self;
  final $Res Function(ChatRoomStarted) _then;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? roomId = null,}) {
  return _then(ChatRoomStarted(
null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatRoomMessageReceived implements ChatRoomEvent {
  const ChatRoomMessageReceived(this.message);
  

 final  ChatMessage message;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRoomMessageReceivedCopyWith<ChatRoomMessageReceived> get copyWith => _$ChatRoomMessageReceivedCopyWithImpl<ChatRoomMessageReceived>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomMessageReceived&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ChatRoomEvent.messageReceived(message: $message)';
}


}

/// @nodoc
abstract mixin class $ChatRoomMessageReceivedCopyWith<$Res> implements $ChatRoomEventCopyWith<$Res> {
  factory $ChatRoomMessageReceivedCopyWith(ChatRoomMessageReceived value, $Res Function(ChatRoomMessageReceived) _then) = _$ChatRoomMessageReceivedCopyWithImpl;
@useResult
$Res call({
 ChatMessage message
});


$ChatMessageCopyWith<$Res> get message;

}
/// @nodoc
class _$ChatRoomMessageReceivedCopyWithImpl<$Res>
    implements $ChatRoomMessageReceivedCopyWith<$Res> {
  _$ChatRoomMessageReceivedCopyWithImpl(this._self, this._then);

  final ChatRoomMessageReceived _self;
  final $Res Function(ChatRoomMessageReceived) _then;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ChatRoomMessageReceived(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessage,
  ));
}

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<$Res> get message {
  
  return $ChatMessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}

/// @nodoc


class ChatRoomSendRequested implements ChatRoomEvent {
  const ChatRoomSendRequested(this.text);
  

 final  String text;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRoomSendRequestedCopyWith<ChatRoomSendRequested> get copyWith => _$ChatRoomSendRequestedCopyWithImpl<ChatRoomSendRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomSendRequested&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'ChatRoomEvent.sendRequested(text: $text)';
}


}

/// @nodoc
abstract mixin class $ChatRoomSendRequestedCopyWith<$Res> implements $ChatRoomEventCopyWith<$Res> {
  factory $ChatRoomSendRequestedCopyWith(ChatRoomSendRequested value, $Res Function(ChatRoomSendRequested) _then) = _$ChatRoomSendRequestedCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$ChatRoomSendRequestedCopyWithImpl<$Res>
    implements $ChatRoomSendRequestedCopyWith<$Res> {
  _$ChatRoomSendRequestedCopyWithImpl(this._self, this._then);

  final ChatRoomSendRequested _self;
  final $Res Function(ChatRoomSendRequested) _then;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(ChatRoomSendRequested(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatRoomImageSendRequested implements ChatRoomEvent {
  const ChatRoomImageSendRequested(this.image);
  

 final  ChatImageDraft image;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRoomImageSendRequestedCopyWith<ChatRoomImageSendRequested> get copyWith => _$ChatRoomImageSendRequestedCopyWithImpl<ChatRoomImageSendRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomImageSendRequested&&(identical(other.image, image) || other.image == image));
}


@override
int get hashCode => Object.hash(runtimeType,image);

@override
String toString() {
  return 'ChatRoomEvent.imageSendRequested(image: $image)';
}


}

/// @nodoc
abstract mixin class $ChatRoomImageSendRequestedCopyWith<$Res> implements $ChatRoomEventCopyWith<$Res> {
  factory $ChatRoomImageSendRequestedCopyWith(ChatRoomImageSendRequested value, $Res Function(ChatRoomImageSendRequested) _then) = _$ChatRoomImageSendRequestedCopyWithImpl;
@useResult
$Res call({
 ChatImageDraft image
});




}
/// @nodoc
class _$ChatRoomImageSendRequestedCopyWithImpl<$Res>
    implements $ChatRoomImageSendRequestedCopyWith<$Res> {
  _$ChatRoomImageSendRequestedCopyWithImpl(this._self, this._then);

  final ChatRoomImageSendRequested _self;
  final $Res Function(ChatRoomImageSendRequested) _then;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? image = null,}) {
  return _then(ChatRoomImageSendRequested(
null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ChatImageDraft,
  ));
}


}

/// @nodoc


class ChatRoomRetryRequested implements ChatRoomEvent {
  const ChatRoomRetryRequested(this.messageId);
  

 final  String messageId;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRoomRetryRequestedCopyWith<ChatRoomRetryRequested> get copyWith => _$ChatRoomRetryRequestedCopyWithImpl<ChatRoomRetryRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomRetryRequested&&(identical(other.messageId, messageId) || other.messageId == messageId));
}


@override
int get hashCode => Object.hash(runtimeType,messageId);

@override
String toString() {
  return 'ChatRoomEvent.retryRequested(messageId: $messageId)';
}


}

/// @nodoc
abstract mixin class $ChatRoomRetryRequestedCopyWith<$Res> implements $ChatRoomEventCopyWith<$Res> {
  factory $ChatRoomRetryRequestedCopyWith(ChatRoomRetryRequested value, $Res Function(ChatRoomRetryRequested) _then) = _$ChatRoomRetryRequestedCopyWithImpl;
@useResult
$Res call({
 String messageId
});




}
/// @nodoc
class _$ChatRoomRetryRequestedCopyWithImpl<$Res>
    implements $ChatRoomRetryRequestedCopyWith<$Res> {
  _$ChatRoomRetryRequestedCopyWithImpl(this._self, this._then);

  final ChatRoomRetryRequested _self;
  final $Res Function(ChatRoomRetryRequested) _then;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? messageId = null,}) {
  return _then(ChatRoomRetryRequested(
null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatRoomMoreRequested implements ChatRoomEvent {
  const ChatRoomMoreRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomMoreRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatRoomEvent.moreRequested()';
}


}




/// @nodoc


class ChatRoomDeleteRequested implements ChatRoomEvent {
  const ChatRoomDeleteRequested(this.messageId);
  

 final  String messageId;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRoomDeleteRequestedCopyWith<ChatRoomDeleteRequested> get copyWith => _$ChatRoomDeleteRequestedCopyWithImpl<ChatRoomDeleteRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomDeleteRequested&&(identical(other.messageId, messageId) || other.messageId == messageId));
}


@override
int get hashCode => Object.hash(runtimeType,messageId);

@override
String toString() {
  return 'ChatRoomEvent.deleteRequested(messageId: $messageId)';
}


}

/// @nodoc
abstract mixin class $ChatRoomDeleteRequestedCopyWith<$Res> implements $ChatRoomEventCopyWith<$Res> {
  factory $ChatRoomDeleteRequestedCopyWith(ChatRoomDeleteRequested value, $Res Function(ChatRoomDeleteRequested) _then) = _$ChatRoomDeleteRequestedCopyWithImpl;
@useResult
$Res call({
 String messageId
});




}
/// @nodoc
class _$ChatRoomDeleteRequestedCopyWithImpl<$Res>
    implements $ChatRoomDeleteRequestedCopyWith<$Res> {
  _$ChatRoomDeleteRequestedCopyWithImpl(this._self, this._then);

  final ChatRoomDeleteRequested _self;
  final $Res Function(ChatRoomDeleteRequested) _then;

/// Create a copy of ChatRoomEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? messageId = null,}) {
  return _then(ChatRoomDeleteRequested(
null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatRoomParticipantsRefreshed implements ChatRoomEvent {
  const ChatRoomParticipantsRefreshed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomParticipantsRefreshed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatRoomEvent.participantsRefreshed()';
}


}




/// @nodoc


class ChatRoomReadConfirmed implements ChatRoomEvent {
  const ChatRoomReadConfirmed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomReadConfirmed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatRoomEvent.readConfirmed()';
}


}




// dart format on
