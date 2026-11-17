import 'dart:async';

import 'package:walk/domain/chat/suggest/chat_suggester.dart';
import 'package:walk/domain/chat/suggest/chat_suggestions.dart';

/// 값을 직접 정하는 [ChatSuggester]. 기본은 질문 있음 · 만들 수 있음 · 추천 없음 · 저절로는 건너뜀.
class FakeChatSuggester implements ChatSuggester {
  @override
  ChatSuggestions? current;

  bool questions = true;
  bool ready = true;

  /// refreshIfDue · refresh 가 기다릴 것. 끝나면 [next] 를 저장한 것으로 본다.
  Completer<SuggestOutcome>? pending;
  ChatSuggestions? next;
  SuggestOutcome dueOutcome = SuggestOutcome.skipped;
  SuggestOutcome refreshOutcome = SuggestOutcome.generated;
  final locales = <String?>[];
  int refreshCalls = 0;

  @override
  Future<bool> hasQuestions() async => questions;

  @override
  Future<bool> canGenerate() async => ready;

  Future<SuggestOutcome> _finish(SuggestOutcome outcome) async {
    final waiting = pending;
    final result = waiting == null ? outcome : await waiting.future;
    if (result == SuggestOutcome.generated) current = next;
    return result;
  }

  @override
  Future<SuggestOutcome> refreshIfDue({String? locale}) {
    locales.add(locale);
    return _finish(dueOutcome);
  }

  @override
  Future<SuggestOutcome> refresh({String? locale}) {
    refreshCalls++;
    return _finish(refreshOutcome);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
