import 'package:walk/domain/chat/chat_settings.dart';

/// 메모리 위 [ChatSettings]. 키와 동의를 테스트가 직접 바꾼다.
class FakeChatSettings implements ChatSettings {
  FakeChatSettings([this.key]);

  String? key;

  @override
  Future<String?> apiKey() async => key;

  @override
  Future<void> saveApiKey(String value) async {
    final t = value.trim();
    key = t.isEmpty ? null : t;
  }

  @override
  Future<void> deleteApiKey() async => key = null;

  @override
  bool consented = false;

  @override
  Future<void> setConsented() async => consented = true;
}
