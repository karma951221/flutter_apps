import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/chat/chat_settings.dart';

/// API 키는 보안 저장소에만 둔다. SharedPreferences 에는 동의 여부만 남는다.
@LazySingleton(as: ChatSettings)
class SecureChatSettings implements ChatSettings {
  SecureChatSettings(this._secure, this._prefs);

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  static const apiKeyName = 'anthropic_api_key';
  static const consentedKey = 'chat.consented';

  @override
  Future<String?> apiKey() async {
    final value = (await _secure.read(key: apiKeyName))?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<void> saveApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return deleteApiKey();
    await _secure.write(key: apiKeyName, value: trimmed);
  }

  @override
  Future<void> deleteApiKey() => _secure.delete(key: apiKeyName);

  @override
  bool get consented => _prefs.get(consentedKey) == true;

  @override
  Future<void> setConsented() => _prefs.setBool(consentedKey, true);
}
