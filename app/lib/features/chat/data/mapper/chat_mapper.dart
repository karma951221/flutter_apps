import '../../domain/entity/chat_message.dart';
import '../../domain/entity/chat_participant.dart';
import '../../domain/entity/chat_room.dart';
import '../../domain/entity/chat_room_summary.dart';
import '../dto/chat_message_dto.dart';
import '../dto/chat_participant_dto.dart';
import '../dto/chat_room_dto.dart';
import '../dto/chat_room_summary_dto.dart';

/// DTO → Entity. 여기를 지나면 전송 형식(문자열 코드·snake_case)이 사라진다.
extension ChatMessageDtoMapper on ChatMessageDto {
  /// 서버에서 온 메시지는 언제나 `sent` 다. 보내는 중·실패는 화면이 만들어내는
  /// 상태라 저장소를 지나 올라오지 않는다.
  ChatMessage toEntity({String? senderNickname}) => ChatMessage(
    id: id,
    roomId: roomId,
    type: ChatMessageType.fromCode(type),
    createdAt: createdAt,
    senderId: senderId,
    content: content,
    imagePath: imagePath,
    systemEvent: ChatSystemEvent.fromCode(systemEvent),
    senderNickname: senderNickname,
  );
}

extension ChatRoomDtoMapper on ChatRoomDto {
  ChatRoom toEntity() => ChatRoom(
    id: id,
    title: title,
    createdAt: createdAt,
    description: description,
    memberCount: memberCount,
    lastMessageAt: lastMessageAt,
  );
}

extension ChatRoomSummaryDtoMapper on ChatRoomSummaryDto {
  ChatRoomSummary toEntity() => ChatRoomSummary(
    id: id,
    title: title,
    myNickname: myNickname,
    lastReadAt: lastReadAt,
    description: description,
    memberCount: memberCount,
    unreadCount: unreadCount,
    lastMessageAt: lastMessageAt,
    lastMessageType: lastMessageType == null
        ? null
        : ChatMessageType.fromCode(lastMessageType),
    lastMessageContent: lastMessageContent,
    lastMessageSystemEvent: ChatSystemEvent.fromCode(lastMessageSystemEvent),
  );
}

extension ChatParticipantDtoMapper on ChatParticipantDto {
  ChatParticipant toEntity() => ChatParticipant(
    userId: userId,
    nickname: nickname,
    joinedAt: joinedAt,
    leftAt: leftAt,
  );
}
