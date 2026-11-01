import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/entity/conversation.dart';

part 'chat_history_state.freezed.dart';

/// 저장된 물어보기 대화 목록.
@freezed
class ChatHistoryState with _$ChatHistoryState {
  /// 첫 목록을 아직 받지 못했다.
  @override
  final bool loading;

  /// updatedAt 최근 순.
  @override
  final List<Conversation> conversations;

  /// 목록을 읽지 못했다(스트림 오류).
  @override
  final bool failed;

  const ChatHistoryState({
    this.loading = true,
    this.conversations = const [],
    this.failed = false,
  });
}
