import 'dart:async';

import 'package:injectable/injectable.dart';

import '../chat_connection.dart';
import '../chat_model.dart';
import '../chat_settings.dart';
import '../chat_vendor.dart';

/// 키 확인(모델 목록 호출). 원문 키를 읽는 두 곳 중 하나(`ChatSession` 과 이것).
///
/// 키 기획 ② 는 목록 내용을 버리고 판정만 쓴다. 결과 값은 그대로 돌려줘 ③ 의
/// 카탈로그가 받아 쓰게 한다.
@injectable
class ChatKeyVerifier {
  ChatKeyVerifier(this._model, this._settings);

  final ChatModel _model;
  final ChatSettings _settings;

  static const timeout = Duration(seconds: 10);

  /// 진행 중인 [recheckIfUnverified]. 동시에 불리면 이것을 같이 기다린다.
  Future<ChatKeyStatus?>? _recheck;

  /// 저장 전 확인. 던지지 않는다 — 예외 · [timeout] 초과는 unreachable.
  /// [vendor] 가 모델 어댑터의 벤더와 다르면 ArgumentError(② 는 Claude 하나,
  /// ④ 에서 레지스트리로).
  Future<ModelListResult> verify(ChatVendor vendor, String key) {
    if (vendor != _model.vendor) {
      throw ArgumentError.value(vendor, 'vendor', 'no adapter');
    }
    return _list(key);
  }

  Future<ModelListResult> _list(String key) async {
    try {
      return await Future.sync(() => _model.listModels(key)).timeout(
        timeout,
        onTimeout: () => const ModelListResult.unreachable(),
      );
    } catch (_) {
      return const ModelListResult.unreachable();
    }
  }

  /// 저장된 연결이 unverified 면 저장된 키로 확인해 valid/invalid 를 기록한다(§4 끝 줄).
  /// 기록한 새 상태, 아무것도 안 했으면 null. 동시에 불리면 진행 중인 확인을 같이 기다린다.
  /// 던지지 않는다 — 설정을 읽거나 쓰지 못하면 null.
  Future<ChatKeyStatus?> recheckIfUnverified() =>
      _recheck ??= _recheckOnce().whenComplete(() => _recheck = null);

  Future<ChatKeyStatus?> _recheckOnce() async {
    try {
      final connection = await _settings.connection();
      if (connection == null ||
          connection.status != ChatKeyStatus.unverified ||
          connection.vendor != _model.vendor) {
        return null;
      }
      final key = await _settings.apiKey();
      if (key == null) return null;
      final status = switch (await _list(key)) {
        ModelListOk() => ChatKeyStatus.valid,
        ModelListInvalidKey() => ChatKeyStatus.invalid,
        ModelListUnreachable() => null,
      };
      if (status == null) return null;
      // 확인하는 동안 키를 바꿨거나 끊었으면 지난 키의 판정을 기록하지 않는다.
      final now = await _settings.connection();
      if (now == null || now.status != ChatKeyStatus.unverified) return null;
      if (await _settings.apiKey() != key) return null;
      await _settings.setKeyStatus(status);
      return status;
    } catch (_) {
      return null;
    }
  }
}
