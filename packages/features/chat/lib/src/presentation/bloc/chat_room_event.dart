import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/chat_image_draft.dart';
import '../../domain/entity/chat_message.dart';

part 'chat_room_event.freezed.dart';

/// 방 화면에서 일어나는 일.
///
/// 이벤트가 여럿이라 Cubit 이 아니라 Bloc 이다 (아키텍처 §4).
@freezed
sealed class ChatRoomEvent with _$ChatRoomEvent {
  /// 화면이 열렸다. 구독을 먼저 걸고 히스토리를 읽는다.
  const factory ChatRoomEvent.started(String roomId) = ChatRoomStarted;

  /// 구독으로 새 메시지가 도착했다.
  const factory ChatRoomEvent.messageReceived(ChatMessage message) =
      ChatRoomMessageReceived;

  const factory ChatRoomEvent.sendRequested(String text) = ChatRoomSendRequested;

  const factory ChatRoomEvent.imageSendRequested(ChatImageDraft image) =
      ChatRoomImageSendRequested;

  /// 실패한 버블의 재전송.
  const factory ChatRoomEvent.retryRequested(String messageId) =
      ChatRoomRetryRequested;

  /// 위로 스크롤해 더 오래된 페이지를 읽는다.
  const factory ChatRoomEvent.moreRequested() = ChatRoomMoreRequested;

  const factory ChatRoomEvent.deleteRequested(String messageId) =
      ChatRoomDeleteRequested;

  /// 참여자가 바뀌었을 수 있다 — 모르는 사람의 메시지가 왔을 때 스스로 부른다.
  const factory ChatRoomEvent.participantsRefreshed() =
      ChatRoomParticipantsRefreshed;

  /// 화면을 벗어난다. 읽음을 확정한다.
  const factory ChatRoomEvent.readConfirmed() = ChatRoomReadConfirmed;
}
