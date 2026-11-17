import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_suggestions.freezed.dart';

/// AI 가 최근 질문으로 만든 첫 화면 추천 질문(스펙 2026-11-17).
@freezed
class ChatSuggestions with _$ChatSuggestions {
  @override
  final List<String> questions;

  /// 만든 시각.
  @override
  final DateTime generatedAt;

  /// 만들 때 본 가장 최근 질문의 시각. 이 뒤에 저장된 질문을 "새 질문"으로 센다.
  @override
  final DateTime basedOnAskedAt;

  const ChatSuggestions({
    required this.questions,
    required this.generatedAt,
    required this.basedOnAskedAt,
  });
}
