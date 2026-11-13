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

  group('색인 크기', () {
    test('색인 크기는 처음엔 standard', () async {
      final settings = await _settings();

      expect(settings.wikiIndexSize, WikiIndexSize.standard);
    });

    test('저장한 값을 읽는다', () async {
      final writer = await _settings();

      await writer.setWikiIndexSize(WikiIndexSize.large);

      final reader = PrefsChatHistorySettings(
        await SharedPreferences.getInstance(),
      );
      expect(reader.wikiIndexSize, WikiIndexSize.large);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'walk.chat.wikiIndexSize',
        ),
        'large',
      );
    });

    test('모르는 값이면 standard', () async {
      final unknown = await _settings({
        PrefsChatHistorySettings.wikiIndexSizeKey: 'huge',
      });
      expect(unknown.wikiIndexSize, WikiIndexSize.standard);

      final number = await _settings({
        PrefsChatHistorySettings.wikiIndexSizeKey: 3,
      });
      expect(number.wikiIndexSize, WikiIndexSize.standard);
    });

    test('상한 값', () {
      expect(WikiIndexSize.small.maxNotes, 50);
      expect(WikiIndexSize.small.maxChars, 2000);
      expect(WikiIndexSize.standard.maxNotes, 150);
      expect(WikiIndexSize.standard.maxChars, 6000);
      expect(WikiIndexSize.large.maxNotes, 300);
      expect(WikiIndexSize.large.maxChars, 12000);
      expect(WikiIndexSize.all.maxNotes, isNull);
      expect(WikiIndexSize.all.maxChars, 30000);
      expect(WikiIndexSize.fallback, WikiIndexSize.standard);
    });
  });

  group('useRecords', () {
    test('처음엔 켬', () async {
      expect((await _settings()).useRecords, isTrue);
    });

    test('끈 선택을 새 인스턴스가 읽는다', () async {
      final writer = await _settings();
      await writer.setUseRecords(false);

      final reader = PrefsChatHistorySettings(
        await SharedPreferences.getInstance(),
      );
      expect(reader.useRecords, isFalse);

      await reader.setUseRecords(true);
      expect(writer.useRecords, isTrue);
    });

    test('bool 이 아니면 켬', () async {
      final wrong = await _settings({
        PrefsChatHistorySettings.useRecordsKey: 'false',
      });
      expect(wrong.useRecords, isTrue);
    });
  });
}
