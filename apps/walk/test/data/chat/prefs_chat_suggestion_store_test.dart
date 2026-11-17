import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/chat/prefs_chat_suggestion_store.dart';
import 'package:walk/domain/chat/suggest/chat_suggestions.dart';

Future<PrefsChatSuggestionStore> _store([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsChatSuggestionStore(await SharedPreferences.getInstance());
}

void main() {
  final at = DateTime.utc(2026, 11, 17, 9);
  final based = DateTime.utc(2026, 11, 17, 8, 30);

  test('처음엔 추천도 시도 시각도 없다', () async {
    final store = await _store();

    expect(store.current, isNull);
    expect(store.triedAt, isNull);
  });

  test('저장한 추천을 다시 읽는다', () async {
    final writer = await _store();
    final value = ChatSuggestions(
      questions: const ['어제 몇 걸음 걸었지?', '이번 주 일기 요약해 줘'],
      generatedAt: at,
      basedOnAskedAt: based,
    );

    await writer.save(value);
    await writer.setTriedAt(at);

    final reader = PrefsChatSuggestionStore(
      await SharedPreferences.getInstance(),
    );
    expect(reader.current, value);
    expect(reader.triedAt, at);
  });

  test('깨진 JSON · 빈 질문 · 문자열 아닌 질문 · 타입 다른 값이면 없다', () async {
    for (final raw in <Object>[
      '{not json',
      '{"questions":[],"generatedAt":"2026-11-17T09:00:00.000Z","basedOnAskedAt":"2026-11-17T09:00:00.000Z"}',
      '{"questions":[1,2],"generatedAt":"2026-11-17T09:00:00.000Z","basedOnAskedAt":"2026-11-17T09:00:00.000Z"}',
      '{"questions":["a"],"generatedAt":"어제"}',
      '[]',
      42,
    ]) {
      final store = await _store({PrefsChatSuggestionStore.key: raw});
      expect(store.current, isNull, reason: '$raw');
    }
    final badTried = await _store({PrefsChatSuggestionStore.triedAtKey: 'x'});
    expect(badTried.triedAt, isNull);
  });
}
