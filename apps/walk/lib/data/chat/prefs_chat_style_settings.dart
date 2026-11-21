import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/chat/chat_style_settings.dart';

/// 말투는 enum 이름, 직접 입력은 문자열, 그림 만들기는 bool. 타입이 다르거나 모르는 값이면 기본값.
@LazySingleton(as: ChatStyleSettings)
class PrefsChatStyleSettings implements ChatStyleSettings {
  PrefsChatStyleSettings(this._prefs);

  final SharedPreferences _prefs;

  static const toneKey = 'walk.chat.tone';
  static const customToneKey = 'walk.chat.customTone';
  static const imageGenerationKey = 'walk.chat.imageGeneration';

  String? _string(String key) => switch (_prefs.get(key)) {
    final String value => value,
    _ => null,
  };

  @override
  ChatTone get tone =>
      ChatTone.values.asNameMap()[_string(toneKey)] ?? ChatTone.fallback;

  @override
  String get customTone => _string(customToneKey) ?? '';

  @override
  Future<void> setTone(ChatTone tone, {String? custom}) async {
    if (custom != null) {
      await _prefs.setString(customToneKey, ChatTone.normalizeCustom(custom));
    }
    await _prefs.setString(toneKey, tone.name);
  }

  /// 없거나 bool 이 아니면 켬.
  @override
  bool get imageGeneration => switch (_prefs.get(imageGenerationKey)) {
    final bool value => value,
    _ => true,
  };

  @override
  Future<void> setImageGeneration(bool on) =>
      _prefs.setBool(imageGenerationKey, on);
}
