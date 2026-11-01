import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_connection.dart';
import '../../../domain/chat/chat_model.dart';
import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/chat/usecase/chat_key_verifier.dart';
import '../../../domain/chat/usecase/chat_model_choice.dart';
import '../../chat/widget/model_chip.dart';
import 'chat_settings_state.dart';

/// 저장 전 확인 결과.
enum ChatKeyCheck { valid, invalid, unreachable }

/// 물어보기 설정 — 키 확인 · 등록 · 끊기 · 모델 행. 저장된 원문 키는 읽지 않고,
/// 입력한 키도 상태에 담지 않는다.
class ChatSettingsCubit extends Cubit<ChatSettingsState> {
  ChatSettingsCubit(this._settings, this._verifier, this._choice)
    : super(const ChatSettingsState());

  final ChatSettings _settings;
  final ChatKeyVerifier _verifier;
  final ChatModelChoice _choice;

  /// ② 는 Claude 하나. ④ 가 벤더 시트에서 고른 값으로 바꾼다.
  static const vendor = ChatVendor.anthropic;

  /// 마지막 [check] 가 받은 목록(벤더 · 목록, 키 아님). 등록 뒤 다시 받지 않고 넣는다(결정 G5).
  /// ok 가 아닌 확인이면 비운다.
  (ChatVendor, List<ModelInfo>)? _checkedModels;

  /// 연결 정보를 읽고, 모델 목록을 규칙대로 갱신한 뒤(설정 화면이 열릴 때 — 24시간 ·
  /// unverified · 벤더 다름일 때만) 다시 읽는다. 연결 정보를 읽지 못하면 미연결처럼 보인다.
  Future<void> load() => _load(refreshModels: true);

  /// [pending] 이면 목록을 뒤에서 받는 중이다.
  Future<void> _load({
    required bool refreshModels,
    bool pending = false,
  }) async {
    ChatConnection? connection;
    try {
      connection = await _settings.connection();
    } on Object {
      connection = null;
    }
    if (isClosed) return;
    // 목록을 받는 동안엔 "받지 못했어요"를 미리 보이지 않는다.
    _emit(connection, settled: !pending && !refreshModels);
    if (!refreshModels || connection == null) return;
    await _choice.refresh();
    await _reload();
  }

  /// 모델 행 "다시 시도" — 목록을 강제로 받은 뒤 다시 읽는다(받으면 키 상태도 바뀐다).
  Future<void> retryModels() async {
    await _choice.refresh(force: true);
    await _reload();
  }

  /// 모델 고르기 시트가 바꾼 뒤 모델 행을 다시 읽는다.
  void modelChanged() {
    if (isClosed) return;
    _emit(state.connection, settled: true);
  }

  /// 목록 갱신 뒤 — 키 상태가 바뀌었을 수 있어 연결도 다시 읽는다.
  Future<void> _reload() async {
    ChatConnection? connection;
    try {
      connection = await _settings.connection();
    } on Object {
      connection = state.connection;
    }
    if (isClosed) return;
    _emit(connection, settled: true);
  }

  /// [settled] 가 false 면 모델이 없어도 아직 "받지 못했어요" 가 아니다(받는 중).
  void _emit(ChatConnection? connection, {required bool settled}) {
    final model = connection == null ? null : ModelChipData.of(_choice);
    emit(
      ChatSettingsState(
        loading: false,
        connection: connection,
        model: model,
        fastMode: model != null && _choice.fastModeOn,
        modelsUnavailable: settled && connection != null && model == null,
      ),
    );
  }

  /// 입력한 키를 확인만 한다(저장 안 함). trim 해서 보낸다. ok 면 받은 목록을 들고 있다가
  /// [connect] 가 넣는다.
  Future<ChatKeyCheck> check(String key) async {
    final result = await _verifier.verify(vendor, key.trim());
    _checkedModels = switch (result) {
      ModelListOk(:final models) => (vendor, models),
      _ => null,
    };
    return switch (result) {
      ModelListOk() => ChatKeyCheck.valid,
      ModelListInvalidKey() => ChatKeyCheck.invalid,
      ModelListUnreachable() => ChatKeyCheck.unreachable,
    };
  }

  /// [check] 결과로 등록한다. valid → [ChatKeyStatus.valid], unreachable → unverified,
  /// invalid 면 ArgumentError. 쓰지 못하면 false(기존 연결 그대로). 성공하면 다시 읽는다.
  ///
  /// 확인 때 받은 목록이 있으면 그대로 넣고, 없으면(unreachable) 목록 강제 갱신을 뒤에서
  /// 요청한다 — 기다리지 않고, 끝나면 모델 행을 다시 읽는다.
  Future<bool> connect(String key, ChatKeyCheck check) async {
    final status = switch (check) {
      ChatKeyCheck.valid => ChatKeyStatus.valid,
      ChatKeyCheck.unreachable => ChatKeyStatus.unverified,
      ChatKeyCheck.invalid => throw ArgumentError.value(
        check,
        'check',
        'invalid key',
      ),
    };
    final checked = check == ChatKeyCheck.valid ? _checkedModels : null;
    _checkedModels = null;
    if (!await _write(() => _settings.connect(vendor, key, status))) {
      return false;
    }
    if (checked != null) {
      try {
        await _choice.adopt(checked.$1, checked.$2);
      } on Object {
        // 넣지 못하면 다음 갱신이 받는다.
      }
      await _load(refreshModels: false);
      return true;
    }
    await _load(refreshModels: false, pending: true);
    unawaited(
      _choice
          .refresh(force: true)
          .then<void>((_) => _reload(), onError: (Object _) {}),
    );
    return true;
  }

  /// 끊지 못하면 false. 끊으면 모델 목록도 비운다.
  Future<bool> disconnect() async {
    if (!await _write(_settings.disconnect)) return false;
    try {
      await _choice.forget();
    } on Object {
      // 목록은 연결 벤더가 없으면 쓰이지 않는다.
    }
    await _load(refreshModels: false);
    return true;
  }

  /// 쓰지 못하면 loading 을 내리고 false.
  Future<bool> _write(Future<void> Function() write) async {
    try {
      await write();
    } on Object {
      if (!isClosed) emit(state.copyWith(loading: false));
      return false;
    }
    return true;
  }
}
