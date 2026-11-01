import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/entity/conversation.dart';
import '../../../domain/chat/repository/chat_history_repository.dart';
import 'chat_history_state.dart';

/// 대화 목록 화면. 만들 때 저장소의 목록을 구독하고, 이름 바꾸기 · 삭제는 저장소로 넘긴다 —
/// 바뀐 목록은 스트림으로 다시 들어온다. 목록을 읽지 못하면 [ChatHistoryState.failed].
/// 바꾸기 · 지우기는 던지지 않고 성공 여부를 돌려준다 — 화면이 실패를 알린다.
class ChatHistoryCubit extends Cubit<ChatHistoryState> {
  ChatHistoryCubit(this._history) : super(const ChatHistoryState()) {
    _subscription = _history.conversations().listen(
      (conversations) => emit(
        state.copyWith(
          loading: false,
          failed: false,
          conversations: conversations,
        ),
      ),
      onError: (Object _) {
        if (!isClosed) emit(state.copyWith(loading: false, failed: true));
      },
    );
  }

  final ChatHistoryRepository _history;
  late final StreamSubscription<List<Conversation>> _subscription;

  Future<bool> rename(String id, String title) =>
      _attempt(() => _history.rename(id, title));

  Future<bool> delete(String id) => _attempt(() => _history.delete(id));

  Future<bool> deleteAll() => _attempt(_history.deleteAll);

  static Future<bool> _attempt(Future<Object?> Function() action) async {
    try {
      await action();
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
