/// 채팅 설정 — Anthropic API 키(보안 저장소)와 데이터 전송 동의.
abstract interface class ChatSettings {
  /// 저장 안 했거나 빈 문자열이면 null.
  Future<String?> apiKey();

  /// trim 해서 저장한다. 빈 문자열이면 [deleteApiKey] 와 같다.
  Future<void> saveApiKey(String key);

  Future<void> deleteApiKey();

  /// 전송 안내에 동의했는가.
  bool get consented;

  Future<void> setConsented();
}
