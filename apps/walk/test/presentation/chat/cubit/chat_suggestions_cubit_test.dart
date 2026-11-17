import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/suggest/chat_suggester.dart';
import 'package:walk/domain/chat/suggest/chat_suggestions.dart';
import 'package:walk/presentation/chat/cubit/chat_suggestions_cubit.dart';

import '../../../support/fake_chat_suggester.dart';

ChatSuggestions _suggestions(List<String> questions) => ChatSuggestions(
  questions: questions,
  generatedAt: DateTime(2026, 11, 17),
  basedOnAskedAt: DateTime(2026, 11, 17),
);

void main() {
  late FakeChatSuggester suggester;

  setUp(() => suggester = FakeChatSuggester());

  test('저장된 질문이 없으면 지난 추천이 있어도 기본 칩(null) · 새로 만들기 없음', () async {
    suggester
      ..questions = false
      ..current = _suggestions(['지운 대화의 추천?']);
    final cubit = ChatSuggestionsCubit(suggester);

    await cubit.load(locale: 'ko');

    expect(cubit.state.questions, isNull);
    expect(cubit.state.canRefresh, isFalse);
    expect(suggester.locales, isEmpty);
    await cubit.close();
  });

  test('저장된 추천을 먼저 보이고, 조건이 맞아 새로 만들면 바꾼다', () async {
    suggester
      ..current = _suggestions(['옛 추천 하나?', '옛 추천 둘?', '옛 추천 셋?'])
      ..next = _suggestions(['새 추천 하나?', '새 추천 둘?', '새 추천 셋?'])
      ..dueOutcome = SuggestOutcome.generated
      ..pending = Completer();
    final cubit = ChatSuggestionsCubit(suggester);

    final loading = cubit.load(locale: 'en');
    await pumpEventQueue();
    expect(cubit.state.questions, ['옛 추천 하나?', '옛 추천 둘?', '옛 추천 셋?']);
    expect(cubit.state.canRefresh, isTrue);
    expect(suggester.locales, ['en']);

    suggester.pending!.complete(SuggestOutcome.generated);
    await loading;
    expect(cubit.state.questions, ['새 추천 하나?', '새 추천 둘?', '새 추천 셋?']);
    await cubit.close();
  });

  test('추천이 아직 없으면 기본 칩(null)', () async {
    final cubit = ChatSuggestionsCubit(suggester);

    await cubit.load();

    expect(cubit.state.questions, isNull);
    await cubit.close();
  });

  test('refresh 는 도는 동안 refreshing, 끝나면 새 추천과 true', () async {
    suggester
      ..next = _suggestions(['a?', 'b?', 'c?'])
      ..pending = Completer();
    final cubit = ChatSuggestionsCubit(suggester);
    suggester.pending = null;
    await cubit.load();
    suggester.pending = Completer();

    final result = cubit.refresh(locale: 'ko');
    expect(cubit.state.refreshing, isTrue);
    suggester.pending!.complete(SuggestOutcome.generated);

    expect(await result, isTrue);
    expect(cubit.state.refreshing, isFalse);
    expect(cubit.state.questions, ['a?', 'b?', 'c?']);
    await cubit.close();
  });

  test('refresh 가 실패하면 false 이고 추천은 그대로', () async {
    suggester
      ..current = _suggestions(['옛?', '추천?', '셋?'])
      ..refreshOutcome = SuggestOutcome.failed;
    final cubit = ChatSuggestionsCubit(suggester);
    await cubit.load();

    expect(await cubit.refresh(), isFalse);
    expect(cubit.state.questions, ['옛?', '추천?', '셋?']);
    expect(cubit.state.refreshing, isFalse);
    await cubit.close();
  });

  test('만드는 중에 닫히면 emit 하지 않는다', () async {
    suggester
      ..next = _suggestions(['a?', 'b?', 'c?'])
      ..dueOutcome = SuggestOutcome.generated
      ..pending = Completer();
    final cubit = ChatSuggestionsCubit(suggester);

    final loading = cubit.load();
    await pumpEventQueue();
    await cubit.close();
    suggester.pending!.complete(SuggestOutcome.generated);

    await expectLater(loading, completes);
  });
}
