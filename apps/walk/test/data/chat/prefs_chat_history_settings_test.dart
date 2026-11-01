import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/chat/prefs_chat_history_settings.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';

Future<PrefsChatHistorySettings> _settings([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsChatHistorySettings(await SharedPreferences.getInstance());
}

void main() {
  test('처음엔 never', () async {
    final settings = await _settings();

    expect(settings.retention, ChatRetention.never);
  });

  test('저장한 값을 읽는다', () async {
    final writer = await _settings();

    await writer.setRetention(ChatRetention.day90);

    final reader = PrefsChatHistorySettings(
      await SharedPreferences.getInstance(),
    );
    expect(reader.retention, ChatRetention.day90);
  });

  test('모르는 이름 · 숫자 값이면 never', () async {
    final unknown = await _settings({
      PrefsChatHistorySettings.retentionKey: 'day365',
    });
    expect(unknown.retention, ChatRetention.never);

    final number = await _settings({PrefsChatHistorySettings.retentionKey: 30});
    expect(number.retention, ChatRetention.never);
  });
}
