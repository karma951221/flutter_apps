import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/chat_history_settings.dart';

part 'chat_history_settings_state.freezed.dart';

/// 물어보기 설정의 대화 기록 섹션 — 보관 기간 · 저장된 대화 수 · 위키 색인 크기 · 위키 수.
@freezed
class ChatHistorySettingsState with _$ChatHistorySettingsState {
  @override
  final ChatRetention retention;

  /// 저장된 대화 수. 0 이면 모두 지우기 행이 꺼진다.
  @override
  final int conversationCount;

  @override
  final WikiIndexSize wikiIndexSize;

  /// 위키 메모 수. 0 이면 위키 모두 지우기 행이 꺼진다.
  @override
  final int wikiCount;

  /// 지금 크기로 만든 색인의 글자 수(색인 크기 시트 위쪽 안내).
  @override
  final int wikiIndexChars;

  const ChatHistorySettingsState({
    this.retention = ChatRetention.fallback,
    this.conversationCount = 0,
    this.wikiIndexSize = WikiIndexSize.fallback,
    this.wikiCount = 0,
    this.wikiIndexChars = 0,
  });
}
