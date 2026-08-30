import 'package:injectable/injectable.dart';

import '../../../../core/id/id_generator.dart';
import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../chat_policy.dart';
import '../entity/chat_image_draft.dart';
import '../entity/chat_message.dart';
import '../entity/chat_participant.dart';
import '../entity/chat_room.dart';
import '../entity/chat_room_summary.dart';
import '../repository/chat_repository.dart';
import 'scenario/create_room_scenario.dart';
import 'scenario/join_room_scenario.dart';
import 'scenario/mark_read_scenario.dart';
import 'scenario/open_direct_room_scenario.dart';
import 'scenario/send_image_message_scenario.dart';
import 'scenario/send_message_scenario.dart';

/// chat feature 의 presentation 진입점 (규칙 ③).
abstract interface class ChatUseCase {
  Future<Result<List<ChatRoomSummary>>> getMyRooms();

  Future<Result<CursorPage<ChatRoom>>> getOpenRooms({
    int limit = ChatPolicy.roomPageSize,
    String? cursor,
    String? query,
  });

  Future<Result<ChatRoom>> createRoom({
    required String title,
    String? description,
    int memberLimit = ChatPolicy.memberLimitDefault,
  });

  Future<Result<void>> joinRoom({
    required String roomId,
    required String nickname,
  });

  Future<Result<void>> leaveRoom(String roomId);

  /// 상대와의 DM 방을 연다. 이미 있으면 그 방 id, 없으면 새로 만든다.
  Future<Result<String>> openDirectRoom(String partnerId);

  Future<Result<List<ChatParticipant>>> getParticipants(String roomId);

  Future<Result<CursorPage<ChatMessage>>> getMessages({
    required String roomId,
    int limit = ChatPolicy.messagePageSize,
    String? cursor,
  });

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

  Future<Result<bool>> deleteMessage(String messageId);

  Future<Result<void>> markRead({required String roomId, required DateTime at});

  Future<Result<String>> imageUrl(String path);

  Stream<ChatMessage> messageStream(String roomId);

  Future<void> disposeMessageStream(String roomId);

  /// 보내기 전에 메시지 id 를 만든다.
  ///
  /// 화면이 `IdGenerator` 를 직접 주입받지 않게 facade 가 대신 연다 (규칙 ③).
  /// bloc 은 이 id 로 낙관적 버블을 띄우고, 같은 id 를 [sendMessage] 에 넘겨
  /// 실시간으로 되돌아온 자기 메시지를 알아본다.
  String newMessageId();
}

@LazySingleton(as: ChatUseCase)
class DefaultChatUseCase implements ChatUseCase {
  DefaultChatUseCase(this._repository, this._ids);

  final ChatRepository _repository;
  final IdGenerator _ids;

  @override
  Future<Result<List<ChatRoomSummary>>> getMyRooms() => _repository.getMyRooms();

  @override
  Future<Result<CursorPage<ChatRoom>>> getOpenRooms({
    int limit = ChatPolicy.roomPageSize,
    String? cursor,
    String? query,
  }) => _repository.getOpenRooms(limit: limit, cursor: cursor, query: query);

  @override
  Future<Result<ChatRoom>> createRoom({
    required String title,
    String? description,
    int memberLimit = ChatPolicy.memberLimitDefault,
  }) => CreateRoomScenario(_repository)(
    title: title,
    description: description,
    memberLimit: memberLimit,
  );

  @override
  Future<Result<void>> joinRoom({
    required String roomId,
    required String nickname,
  }) => JoinRoomScenario(_repository)(roomId: roomId, nickname: nickname);

  @override
  Future<Result<void>> leaveRoom(String roomId) => _repository.leaveRoom(roomId);

  @override
  Future<Result<String>> openDirectRoom(String partnerId) =>
      OpenDirectRoomScenario(_repository)(partnerId);

  @override
  Future<Result<List<ChatParticipant>>> getParticipants(String roomId) =>
      _repository.getParticipants(roomId);

  @override
  Future<Result<CursorPage<ChatMessage>>> getMessages({
    required String roomId,
    int limit = ChatPolicy.messagePageSize,
    String? cursor,
  }) => _repository.getMessages(roomId: roomId, limit: limit, cursor: cursor);

  @override
  Future<Result<void>> sendMessage({
    required String id,
    required String roomId,
    required String content,
  }) => SendMessageScenario(
    _repository,
  )(id: id, roomId: roomId, content: content);

  @override
  Future<Result<void>> sendImageMessage({
    required String id,
    required String roomId,
    required ChatImageDraft image,
  }) => SendImageMessageScenario(
    _repository,
  )(id: id, roomId: roomId, image: image);

  @override
  Future<Result<bool>> deleteMessage(String messageId) =>
      _repository.deleteMessage(messageId);

  @override
  Future<Result<void>> markRead({
    required String roomId,
    required DateTime at,
  }) => MarkReadScenario(_repository)(roomId: roomId, at: at);

  @override
  Future<Result<String>> imageUrl(String path) => _repository.imageUrl(path);

  @override
  Stream<ChatMessage> messageStream(String roomId) =>
      _repository.messageStream(roomId);

  @override
  Future<void> disposeMessageStream(String roomId) =>
      _repository.disposeMessageStream(roomId);

  @override
  String newMessageId() => _ids.newId();
}
