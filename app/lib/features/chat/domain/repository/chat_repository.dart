import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../entity/chat_image_draft.dart';
import '../entity/chat_message.dart';
import '../entity/chat_participant.dart';
import '../entity/chat_room.dart';
import '../entity/chat_room_summary.dart';

/// 채팅 저장소의 계약.
///
/// 실시간이 이 인터페이스에 드러나는 것은 [messageStream] 하나뿐이다.
/// `RealtimeChannel` · `PostgresChangePayload` 같은 SDK 타입은 datasource 밖으로
/// 나가지 않으므로(규칙 ①), 전달 방식을 Broadcast 로 바꾸더라도 datasource 한
/// 파일만 갈아끼우면 된다 (계획서 "실시간 교체 여지").
abstract interface class ChatRepository {
  /// 내가 참여 중인 방 목록.
  Future<Result<List<ChatRoomSummary>>> getMyRooms();

  /// 탐색용 공개방 목록. [query] 가 있으면 제목으로 좁힌다.
  Future<Result<CursorPage<ChatRoom>>> getOpenRooms({
    required int limit,
    String? cursor,
    String? query,
  });

  Future<Result<ChatRoom>> createRoom({
    required String title,
    String? description,
    required int memberLimit,
  });

  /// 방에 들어간다. 나갔던 방이면 재입장이다 — 앱은 둘을 구분하지 않는다.
  Future<Result<void>> joinRoom({
    required String roomId,
    required String nickname,
  });

  Future<Result<void>> leaveRoom(String roomId);

  /// 나간 사람까지 포함해서 돌려준다. 방에 남은 메시지에 이름을 붙여야 한다.
  Future<Result<List<ChatParticipant>>> getParticipants(String roomId);

  /// 최신부터 읽는다. 화면이 뒤집어서 그린다.
  Future<Result<CursorPage<ChatMessage>>> getMessages({
    required String roomId,
    required int limit,
    String? cursor,
  });

  /// [id] 를 앱이 만들어 넘긴다. 낙관적 버블과 실시간으로 되돌아온 내 메시지를
  /// 같은 id 로 이어 붙이기 위해서다.
  Future<Result<void>> sendMessage({
    required String id,
    required String roomId,
    required String content,
  });

  Future<Result<void>> sendImageMessage({
    required String id,
    required String roomId,
    required ChatImageDraft image,
  });

  /// 본인 메시지를 소프트 삭제한다. 지운 것이 없으면 `false`.
  Future<Result<bool>> deleteMessage(String messageId);

  Future<Result<void>> markRead({required String roomId, required DateTime at});

  /// 비공개 버킷의 사진을 볼 수 있는 한시적 URL.
  Future<Result<String>> imageUrl(String path);

  /// 이 방에 새로 들어오는 메시지.
  ///
  /// 구독은 호출한 쪽이 [disposeMessageStream] 으로 닫는다.
  Stream<ChatMessage> messageStream(String roomId);

  Future<void> disposeMessageStream(String roomId);
}
