import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/transit/repository/transit_key_store.dart';

/// 원문 키는 보안 저장소에만, 확인 상태는 prefs 에 둔다. 둘 다 백업 허용 목록에 없다.
/// 키 없이 prefs 만 남은 상태(복원 · 기기 이전)의 상태는 없는 것으로 읽는다.
@LazySingleton(as: TransitKeyStore)
class SecureTransitKeyStore implements TransitKeyStore {
  SecureTransitKeyStore(this._secure, this._prefs);

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  static const keyName = 'transit.odsayKey';
  static const statusKey = 'transit.keyStatus';

  @override
  Future<String?> read() async {
    try {
      final key = (await _secure.read(key: keyName))?.trim();
      return key == null || key.isEmpty ? null : key;
    } on Object {
      // 키스토어가 깨졌다 — 키 없음으로 본다.
      return null;
    }
  }

  @override
  Future<void> save(String key, TransitKeyStatus status) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(key, 'key', 'empty');
    await _secure.write(key: keyName, value: trimmed);
    await _prefs.setString(statusKey, status.name);
  }

  @override
  Future<void> delete() async {
    await _secure.delete(key: keyName);
    await _prefs.remove(statusKey);
  }

  @override
  Future<TransitKeyStatus?> status() async {
    if (await read() == null) return null;
    return TransitKeyStatus.values.asNameMap()[_prefs.getString(statusKey)];
  }

  @override
  Future<void> setStatus(TransitKeyStatus s) async {
    await _prefs.setString(statusKey, s.name);
  }
}
