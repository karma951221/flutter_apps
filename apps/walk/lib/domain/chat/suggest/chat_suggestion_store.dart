import 'chat_suggestions.dart';

/// 추천 질문과 마지막 생성 시도 시각을 기기에 둔다. 백업 대상이 아니다.
abstract interface class ChatSuggestionStore {
  /// 저장된 추천. 없거나 읽을 수 없으면 null.
  ChatSuggestions? get current;

  Future<void> save(ChatSuggestions value);

  /// 마지막 생성 시도(성공 · 실패 모두) 시각.
  DateTime? get triedAt;

  Future<void> setTriedAt(DateTime value);
}
