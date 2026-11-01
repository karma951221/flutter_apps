import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_connection.dart';
import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_vendor.dart';
import 'chat_settings_state.dart';

/// 물어보기 설정 — 키 넣기 · 바꾸기 · 지우기. 원문 키는 읽지 않는다.
class ChatSettingsCubit extends Cubit<ChatSettingsState> {
  ChatSettingsCubit(this._settings) : super(const ChatSettingsState());

  final ChatSettings _settings;

  /// 연결 정보를 읽지 못하면 미연결처럼 보인다.
  Future<void> load() async {
    ChatConnection? connection;
    try {
      connection = await _settings.connection();
    } on Object {
      connection = null;
    }
    if (!isClosed) {
      emit(ChatSettingsState(loading: false, connection: connection));
    }
  }

  /// 저장하지 못하면 false — 화면이 알린다. 연결은 그대로 둔다.
  /// 빈 키는 지금처럼 끊기와 같다.
  Future<bool> save(String key) => _write(
    () => key.trim().isEmpty
        ? _settings.disconnect()
        : _settings.connect(
            ChatVendor.anthropic,
            key,
            ChatKeyStatus.unverified,
          ),
  );

  /// 지우지 못하면 false.
  Future<bool> delete() => _write(_settings.disconnect);

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
}
