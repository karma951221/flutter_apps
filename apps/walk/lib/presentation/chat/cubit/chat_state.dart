import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/diary/entity/diary_entry.dart';

part 'chat_state.freezed.dart';

/// 채팅을 쓸 수 있는가. 키 · 동의를 읽기 전은 [checking].
enum ChatAccess { checking, noKey, needsConsent, ready }

enum ChatRole { user, assistant }

/// 말풍선 하나. assistant 말풍선은 답이 흘러나오는 동안 [text] 가 자란다.
@freezed
class ChatBubble with _$ChatBubble {
  @override
  final ChatRole role;

  @override
  final String text;

  /// 답이 근거로 쓴 일기 기록. 휴지통 · 없는 기록은 뺀다.
  @override
  final List<DiaryEntry> cited;

  /// 답을 끝까지 받지 못했다. 이미 받은 [text] 는 그대로 둔다.
  @override
  final ChatFailure? failure;

  const ChatBubble({
    required this.role,
    required this.text,
    this.cited = const [],
    this.failure,
  });
}

@freezed
class ChatState with _$ChatState {
  @override
  final ChatAccess access;

  @override
  final List<ChatBubble> bubbles;

  /// 답을 받는 중.
  @override
  final bool busy;

  /// 지금 실행 중인 기록 도구 이름. 글이 다시 흘러나오면 비운다.
  @override
  final String? activeTool;

  const ChatState({
    required this.access,
    this.bubbles = const [],
    this.busy = false,
    this.activeTool,
  });
}
