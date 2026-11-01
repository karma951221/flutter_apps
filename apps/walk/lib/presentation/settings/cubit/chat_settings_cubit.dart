import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_settings.dart';
import 'chat_settings_state.dart';

/// 물어보기 설정 — API 키 넣기 · 바꾸기 · 지우기.
class ChatSettingsCubit extends Cubit<ChatSettingsState> {
  ChatSettingsCubit(this._settings) : super(const ChatSettingsState());

  final ChatSettings _settings;

  /// 보안 저장소를 읽지 못하면 키가 없는 것처럼 보인다.
  Future<void> load() async {
    String? key;
    try {
      key = await _settings.apiKey();
    } on Object {
      key = null;
    }
    if (!isClosed) emit(ChatSettingsState(loading: false, keyHint: _hint(key)));
  }

  /// 저장하지 못하면 false — 화면이 알린다. 힌트는 그대로 둔다.
  Future<bool> save(String key) => _write(() => _settings.saveApiKey(key));

  /// 지우지 못하면 false.
  Future<bool> delete() => _write(_settings.deleteApiKey);

  Future<bool> _write(Future<void> Function() write) async {
    try {
      await write();
    } on Object {
      if (!isClosed) emit(state.copyWith(loading: false));
      return false;
    }
    await load();
    return true;
  }

  static String? _hint(String? key) {
    if (key == null || key.isEmpty) return null;
    final tail = key.length <= 4 ? key : key.substring(key.length - 4);
    return '…$tail';
  }
}
