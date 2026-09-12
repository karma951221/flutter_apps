import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecase/chat_use_case.dart';
import 'chat_room_list_state.dart';

/// 내가 참여 중인 방 목록을 소유한다.
///
/// 커서를 쓰지 않는다. 한 사람이 들어가 있는 방이 페이지가 필요할 만큼 많아지는
/// 것은 이 앱의 대상이 아니다 — 차단 목록과 같은 판단이다.
@injectable
class ChatRoomListCubit extends Cubit<ChatRoomListState> {
  ChatRoomListCubit(this._useCase) : super(const ChatRoomListState());

  final ChatUseCase _useCase;

  Future<void> load() async {
    final result = await _useCase.getMyRooms();
    if (isClosed) return;

    emit(
      result.when(
        ok: (rooms) => ChatRoomListState(
          status: ChatRoomListStatus.loaded,
          items: rooms,
        ),
        err: (failure) => ChatRoomListState(
          status: ChatRoomListStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  /// 방을 읽고 나왔을 때 그 줄의 안읽음만 0 으로 만든다.
  ///
  /// 목록을 다시 읽지 않는 이유는 피드와 같다 — 스크롤 위치가 사라진다.
  void markRoomRead(String roomId) {
    final index = state.items.indexWhere((room) => room.id == roomId);
    if (index < 0 || !state.items[index].hasUnread) return;

    final next = [...state.items];
    next[index] = next[index].asRead();
    emit(ChatRoomListState(status: state.status, items: next));
  }

  /// 방에서 나왔을 때 목록에서 걷어낸다.
  void removeRoom(String roomId) {
    final next = state.items.where((room) => room.id != roomId).toList();
    if (next.length == state.items.length) return;
    emit(ChatRoomListState(status: state.status, items: next));
  }
}
