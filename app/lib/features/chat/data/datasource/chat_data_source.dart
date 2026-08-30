import '../../domain/entity/chat_image_draft.dart';
import '../cursor/message_cursor.dart';
import '../cursor/room_cursor.dart';
import '../dto/chat_message_dto.dart';
import '../dto/chat_participant_dto.dart';
import '../dto/chat_room_dto.dart';
import '../dto/chat_room_summary_dto.dart';

/// 채팅 원격 데이터 접근의 계약.
///
/// 구현체(`SupabaseChatDataSource`)가 SDK 타입을 다루는 유일한 곳이다.
abstract interface class ChatDataSource {
  Future<List<ChatRoomSummaryDto>> getMyRooms();

  Future<List<ChatRoomDto>> getOpenRooms({
    required int limit,
    RoomCursor? cursor,
    String? query,
  });

  Future<ChatRoomDto> createRoom({
    required String title,
    String? description,
    required int memberLimit,
  });

  /// 첫 입장과 재입장을 한 번에 처리한다 (PK 충돌 시 upsert).
  Future<void> joinRoom({required String roomId, required String nickname});

  Future<void> leaveRoom(String roomId);

  Future<List<ChatParticipantDto>> getParticipants(String roomId);

  Future<List<ChatMessageDto>> getMessages({
    required String roomId,
    required int limit,
    MessageCursor? cursor,
  });

  Future<void> sendMessage({
    required String id,
    required String roomId,
    required String content,
  });

  Future<void> sendImageMessage({
    required String id,
    required String roomId,
    required ChatImageDraft image,
  });

  Future<bool> deleteMessage(String messageId);

  Future<void> markRead({required String roomId, required DateTime at});

  Future<String> imageUrl(String path);

  Stream<ChatMessageDto> messageStream(String roomId);

  Future<void> disposeMessageStream(String roomId);
}
