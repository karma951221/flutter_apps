import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entity/chat_message.dart';

part 'chat_room_state.freezed.dart';

/// 방 화면의 상태.
///
/// [messages] 는 **최신이 앞**이다. 화면이 `ListView(reverse: true)` 로 그리므로
/// 0번이 화면 맨 아래가 되고, 더 오래된 페이지는 뒤에 붙는다. 새 메시지를 앞에
/// 넣는 것만으로 아래에 쌓이므로 스크롤 위치를 건드릴 일이 없다.
@freezed
class ChatRoomState with _$ChatRoomState {
  const ChatRoomState({
    this.status = ChatRoomStatus.loading,
    this.roomId = '',
    this.messages = const [],
    this.participantNicknames = const {},
    this.isLoadingMore = false,
    this.nextCursor,
    this.failure,
    this.actionFailure,
  });

  @override
  final ChatRoomStatus status;
  @override
  final String roomId;
  @override
  final List<ChatMessage> messages;

  /// userId → 이 방에서 쓰는 닉네임. 나간 사람도 들어 있다 — 그 사람이 남긴
  /// 메시지에 이름을 붙여야 한다.
  @override
  final Map<String, String> participantNicknames;
  @override
  final bool isLoadingMore;
  @override
  final String? nextCursor;

  /// 방을 여는 데 실패했다. 화면 전체가 오류 안내가 된다.
  @override
  final Failure? failure;

  /// 전송·삭제처럼 목록은 살아 있는 채로 알려야 하는 실패. 스낵바로 소비하고
  /// 화면은 그대로 둔다.
  @override
  final Failure? actionFailure;

  bool get canLoadMore => nextCursor != null;

  /// 아직 서버에 닿지 않은 버블이 있는지. 나가기 확인 문구가 이 값을 본다.
  bool get hasPending => messages.any((message) => message.isPending);
}

enum ChatRoomStatus { loading, loaded, failure }
