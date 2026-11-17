enum TransitKeyStatus { connected, unverified, rejected }

/// ODsay 키 보관소. 키는 보안 저장소, 상태는 prefs 에 둔다.
abstract interface class TransitKeyStore {
  Future<String?> read();
  Future<void> save(String key, TransitKeyStatus status);
  Future<void> delete();
  Future<TransitKeyStatus?> status();
  Future<void> setStatus(TransitKeyStatus s);
}
