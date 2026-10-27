import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_settings.dart';
import 'chat_settings_state.dart';

/// 설정 탭 "채팅" 섹션 — API 키 넣기 · 바꾸기 · 지우기.
class ChatSettingsCubit extends Cubit<ChatSettingsState> {
  ChatSettingsCubit(this._settings) : super(const ChatSettingsState());

  final ChatSettings _settings;

  Future<void> load() async {
    final key = await _settings.apiKey();
    if (!isClosed) emit(ChatSettingsState(loading: false, keyHint: _hint(key)));
  }

  Future<void> save(String key) async {
    await _settings.saveApiKey(key);
    await load();
  }

  Future<void> delete() async {
    await _settings.deleteApiKey();
    await load();
  }

  static String? _hint(String? key) {
    if (key == null || key.isEmpty) return null;
    final tail = key.length <= 4 ? key : key.substring(key.length - 4);
    return '…$tail';
  }
}
