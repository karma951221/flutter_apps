import 'package:injectable/injectable.dart';

import '../../../../core/data/repository/repository_error_handler.dart';
import '../../../../core/pagination/cursor_page.dart';
import '../../../../core/result/result.dart';
import '../../domain/entity/chat_image_draft.dart';
import '../../domain/entity/chat_message.dart';
import '../../domain/entity/chat_participant.dart';
import '../../domain/entity/chat_room.dart';
import '../../domain/entity/chat_room_summary.dart';
import '../../domain/repository/chat_repository.dart';
import '../cursor/message_cursor.dart';
import '../cursor/room_cursor.dart';
import '../datasource/chat_data_source.dart';
import '../mapper/chat_mapper.dart';

/// ChatDataSource 를 domain 계약으로 옮기는 구현체.
@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl with RepositoryErrorHandler implements ChatRepository {
  ChatRepositoryImpl(this._dataSource);

  final ChatDataSource _dataSource;

  @override
  Future<Result<List<ChatRoomSummary>>> getMyRooms() => guard(() async {
    final rows = await _dataSource.getMyRooms();
    return rows.map((dto) => dto.toEntity()).toList();
  });

  @override
  Future<Result<CursorPage<ChatRoom>>> getOpenRooms({
    required int limit,
    String? cursor,
    String? query,
  }) => guard(() async {
    // limit + 1 을 요청해 다음 페이지가 있는지 본다. COUNT 질의가 필요 없다.
    final rows = await _dataSource.getOpenRooms(
      limit: limit + 1,
      cursor: RoomCursor.decode(cursor),
      query: query,
    );

    final hasMore = rows.length > limit;
    final page = hasMore ? rows.sublist(0, limit) : rows;
    // 다음 커서는 **잘라낸 뒤 실제로 돌려주는 마지막 항목**으로 만든다.
    // 잘라낸 항목으로 만들면 한 건이 건너뛰어진다 (아키텍처 §3-1).
    final last = page.isEmpty ? null : page.last;

    return CursorPage(
      items: page.map((dto) => dto.toEntity()).toList(),
      nextCursor: hasMore && last != null
          ? RoomCursor(createdAt: last.createdAt, id: last.id).encode()
          : null,
    );
  });

  @override
  Future<Result<ChatRoom>> createRoom({
    required String title,
    String? description,
    required int memberLimit,
  }) => guard(() async {
    final dto = await _dataSource.createRoom(
      title: title,
      description: description,
      memberLimit: memberLimit,
    );
    return dto.toEntity();
  });

  @override
  Future<Result<void>> joinRoom({
    required String roomId,
    required String nickname,
  }) => guard(() => _dataSource.joinRoom(roomId: roomId, nickname: nickname));

  @override
  Future<Result<void>> leaveRoom(String roomId) =>
      guard(() => _dataSource.leaveRoom(roomId));

  @override
  Future<Result<String>> openDirectRoom(String partnerId) =>
      guard(() => _dataSource.openDirectRoom(partnerId));

  @override
  Future<Result<List<ChatParticipant>>> getParticipants(String roomId) =>
      guard(() async {
        final rows = await _dataSource.getParticipants(roomId);
        return rows.map((dto) => dto.toEntity()).toList();
      });

  @override
  Future<Result<CursorPage<ChatMessage>>> getMessages({
    required String roomId,
    required int limit,
    String? cursor,
  }) => guard(() async {
    final rows = await _dataSource.getMessages(
      roomId: roomId,
      limit: limit + 1,
      cursor: MessageCursor.decode(cursor),
    );

    final hasMore = rows.length > limit;
    final page = hasMore ? rows.sublist(0, limit) : rows;
    final last = page.isEmpty ? null : page.last;

    return CursorPage(
      items: page.map((dto) => dto.toEntity()).toList(),
      nextCursor: hasMore && last != null
          ? MessageCursor(createdAt: last.createdAt, id: last.id).encode()
          : null,
    );
  });

  @override
  Future<Result<void>> sendMessage({
    required String id,
    required String roomId,
    required String content,
  }) => guard(
    () => _dataSource.sendMessage(id: id, roomId: roomId, content: content),
  );

  @override
  Future<Result<void>> sendImageMessage({
    required String id,
    required String roomId,
    required ChatImageDraft image,
  }) => guard(
    () => _dataSource.sendImageMessage(id: id, roomId: roomId, image: image),
  );

  @override
  Future<Result<bool>> deleteMessage(String messageId) =>
      guard(() => _dataSource.deleteMessage(messageId));

  @override
  Future<Result<void>> markRead({
    required String roomId,
    required DateTime at,
  }) => guard(() => _dataSource.markRead(roomId: roomId, at: at));

  @override
  Future<Result<String>> imageUrl(String path) =>
      guard(() => _dataSource.imageUrl(path));

  @override
  Stream<ChatMessage> messageStream(String roomId) => _dataSource
      .messageStream(roomId)
      .map((dto) => dto.toEntity());

  @override
  Future<void> disposeMessageStream(String roomId) =>
      _dataSource.disposeMessageStream(roomId);
}
