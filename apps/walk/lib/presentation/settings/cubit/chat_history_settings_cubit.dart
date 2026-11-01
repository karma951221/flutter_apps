import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_history_settings.dart';
import '../../../domain/chat/repository/chat_history_repository.dart';
import 'chat_history_settings_state.dart';

/// 대화 보관 기간과 대화 모두 지우기. 저장소 실패는 호출한 쪽(화면)으로 그대로 던진다.
class ChatHistorySettingsCubit extends Cubit<ChatHistorySettingsState> {
  ChatHistorySettingsCubit(this._settings, this._history)
    : super(const ChatHistorySettingsState());

  final ChatHistorySettings _settings;
  final ChatHistoryRepository _history;

  /// 보관 기간 · 대화 수를 읽는다. 대화 수를 못 읽으면 0 으로 둔다(모두 지우기 행이 꺼진다).
  Future<void> load() async {
    final retention = _settings.retention;
    var count = 0;
    try {
      count = await _history.count();
    } on Object {
      count = 0;
    }
    if (isClosed) return;
    emit(state.copyWith(retention: retention, conversationCount: count));
  }

  Future<void> setRetention(ChatRetention value) async {
    await _settings.setRetention(value);
    if (isClosed) return;
    emit(state.copyWith(retention: value));
  }

  /// 지운 대화 수. 뒤에 대화 수를 다시 읽는다.
  Future<int> deleteAllConversations() async {
    final deleted = await _history.deleteAll();
    final count = await _history.count();
    if (!isClosed) emit(state.copyWith(conversationCount: count));
    return deleted;
  }
}
