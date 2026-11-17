enum TransitKeyStatus { connected, unverified, rejected }

/// ODsay 키 보관소. 키는 보안 저장소, 상태는 prefs 에 둔다.
abstract interface class TransitKeyStore {
  Future<String?> read();
  Future<void> save(String key, TransitKeyStatus status);
  Future<void> delete();
  Future<TransitKeyStatus?> status();
  Future<void> setStatus(TransitKeyStatus s);

  /// 키가 저장 · 삭제될 때마다 알린다. 상태만 바뀔 때([setStatus])는 알리지 않는다.
  Stream<void> get changes;
}
