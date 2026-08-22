import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 세션을 Keychain / EncryptedSharedPreferences 에 저장한다.
///
/// supabase_flutter 의 기본 구현은 세션(access / refresh 토큰)을
/// SharedPreferences 에 **평문으로** 저장한다. 토큰은 비밀이므로 교체한다.
class SecureSupabaseStorage extends LocalStorage {
  const SecureSupabaseStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _sessionKey = 'supabase.session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      await _storage.read(key: _sessionKey) != null;

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);
}
