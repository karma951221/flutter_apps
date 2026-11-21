import 'package:walk/domain/chat/chat_style_settings.dart';

/// 메모리 위의 말투 · 그림 만들기 설정.
class FakeChatStyleSettings implements ChatStyleSettings {
  @override
  ChatTone tone = ChatTone.standard;

  @override
  String customTone = '';

  @override
  bool imageGeneration = true;

  @override
  Future<void> setTone(ChatTone tone, {String? custom}) async {
    this.tone = tone;
    if (custom != null) customTone = ChatTone.normalizeCustom(custom);
  }

  @override
  Future<void> setImageGeneration(bool on) async => imageGeneration = on;
}
