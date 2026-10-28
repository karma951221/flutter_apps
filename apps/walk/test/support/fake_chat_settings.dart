import 'package:walk/domain/chat/chat_settings.dart';

/// 메모리 위 [ChatSettings]. 키와 동의를 테스트가 직접 바꾼다.
class FakeChatSettings implements ChatSettings {
  FakeChatSettings([this.key]);

  String? key;

  /// null 이 아니면 키 읽기 · 저장 · 삭제가 이 오류를 던진다(보안 저장소 실패).
  Object? failWith;

  void _maybeFail() {
    final error = failWith;
    if (error != null) throw error;
  }

  @override
  Future<String?> apiKey() async {
    _maybeFail();
    return key;
  }

  @override
  Future<void> saveApiKey(String value) async {
    _maybeFail();
    final t = value.trim();
    key = t.isEmpty ? null : t;
  }

  @override
  Future<void> deleteApiKey() async {
    _maybeFail();
    key = null;
  }

  @override
  bool consented = false;

  @override
  Future<void> setConsented() async => consented = true;
}
