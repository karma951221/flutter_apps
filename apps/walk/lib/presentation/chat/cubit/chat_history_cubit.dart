import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/entity/conversation.dart';
import '../../../domain/chat/repository/chat_history_repository.dart';
import 'chat_history_state.dart';

/// 대화 목록 화면. 만들 때 저장소의 목록을 구독하고, 이름 바꾸기 · 삭제는 저장소로 넘긴다 —
/// 바뀐 목록은 스트림으로 다시 들어온다.
class ChatHistoryCubit extends Cubit<ChatHistoryState> {
  ChatHistoryCubit(this._history) : super(const ChatHistoryState()) {
    _subscription = _history.conversations().listen(
      (conversations) =>
          emit(state.copyWith(loading: false, conversations: conversations)),
    );
  }

  final ChatHistoryRepository _history;
  late final StreamSubscription<List<Conversation>> _subscription;

  Future<void> rename(String id, String title) => _history.rename(id, title);

  Future<void> delete(String id) => _history.delete(id);

  /// 지운 대화 수.
  Future<int> deleteAll() => _history.deleteAll();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
