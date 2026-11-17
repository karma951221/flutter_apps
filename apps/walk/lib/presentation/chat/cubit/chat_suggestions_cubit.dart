import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/suggest/chat_suggester.dart';
import 'chat_suggestions_state.dart';

/// 빈 대화 화면의 추천 질문(스펙 2026-11-17 §3 보이기). 화면이 뜰 때 [load] 한다 —
/// 저장된 추천을 먼저 보이고, 조건이 맞으면 뒤에서 새로 만들어 바꾼다. 던지지 않는다.
class ChatSuggestionsCubit extends Cubit<ChatSuggestionsState> {
  ChatSuggestionsCubit(this._suggester) : super(const ChatSuggestionsState());

  final ChatSuggester _suggester;

  Future<void> load({String? locale}) async {
    // 대화를 모두 지웠으면 그 대화에서 나온 추천을 보이지 않는다.
    if (!await _suggester.hasQuestions()) {
      if (!isClosed) emit(const ChatSuggestionsState());
      return;
    }
    final canRefresh = await _suggester.canGenerate();
    if (isClosed) return;
    emit(state.copyWith(questions: _current, canRefresh: canRefresh));

    final outcome = await _suggester.refreshIfDue(locale: locale);
    if (isClosed || outcome != SuggestOutcome.generated) return;
    emit(state.copyWith(questions: _current));
  }

  /// 새로 만들기. 새 추천을 저장했으면 true.
  Future<bool> refresh({String? locale}) async {
    if (state.refreshing) return false;
    emit(state.copyWith(refreshing: true));
    final outcome = await _suggester.refresh(locale: locale);
    if (isClosed) return outcome == SuggestOutcome.generated;
    emit(state.copyWith(questions: _current, refreshing: false));
    return outcome == SuggestOutcome.generated;
  }

  List<String>? get _current => _suggester.current?.questions;
}
