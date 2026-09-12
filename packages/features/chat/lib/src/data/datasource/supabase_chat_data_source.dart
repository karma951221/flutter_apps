import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:core/core.dart';
import '../../domain/entity/chat_image_draft.dart';
import '../cursor/message_cursor.dart';
import '../cursor/room_cursor.dart';
import '../dto/chat_message_dto.dart';
import '../dto/chat_participant_dto.dart';
import '../dto/chat_room_dto.dart';
import '../dto/chat_room_summary_dto.dart';
import 'chat_data_source.dart';

/// 채팅의 Supabase 구현.
///
/// `RealtimeChannel` 과 `PostgresChangePayload` 가 사는 유일한 곳이다 (규칙 ①).
/// 바깥으로 나가는 것은 `Stream<ChatMessageDto>` 뿐이라, 전달 방식을
/// Broadcast 로 바꾸더라도 이 파일만 갈아끼우면 된다.
@LazySingleton(as: ChatDataSource)
class SupabaseChatDataSource implements ChatDataSource {
  SupabaseChatDataSource(this._client, this._images);

  final SupabaseClient _client;
  final ImageStorage _images;

  static const _bucket = 'chat-images';

  static const _messageColumns =
      'id, room_id, sender_id, type, content, image_path, system_event, '
      'created_at, deleted_at';

  /// 방마다 채널 하나. 화면이 닫힐 때 [disposeMessageStream] 이 걷어낸다.
  final _channels = <String, RealtimeChannel>{};
  final _controllers = <String, StreamController<ChatMessageDto>>{};

  // ------------------------------------------------------------------ 방 목록

  @override
  Future<List<ChatRoomSummaryDto>> getMyRooms() async {
    final rows = await _client
        .from('my_chat_rooms')
        .select()
        // 대화가 없는 새 방은 last_message_at 이 null 이다. 목록 맨 아래로
        // 밀지 않고 개설 시각으로 자리를 잡아준다.
        .order('last_message_at', ascending: false, nullsFirst: false)
        .order('created_at', ascending: false);

    return rows.map(ChatRoomSummaryDto.fromJson).toList();
  }

  @override
  Future<List<ChatRoomDto>> getOpenRooms({
    required int limit,
    RoomCursor? cursor,
    String? query,
  }) async {
    var request = _client.from('open_chat_rooms').select();

    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      // 사용자가 친 `%` · `_` 는 리터럴이다. 이스케이프하지 않으면 방 이름에
      // 그 글자를 넣은 검색이 전부 뒤죽박죽이 된다 (core/data/like_pattern.dart).
      request = request.ilike('title', '%${LikePattern.escape(trimmed)}%');
    }
    if (cursor != null) {
      final createdAt = cursor.createdAt.toUtc().toIso8601String();
      request = request.or(
        'created_at.lt.$createdAt,'
        'and(created_at.eq.$createdAt,id.lt.${cursor.id})',
      );
    }

    final rows = await request
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    return rows.map(ChatRoomDto.fromJson).toList();
  }

  @override
  Future<ChatRoomDto> createRoom({
    required String title,
    String? description,
    required int memberLimit,
  }) async {
    // created_by 는 보내지 않는다. DB 의 default auth.uid() 가 채우고,
    // INSERT GRANT 에서 빠져 있어 위조할 수도 없다.
    final row = await _client
        .from('chat_rooms')
        .insert({
          'type': 'open',
          'title': title,
          'description': description,
          'member_limit': memberLimit,
        })
        .select('id, title, description, created_at')
        .single();

    // 방금 만든 방이라 참여자도 메시지도 없다. 탐색 뷰를 다시 읽지 않고
    // 삽입 결과로 엔티티를 만든다.
    return ChatRoomDto.fromJson({...row, 'member_count': 0});
  }

  // ------------------------------------------------------------------ 참여

  @override
  Future<void> joinRoom({
    required String roomId,
    required String nickname,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        failureCode: FailureCode.authenticationRequired,
      );
    }

    // upsert 를 쓰지 않는다. PostgREST 의 upsert 는 보내는 **모든 컬럼**에
    // INSERT 와 UPDATE 권한을 요구하는데, 그러려면 `room_id` 에 UPDATE 를
    // 줘야 한다 — 그 순간 자기 참여자 행의 room_id 를 고쳐 들어간 적 없는
    // 방으로 옮길 수 있고, 삽입 정책의 "살아 있는 공개방인가" 검사가 통째로
    // 건너뛰어진다.
    //
    // 참여자 조회 정책에 `user_id = auth.uid()` 가 or 로 붙어 있는 것이
    // 이걸 위해서다 — 나간 뒤에도 자기 행은 읽히므로 첫 입장과 재입장을
    // 앱이 구분할 수 있다 (계획서 · 스키마 §14).
    final existing = await _client
        .from('chat_participants')
        .select('user_id')
        .eq('room_id', roomId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      // user_id 는 보내지 않는다 — default auth.uid() 가 채운다.
      await _client.from('chat_participants').insert({
        'room_id': roomId,
        'nickname': nickname,
      });
      return;
    }

    // 재입장. left_at 을 null 로 되돌리는 것이 곧 재입장이고, 트리거가
    // 그 전이를 보고 join 시스템 메시지를 남긴다.
    await _client
        .from('chat_participants')
        .update({'nickname': nickname, 'left_at': null})
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        failureCode: FailureCode.authenticationRequired,
      );
    }
    await _client
        .from('chat_participants')
        .update({'left_at': DateTime.now().toUtc().toIso8601String()})
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  @override
  Future<String> openDirectRoom(String partnerId) async {
    final roomId = await _client.rpc<dynamic>(
      'open_direct_room',
      params: {'partner_id': partnerId},
    );
    return roomId as String;
  }

  @override
  Future<List<ChatParticipantDto>> getParticipants(String roomId) async {
    // 나간 사람도 가져온다. 방에 남은 그 사람의 메시지에 이름을 붙여야 한다.
    final rows = await _client
        .from('chat_participants')
        .select('user_id, nickname, joined_at, left_at')
        .eq('room_id', roomId)
        .order('joined_at', ascending: true);

    return rows.map(ChatParticipantDto.fromJson).toList();
  }

  @override
  Future<void> markRead({required String roomId, required DateTime at}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('chat_participants')
        .update({'last_read_at': at.toUtc().toIso8601String()})
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  // ------------------------------------------------------------------ 메시지

  @override
  Future<List<ChatMessageDto>> getMessages({
    required String roomId,
    required int limit,
    MessageCursor? cursor,
  }) async {
    var request = _client
        .from('chat_messages')
        .select(_messageColumns)
        .eq('room_id', roomId);

    if (cursor != null) {
      final createdAt = cursor.createdAt.toUtc().toIso8601String();
      request = request.or(
        'created_at.lt.$createdAt,'
        'and(created_at.eq.$createdAt,id.lt.${cursor.id})',
      );
    }

    final rows = await request
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    return rows.map(ChatMessageDto.fromJson).toList();
  }

  @override
  Future<void> sendMessage({
    required String id,
    required String roomId,
    required String content,
  }) async {
    // id 를 앱이 보낸다. 낙관적 버블과 실시간으로 되돌아온 행을 잇는 열쇠다.
    // sender_id 는 default auth.uid() 가 채운다.
    await _client.from('chat_messages').insert({
      'id': id,
      'room_id': roomId,
      'type': 'text',
      'content': content,
    });
  }

  @override
  Future<void> sendImageMessage({
    required String id,
    required String roomId,
    required ChatImageDraft image,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const Failure.auth(
        message: '로그인이 필요합니다',
        failureCode: FailureCode.authenticationRequired,
      );
    }

    // 경로의 첫 조각이 room_id 다. 읽기 권한이 방 단위라 Storage 정책이
    // is_room_member 로 판정하려면 이 순서여야 한다.
    final path = '$roomId/$userId/$id.${image.extension}';
    await _images.uploadToPath(
      bucket: _bucket,
      path: path,
      bytes: image.bytes,
      contentType: image.contentType,
    );

    try {
      await _client.from('chat_messages').insert({
        'id': id,
        'room_id': roomId,
        'type': 'image',
        'image_path': path,
      });
    } catch (_) {
      // 행이 만들어지지 않았으면 올린 객체는 아무 데서도 참조되지 않는다.
      // 게시물 이미지와 같은 best-effort 정리다.
      await _images.removePaths(bucket: _bucket, paths: [path]);
      rethrow;
    }
  }

  @override
  Future<bool> deleteMessage(String messageId) async {
    // 조회 정책이 삭제된 행을 가려 UPDATE ... RETURNING 이 막힌다. 함수로만 지운다.
    final deleted = await _client.rpc<dynamic>(
      'soft_delete_chat_message',
      params: {'message_id': messageId},
    );
    return deleted == true;
  }

  @override
  Future<String> imageUrl(String path) =>
      _images.signedUrl(bucket: _bucket, path: path);

  // ------------------------------------------------------------------ 실시간

  @override
  Stream<ChatMessageDto> messageStream(String roomId) {
    final existing = _controllers[roomId];
    if (existing != null) return existing.stream;

    // broadcast 컨트롤러다 — 방 화면이 다시 붙어도 같은 채널을 나눠 쓴다.
    final controller = StreamController<ChatMessageDto>.broadcast();
    _controllers[roomId] = controller;

    final channel = _client
        .channel('chat-room-$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            if (controller.isClosed) return;
            try {
              controller.add(ChatMessageDto.fromJson(payload.newRecord));
            } catch (error, stackTrace) {
              // 한 건이 어긋난다고 구독을 끊지 않는다. 방 화면이 통째로
              // 죽는 것보다 그 메시지만 빠지는 편이 낫다.
              controller.addError(error, stackTrace);
            }
          },
        );

    // 구독자별 RLS 재검사는 서버가 한다 — 차단한 상대의 메시지와 비참여자의
    // 구독은 여기까지 오지 않는다 (supabase/tests/chat_realtime_check.py 로 확인).
    channel.subscribe();
    _channels[roomId] = channel;

    return controller.stream;
  }

  @override
  Future<void> disposeMessageStream(String roomId) async {
    final channel = _channels.remove(roomId);
    if (channel != null) await _client.removeChannel(channel);
    await _controllers.remove(roomId)?.close();
  }
}
