import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_suggestions_state.freezed.dart';

/// 빈 대화 화면의 추천 질문.
@freezed
class ChatSuggestionsState with _$ChatSuggestionsState {
  /// AI 추천. null 이면 기본 예시 질문을 보인다.
  @override
  final List<String>? questions;

  /// 새로 만들기를 보일까(키 · 동의 · 질문 3개).
  @override
  final bool canRefresh;

  /// 새로 만들기가 도는 중.
  @override
  final bool refreshing;

  const ChatSuggestionsState({
    this.questions,
    this.canRefresh = false,
    this.refreshing = false,
  });
}
