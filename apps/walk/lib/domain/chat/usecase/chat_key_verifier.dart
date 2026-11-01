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
///
/// 싱글턴 — 여러 화면이 동시에 [recheckIfUnverified] 를 불러도 확인은 하나.
@lazySingleton
class ChatKeyVerifier {
  ChatKeyVerifier(this._registry, this._settings);

  final ChatModelRegistry _registry;
  final ChatSettings _settings;

  static const timeout = Duration(seconds: 10);

  /// 진행 중인 [recheckIfUnverified]. 동시에 불리면 이것을 같이 기다린다.
  Future<ChatKeyStatus?>? _recheck;

  /// 저장 전 확인 — [vendor] 어댑터의 목록을 부른다. 던지지 않는다 — 예외(어댑터가
  /// 없는 벤더 포함) · [timeout] 초과는 unreachable.
  Future<ModelListResult> verify(ChatVendor vendor, String key) =>
      _list(vendor, key);

  Future<ModelListResult> _list(ChatVendor vendor, String key) async {
    try {
      return await Future.sync(
        () => _registry.of(vendor).listModels(key),
      ).timeout(timeout, onTimeout: () => const ModelListResult.unreachable());
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
      if (connection == null || connection.status != ChatKeyStatus.unverified) {
        return null;
      }
      final key = await _settings.apiKey();
      if (key == null) return null;
      final status = switch (await _list(connection.vendor, key)) {
        ModelListOk() => ChatKeyStatus.valid,
        ModelListInvalidKey() => ChatKeyStatus.invalid,
        ModelListUnreachable() => null,
      };
      if (status == null) return null;
      // 그사이 다른 쪽(질문 등)이 이미 판정했으면 덮지 않는다.
      final now = await _settings.connection();
      if (now == null || now.status != ChatKeyStatus.unverified) return null;
      // 확인하는 동안 키를 바꿨거나 끊었으면 setKeyStatus 가 기록하지 않는다.
      await _settings.setKeyStatus(status, forKey: key);
      final after = await _settings.connection();
      return after?.status == status ? status : null;
    } catch (_) {
      return null;
    }
  }
}
