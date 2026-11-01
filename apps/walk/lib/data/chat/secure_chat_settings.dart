import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/chat/api_key_mask.dart';
import '../../domain/chat/chat_connection.dart';
import '../../domain/chat/chat_settings.dart';
import '../../domain/chat/chat_vendor.dart';

/// 원문 키는 보안 저장소에만 둔다. SharedPreferences 에는 벤더 · 확인 상태 · 동의만 남는다
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
  static const consentedKey = 'chat.consented';

  /// 옛 키 이전. 성공하면 메모하고, 실패하면 비워 다음 접근 때 다시 한다.
  Future<void>? _migration;

  Future<void> _migrated() => _migration ??= _migrateLegacy().then(
    (_) {},
    onError: (Object _) => _migration = null,
  );

  Future<void> _migrateLegacy() async {
    final legacy = (await _secure.read(key: legacyApiKeyName))?.trim();
    if (legacy == null) return;
    final current = (await _secure.read(key: apiKeyName))?.trim();
    if (legacy.isNotEmpty && (current == null || current.isEmpty)) {
      await _secure.write(key: apiKeyName, value: legacy);
      await _prefs.setString(vendorKey, ChatVendor.anthropic.name);
      await _prefs.setString(keyStatusKey, ChatKeyStatus.unverified.name);
    }
    await _secure.delete(key: legacyApiKeyName);
  }

  Future<void> _forgetPrefs() async {
    await _prefs.remove(vendorKey);
    await _prefs.remove(keyStatusKey);
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
      try {
        await _secure.delete(key: apiKeyName);
      } on Object {
        // 지우지 못해도 미연결로 본다.
      }
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
    await _secure.write(key: apiKeyName, value: trimmed);
    await _prefs.setString(vendorKey, vendor.name);
    await _prefs.setString(keyStatusKey, status.name);
  }

  @override
  Future<void> disconnect() async {
    await _migrated();
    await _secure.delete(key: apiKeyName);
    await _forgetPrefs();
  }

  @override
  Future<void> setKeyStatus(ChatKeyStatus status) async {
    if (_storedVendor == null || _storedStatus == status) return;
    await _prefs.setString(keyStatusKey, status.name);
  }

  @override
  bool get consented => _prefs.get(consentedKey) == true;

  @override
  Future<void> setConsented() => _prefs.setBool(consentedKey, true);
}
