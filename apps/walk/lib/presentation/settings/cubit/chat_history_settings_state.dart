import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/chat_history_settings.dart';

part 'chat_history_settings_state.freezed.dart';

/// 물어보기 설정의 대화 기록 섹션 — 보관 기간 · 저장된 대화 수.
@freezed
class ChatHistorySettingsState with _$ChatHistorySettingsState {
  @override
  final ChatRetention retention;

  /// 저장된 대화 수. 0 이면 모두 지우기 행이 꺼진다.
  @override
  final int conversationCount;

  const ChatHistorySettingsState({
    this.retention = ChatRetention.fallback,
    this.conversationCount = 0,
  });
}
