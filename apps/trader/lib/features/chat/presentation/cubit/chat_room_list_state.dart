import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:core/core.dart';
import '../../domain/entity/chat_room_summary.dart';

part 'chat_room_list_state.freezed.dart';

/// 채팅 탭(내 방 목록)의 상태.
@freezed
class ChatRoomListState with _$ChatRoomListState {
  const ChatRoomListState({
    this.status = ChatRoomListStatus.loading,
    this.items = const [],
    this.failure,
  });

  @override
  final ChatRoomListStatus status;
  @override
  final List<ChatRoomSummary> items;
  @override
  final Failure? failure;

  /// 하단 탭 배지에 쓰는 합계.
  ///
  /// v1 에서 이 값은 목록을 다시 읽을 때만 갱신된다 — 방 밖에서의 상시 갱신은
  /// 푸시 알림과 함께 4단계에서 다룬다 (계획서 "v1 범위 밖").
  int get totalUnread =>
      items.fold(0, (sum, room) => sum + room.unreadCount);
}

enum ChatRoomListStatus { loading, loaded, failure }
