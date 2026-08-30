// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_room_summary_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatRoomSummaryDto {

 String get id; String? get title; String get myNickname; DateTime get lastReadAt; String get type; String? get partnerId; String? get partnerNickname; String? get partnerAvatarUrl; String? get description; int get memberCount; int get unreadCount; DateTime? get lastMessageAt; String? get lastMessageType; String? get lastMessageContent; String? get lastMessageSystemEvent;
/// Create a copy of ChatRoomSummaryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRoomSummaryDtoCopyWith<ChatRoomSummaryDto> get copyWith => _$ChatRoomSummaryDtoCopyWithImpl<ChatRoomSummaryDto>(this as ChatRoomSummaryDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomSummaryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.myNickname, myNickname) || other.myNickname == myNickname)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt)&&(identical(other.type, type) || other.type == type)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.partnerNickname, partnerNickname) || other.partnerNickname == partnerNickname)&&(identical(other.partnerAvatarUrl, partnerAvatarUrl) || other.partnerAvatarUrl == partnerAvatarUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.lastMessageType, lastMessageType) || other.lastMessageType == lastMessageType)&&(identical(other.lastMessageContent, lastMessageContent) || other.lastMessageContent == lastMessageContent)&&(identical(other.lastMessageSystemEvent, lastMessageSystemEvent) || other.lastMessageSystemEvent == lastMessageSystemEvent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,myNickname,lastReadAt,type,partnerId,partnerNickname,partnerAvatarUrl,description,memberCount,unreadCount,lastMessageAt,lastMessageType,lastMessageContent,lastMessageSystemEvent);

@override
String toString() {
  return 'ChatRoomSummaryDto(id: $id, title: $title, myNickname: $myNickname, lastReadAt: $lastReadAt, type: $type, partnerId: $partnerId, partnerNickname: $partnerNickname, partnerAvatarUrl: $partnerAvatarUrl, description: $description, memberCount: $memberCount, unreadCount: $unreadCount, lastMessageAt: $lastMessageAt, lastMessageType: $lastMessageType, lastMessageContent: $lastMessageContent, lastMessageSystemEvent: $lastMessageSystemEvent)';
}


}

/// @nodoc
abstract mixin class $ChatRoomSummaryDtoCopyWith<$Res>  {
  factory $ChatRoomSummaryDtoCopyWith(ChatRoomSummaryDto value, $Res Function(ChatRoomSummaryDto) _then) = _$ChatRoomSummaryDtoCopyWithImpl;
@useResult
$Res call({
 String id, String myNickname, DateTime lastReadAt, String? title, String type, String? partnerId, String? partnerNickname, String? partnerAvatarUrl, String? description, int memberCount, int unreadCount, DateTime? lastMessageAt, String? lastMessageType, String? lastMessageContent, String? lastMessageSystemEvent
});




}
/// @nodoc
class _$ChatRoomSummaryDtoCopyWithImpl<$Res>
    implements $ChatRoomSummaryDtoCopyWith<$Res> {
  _$ChatRoomSummaryDtoCopyWithImpl(this._self, this._then);

  final ChatRoomSummaryDto _self;
  final $Res Function(ChatRoomSummaryDto) _then;

/// Create a copy of ChatRoomSummaryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? myNickname = null,Object? lastReadAt = null,Object? title = freezed,Object? type = null,Object? partnerId = freezed,Object? partnerNickname = freezed,Object? partnerAvatarUrl = freezed,Object? description = freezed,Object? memberCount = null,Object? unreadCount = null,Object? lastMessageAt = freezed,Object? lastMessageType = freezed,Object? lastMessageContent = freezed,Object? lastMessageSystemEvent = freezed,}) {
  return _then(ChatRoomSummaryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,myNickname: null == myNickname ? _self.myNickname : myNickname // ignore: cast_nullable_to_non_nullable
as String,lastReadAt: null == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,partnerId: freezed == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String?,partnerNickname: freezed == partnerNickname ? _self.partnerNickname : partnerNickname // ignore: cast_nullable_to_non_nullable
as String?,partnerAvatarUrl: freezed == partnerAvatarUrl ? _self.partnerAvatarUrl : partnerAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastMessageType: freezed == lastMessageType ? _self.lastMessageType : lastMessageType // ignore: cast_nullable_to_non_nullable
as String?,lastMessageContent: freezed == lastMessageContent ? _self.lastMessageContent : lastMessageContent // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSystemEvent: freezed == lastMessageSystemEvent ? _self.lastMessageSystemEvent : lastMessageSystemEvent // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatRoomSummaryDto].
extension ChatRoomSummaryDtoPatterns on ChatRoomSummaryDto {
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
