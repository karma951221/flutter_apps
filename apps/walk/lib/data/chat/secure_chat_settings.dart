import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/chat/api_key_mask.dart';
import '../../domain/chat/chat_connection.dart';
import '../../domain/chat/chat_settings.dart';
import '../../domain/chat/chat_vendor.dart';

/// 원문 키는 보안 저장소에만 둔다. SharedPreferences 에는 벤더 · 확인 상태 · 동의 · 고른 모델 ·
/// 빠른 출력만 남는다
/// (키 미리보기도 저장하지 않고 읽을 때마다 가린다).
///
/// 보안 저장소 항목은 백업에서 빠진다(android res/xml 의 백업 규칙). 복원돼 prefs 만 남으면
/// 읽을 때 미연결로 정리한다.
@LazySingleton(as: ChatSettings)
class SecureChatSettings implements ChatSettings {
  SecureChatSettings(this._secure, this._prefs);

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  static const apiKeyName = 'chat.apiKey';

  /// 벤더 중립 이전의 저장 키. 첫 접근 때 [apiKeyName] 으로 옮기고 지운다.
  static const legacyApiKeyName = 'anthropic_api_key';
  static const vendorKey = 'chat.vendor';
  static const keyStatusKey = 'chat.keyStatus';
  static const consentedVendorKey = 'chat.consentedVendor';

  /// 벤더별 동의 이전의 저장 키(bool). 첫 접근 때 [consentedVendorKey] 로 옮기고 지운다.
  static const legacyConsentedKey = 'chat.consented';
  static const modelKey = 'chat.model';
  static const fastModeKey = 'chat.fastMode';
  static const fastModeAckKey = 'chat.fastMode.ack';

  /// 옛 키 이전. 성공하면 메모하고, 실패하면 비워 다음 접근 때 다시 한다.
  Future<void>? _migration;

  Future<void> _migrated() => _migration ??= _migrateLegacy().then(
    (_) {},
    onError: (Object _) => _migration = null,
  );

  Future<void> _migrateLegacy() async {
    String? legacy;
    try {
      legacy = (await _secure.read(key: legacyApiKeyName))?.trim();
    } on Object {
      // 옛 항목을 읽을 수 없다 — 다시 시도해도 같으니 지우고 끝낸다.
      await _deleteQuietly(legacyApiKeyName);
      return;
    }
    if (legacy == null) return;
    final current = (await _secure.read(key: apiKeyName))?.trim();
    if (legacy.isNotEmpty && (current == null || current.isEmpty)) {
      await _secure.write(key: apiKeyName, value: legacy);
      await _prefs.setString(vendorKey, ChatVendor.anthropic.name);
      await _prefs.setString(keyStatusKey, ChatKeyStatus.unverified.name);
    }
    await _secure.delete(key: legacyApiKeyName);
  }

  /// 지우기를 시도한다. 실패는 삼킨다.
  Future<void> _deleteQuietly(String name) async {
    try {
      await _secure.delete(key: name);
    } on Object {
      // 지우지 못해도 미연결로 본다.
    }
  }

  /// 연결을 잊는다 — 벤더 · 상태 · 고른 모델. 빠른 출력 · 동의는 남긴다.
  Future<void> _forgetPrefs() async {
    await _prefs.remove(vendorKey);
    await _prefs.remove(keyStatusKey);
    await _prefs.remove(modelKey);
  }

  ChatVendor? get _storedVendor =>
      ChatVendor.values.asNameMap()[_prefs.getString(vendorKey)];

  ChatKeyStatus? get _storedStatus =>
      ChatKeyStatus.values.asNameMap()[_prefs.getString(keyStatusKey)];

  /// 키를 읽고 prefs 를 키에 맞춘다. 미연결이면 null.
  Future<String?> _readKey() async {
    await _migrated();
    String? raw;
    try {
      raw = await _secure.read(key: apiKeyName);
    } on Object {
      // 키스토어가 깨졌다(복원 · 기기 이전 등). 항목을 지우고 미연결로 둔다.
      await _deleteQuietly(apiKeyName);
      await _forgetPrefs();
      return null;
    }
    final key = raw?.trim();
    if (key == null || key.isEmpty) {
      if (_prefs.containsKey(vendorKey) || _prefs.containsKey(keyStatusKey)) {
        await _forgetPrefs();
      }
      return null;
    }
    if (_storedVendor == null) {
      await _prefs.setString(
        vendorKey,
        (vendorOfKey(key) ?? ChatVendor.anthropic).name,
      );
      await _prefs.setString(keyStatusKey, ChatKeyStatus.unverified.name);
    } else if (_storedStatus == null) {
      await _prefs.setString(keyStatusKey, ChatKeyStatus.unverified.name);
    }
    return key;
  }

  @override
  Future<ChatConnection?> connection() async {
    final key = await _readKey();
    if (key == null) return null;
    final vendor = _storedVendor ?? ChatVendor.anthropic;
    return ChatConnection(
      vendor: vendor,
      keyPreview: maskApiKey(vendor, key),
      status: _storedStatus ?? ChatKeyStatus.unverified,
    );
  }

  @override
  Future<bool> hasApiKey() async => await _readKey() != null;

  @override
  Future<String?> apiKey() => _readKey();

  @override
  Future<void> connect(
    ChatVendor vendor,
    String key,
    ChatKeyStatus status,
  ) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(key, 'key', 'empty');
    await _migrated();
    final previousVendor = _storedVendor;
    await _secure.write(key: apiKeyName, value: trimmed);
    try {
      await _prefs.setString(vendorKey, vendor.name);
      await _prefs.setString(keyStatusKey, status.name);
      // 고른 모델은 벤더의 것 — 다른 벤더로 바뀌면 추천으로 돌아간다.
      if (previousVendor != vendor) await _prefs.remove(modelKey);
    } on Object {
      // 키는 새것인데 벤더 · 상태 · 고른 모델은 지난 키의 것일 수 있다. 셋 다 지워 다음
      // 읽기(_readKey)가 키 접두사로 벤더를 다시 정하고 unverified 로 보게 한다.
      for (final name in const [vendorKey, keyStatusKey, modelKey]) {
        try {
          await _prefs.remove(name);
        } on Object {
          // 지우지도 못하면 그대로 둔다 — 원래 예외를 던진다.
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _migrated();
    await _secure.delete(key: apiKeyName);
    // 이전이 실패해 옛 항목이 남아 있으면 다음 접근 때 지운 키가 되살아난다.
    await _deleteQuietly(legacyApiKeyName);
    await _forgetPrefs();
  }

  /// 저장된 키를 다시 읽어 [forKey] 와 같을 때만 쓴다(읽지 못하면 미연결로 보고 쓰지 않는다).
  @override
  Future<void> setKeyStatus(
    ChatKeyStatus status, {
    required String forKey,
  }) async {
    final current = await _readKey();
    if (current == null || current != forKey.trim()) return;
    if (_storedStatus == status) return;
    await _prefs.setString(keyStatusKey, status.name);
  }

  @override
  ChatVendor? get connectedVendor => _storedVendor;

  @override
  String? get selectedModel => switch (_prefs.get(modelKey)) {
    final String id when id.isNotEmpty => id,
    _ => null,
  };

  @override
  Future<void> selectModel(String? id) async {
    if (id == null || id.isEmpty) {
      await _prefs.remove(modelKey);
    } else {
      await _prefs.setString(modelKey, id);
    }
  }

  @override
  bool get fastMode => _prefs.get(fastModeKey) == true;

  @override
  Future<void> setFastMode(bool on) => _prefs.setBool(fastModeKey, on);

  @override
  bool get fastModeAcknowledged => _prefs.get(fastModeAckKey) == true;

  @override
  Future<void> acknowledgeFastMode() => _prefs.setBool(fastModeAckKey, true);

  /// 옛 `chat.consented` 는 Claude 하나뿐이던 때의 동의 — true 면 anthropic 으로 옮긴다.
  /// prefs 는 메모리 캐시를 곧바로 바꾸므로 쓰기를 기다리지 않아도 다음 읽기는 새 값을 본다.
  @override
  ChatVendor? get consentedVendor {
    if (_prefs.containsKey(legacyConsentedKey)) {
      final legacy = _prefs.get(legacyConsentedKey) == true;
      if (legacy && !_prefs.containsKey(consentedVendorKey)) {
        unawaited(
          _prefs
              .setString(consentedVendorKey, ChatVendor.anthropic.name)
              .then<void>(
                (_) => _prefs.remove(legacyConsentedKey),
                onError: (Object _) {},
              ),
        );
        return ChatVendor.anthropic;
      }
      unawaited(
        _prefs
            .remove(legacyConsentedKey)
            .then<void>((_) {}, onError: (Object _) {}),
      );
    }
    return ChatVendor.values.asNameMap()[_prefs.get(consentedVendorKey)];
  }

  @override
  Future<void> setConsented(ChatVendor vendor) async {
    await _prefs.setString(consentedVendorKey, vendor.name);
    await _prefs.remove(legacyConsentedKey);
  }
}
