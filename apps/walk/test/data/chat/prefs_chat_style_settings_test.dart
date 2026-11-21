import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/chat/prefs_chat_style_settings.dart';
import 'package:walk/domain/chat/chat_style_settings.dart';

void main() {
  Future<PrefsChatStyleSettings> settings([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return PrefsChatStyleSettings(await SharedPreferences.getInstance());
  }

  test('처음엔 기본 말투 · 빈 직접 입력 · 그림 만들기 켬', () async {
    final s = await settings();
    expect(s.tone, ChatTone.standard);
    expect(s.customTone, '');
    expect(s.imageGeneration, isTrue);
  });

  test('모르는 이름 · 다른 타입이면 기본값', () async {
    final s = await settings({
      PrefsChatStyleSettings.toneKey: 'shouting',
      PrefsChatStyleSettings.imageGenerationKey: 'yes',
      PrefsChatStyleSettings.customToneKey: 3,
    });
    expect(s.tone, ChatTone.standard);
    expect(s.imageGeneration, isTrue);
    expect(s.customTone, '');
  });

  test('말투 · 직접 입력(정리해서) · 스위치를 저장하고 다시 읽는다', () async {
    final s = await settings();
    await s.setTone(ChatTone.custom, custom: '  사투리로\n해 ');
    await s.setImageGeneration(false);

    final prefs = await SharedPreferences.getInstance();
    final again = PrefsChatStyleSettings(prefs);
    expect(again.tone, ChatTone.custom);
    expect(again.customTone, '사투리로 해');
    expect(again.imageGeneration, isFalse);
  });

  test('다른 말투를 골라도 직접 입력은 남는다', () async {
    final s = await settings();
    await s.setTone(ChatTone.custom, custom: '사투리로');
    await s.setTone(ChatTone.warm);
    expect(s.tone, ChatTone.warm);
    expect(s.customTone, '사투리로');
  });
}
