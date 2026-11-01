import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_connection.dart';
import '../../../domain/chat/chat_model.dart';
import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/chat/usecase/chat_key_verifier.dart';
import 'chat_settings_state.dart';

/// 저장 전 확인 결과.
enum ChatKeyCheck { valid, invalid, unreachable }

/// 물어보기 설정 — 키 확인 · 등록 · 끊기. 저장된 원문 키는 읽지 않고,
/// 입력한 키도 상태에 담지 않는다.
class ChatSettingsCubit extends Cubit<ChatSettingsState> {
  ChatSettingsCubit(this._settings, this._verifier)
    : super(const ChatSettingsState());

  final ChatSettings _settings;
  final ChatKeyVerifier _verifier;

  /// ② 는 Claude 하나. ④ 가 벤더 시트에서 고른 값으로 바꾼다.
  static const vendor = ChatVendor.anthropic;

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

  /// 입력한 키를 확인만 한다(저장 안 함). trim 해서 보낸다.
  Future<ChatKeyCheck> check(String key) async =>
      switch (await _verifier.verify(vendor, key.trim())) {
        ModelListOk() => ChatKeyCheck.valid,
        ModelListInvalidKey() => ChatKeyCheck.invalid,
        ModelListUnreachable() => ChatKeyCheck.unreachable,
      };

  /// [check] 결과로 등록한다. valid → [ChatKeyStatus.valid], unreachable → unverified,
  /// invalid 면 ArgumentError. 쓰지 못하면 false(기존 연결 그대로). 성공하면 다시 읽는다.
  Future<bool> connect(String key, ChatKeyCheck check) {
    final status = switch (check) {
      ChatKeyCheck.valid => ChatKeyStatus.valid,
      ChatKeyCheck.unreachable => ChatKeyStatus.unverified,
      ChatKeyCheck.invalid => throw ArgumentError.value(
        check,
        'check',
        'invalid key',
      ),
    };
    return _write(() => _settings.connect(vendor, key, status));
  }

  /// 끊지 못하면 false.
  Future<bool> disconnect() => _write(_settings.disconnect);

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
