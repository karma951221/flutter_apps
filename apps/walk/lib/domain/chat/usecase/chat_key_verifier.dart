import 'dart:async';

import 'package:injectable/injectable.dart';

import '../chat_connection.dart';
import '../chat_model.dart';
import '../chat_settings.dart';
import '../chat_vendor.dart';

/// 키 확인 · 목록 받기(모델 목록 호출). 원문 키를 읽는 두 곳 중 하나(`ChatSession` 과 이것).
///
/// 저장 전 확인([verify])은 결과를 그대로 돌려줘 cubit 이 목록을 카탈로그에 넣게 하고(§4
/// "한 번 호출로 두 가지"), 저장된 키로 받는 [fetchStored] 는 `ChatModelChoice.refresh` 가
/// 쓴다(결정 G4 — 카탈로그 · 고른 모델 쪽은 키를 모른다).
///
/// 싱글턴 — 여러 화면이 동시에 [fetchStored] 를 불러도 호출은 하나.
@lazySingleton
class ChatKeyVerifier {
  ChatKeyVerifier(this._registry, this._settings);

  final ChatModelRegistry _registry;
  final ChatSettings _settings;

  /// [verify] 전체 상한. 저장 버튼이 이만큼 기다린다. 어댑터의 쪽마다 상한과 별개라
  /// 여러 쪽 목록이 이 안에 끝나지 않으면 unreachable 이다.
  static const timeout = Duration(seconds: 10);

  /// [fetchStored] 전체 상한. 뒤에서 받으므로(기다리는 버튼이 없다) 여러 쪽을 받을
  /// 여유를 둔다 — 쪽마다 상한은 어댑터가 따로 건다.
  static const storedTimeout = Duration(seconds: 30);

  /// 진행 중인 [fetchStored]. 동시에 불리면 이것을 같이 기다린다.
  Future<(ChatVendor, ModelListResult)?>? _fetch;

  /// 저장 전 확인 — [vendor] 어댑터의 목록을 부른다. 던지지 않는다 — 예외(어댑터가
  /// 없는 벤더 포함) · [timeout] 초과는 unreachable.
  Future<ModelListResult> verify(ChatVendor vendor, String key) =>
      _list(vendor, key, timeout);

  Future<ModelListResult> _list(
    ChatVendor vendor,
    String key,
    Duration limit,
  ) async {
    try {
      return await Future.sync(
        () => _registry.of(vendor).listModels(key),
      ).timeout(limit, onTimeout: () => const ModelListResult.unreachable());
    } catch (_) {
      return const ModelListResult.unreachable();
    }
  }

  /// 저장된 키 · 벤더로 목록을 받는다(원문 키를 읽는 두 곳 중 하나). 키 상태도 기록한다:
  /// ok → valid, invalidKey → invalid, unreachable → 그대로. 미연결이면 null. 동시에 불리면 하나를 같이 기다린다.
  ///
  /// 받는 동안 키를 바꿨거나 끊었으면 지난 키의 결과라 기록하지 않고 null. 던지지 않는다 —
  /// 설정을 읽지 못하면 null(상태 기록만 실패하면 결과는 그대로 준다).
  Future<(ChatVendor, ModelListResult)?> fetchStored() =>
      _fetch ??= _fetchOnce().whenComplete(() => _fetch = null);

  Future<(ChatVendor, ModelListResult)?> _fetchOnce() async {
    try {
      final connection = await _settings.connection();
      if (connection == null) return null;
      final key = await _settings.apiKey();
      if (key == null) return null;
      final vendor = connection.vendor;
      final result = await _list(vendor, key, storedTimeout);
      final now = await _settings.connection();
      if (now == null || now.vendor != vendor) return null;
      if (await _settings.apiKey() != key) return null;
      final status = switch (result) {
        ModelListOk() => ChatKeyStatus.valid,
        ModelListInvalidKey() => ChatKeyStatus.invalid,
        ModelListUnreachable() => null,
      };
      if (status != null) {
        try {
          // 그사이 키를 바꿨으면 setKeyStatus 가 기록하지 않는다.
          await _settings.setKeyStatus(status, forKey: key);
        } catch (_) {
          // 판정 기록은 다음 확인 때 다시 한다.
        }
      }
      return (vendor, result);
    } catch (_) {
      return null;
    }
  }
}
