import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/attachment/attachment_rules.dart';
import '../../../domain/chat/attachment/chat_attachment.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/diary/entity/diary_entry.dart';
import '../widget/model_chip.dart';
import 'chat_progress.dart';

part 'chat_state.freezed.dart';

/// 채팅을 쓸 수 있는가. 키 · 동의를 읽기 전은 [checking]. [noModels] 는 키 · 동의는
/// 있는데 모델 목록을 한 번도 받지 못해 물을 모델을 정할 수 없다(스펙 §6.3).
enum ChatAccess { checking, noKey, needsConsent, noModels, ready }

enum ChatRole { user, assistant }

/// [📎] 를 막는 이유. 한 질문에 다 찼거나([perQuestion]) 이 대화의 사진 · 문서 자리가
/// 모두 없다([conversation]).
enum AttachBlock { perQuestion, conversation }

/// 첨부하지 못한 파일 하나와 그 이유. 화면이 스낵바로 보이고 consumeAttachmentNotice 로 비운다.
@freezed
class AttachmentNotice with _$AttachmentNotice {
  @override
  final String name;
  @override
  final AttachmentRejection reason;

  const AttachmentNotice({required this.name, required this.reason});
}

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

  /// [■ 멈춤]으로 끊긴 답. 받은 [text] 는 그대로 남는다.
  @override
  final bool stopped;

  /// 저장된 턴의 seq. 저장 전 · 임시 대화 · 실패한 말풍선은 null. 한 턴의 질문 · 답 말풍선이 같은 값.
  @override
  final int? seq;

  /// 답의 진행 단계 · 경과 초(assistant 말풍선만). 저장하지 않는다 — 연 대화 · 짧게 끝난
  /// 답(요약을 남기지 않을 때)은 null.
  @override
  final ChatProgress? progress;

  /// 질문에 붙은 파일(user 말풍선만). 본문은 없다.
  @override
  final List<ChatAttachmentRef> attachments;

  const ChatBubble({
    required this.role,
    required this.text,
    this.cited = const [],
    this.failure,
    this.stopped = false,
    this.seq,
    this.progress,
    this.attachments = const [],
  });

  /// 글은 남기지 않는다 — 길이와 표시만. 진행 노트도 [ChatProgressStep.toString] 이 글을 뺀다.
  @override
  String toString() =>
      'ChatBubble(role: ${role.name}, textLength: ${text.length}, '
      'cited: ${cited.length}, failure: $failure, stopped: $stopped, seq: $seq, '
      'progress: $progress, attachments: ${attachments.length})';
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

  /// 글 없이 멈춰 입력칸에 되돌릴 질문. 화면이 채운 뒤 consumeRestoredDraft 로 비운다.
  @override
  final String? restoredDraft;

  /// 지금 열린 저장 대화. 첫 턴을 저장하기 전 · 임시 대화면 null.
  @override
  final String? conversationId;

  /// 임시 대화 중(D4).
  @override
  final bool temporary;

  /// 배너에 쓰는 지금 벤더. refresh 때 세션 target 에서 읽는다.
  @override
  final ChatVendor vendor;

  /// 저장된 대화를 읽어 들이는 중(열기 · 저장된 턴 지우기). 이 동안 send 는 무시한다.
  @override
  final bool loading;

  /// 앱바 아래 모델 칩. ready 가 아니거나 모델이 없으면 null.
  @override
  final ModelChipData? model;

  /// noModels 의 원인이 잘못된 키 — [다시 시도] 대신 [설정 열기].
  @override
  final bool modelsInvalidKey;

  /// 고른 모델이 없어져 추천으로 바꿨다 — 탭이 보일 때 한 번 알리고 consume 한다.
  @override
  final bool selectionReplaced;

  /// 입력칸에 담긴, 다음 질문과 함께 보낼 첨부.
  @override
  final List<ChatAttachment> pendingAttachments;

  /// 첨부하지 못한 이유 — 화면이 한 번 알리고 비운다.
  @override
  final AttachmentNotice? attachmentNotice;

  /// [📎] 를 막는 이유. null 이면 더 붙일 수 있다. cubit 이 emit 마다 다시 센다.
  @override
  final AttachBlock? attachBlock;

  bool get canAttach => attachBlock == null;

  const ChatState({
    required this.access,
    this.bubbles = const [],
    this.busy = false,
    this.restoredDraft,
    this.conversationId,
    this.temporary = false,
    this.vendor = ChatVendor.anthropic,
    this.loading = false,
    this.model,
    this.modelsInvalidKey = false,
    this.selectionReplaced = false,
    this.pendingAttachments = const [],
    this.attachmentNotice,
    this.attachBlock,
  });

  /// 질문 · 답 글(말풍선 · 되돌린 질문)은 남기지 않는다.
  @override
  String toString() =>
      'ChatState(access: ${access.name}, bubbles: $bubbles, busy: $busy, '
      'restoredDraftLength: ${restoredDraft?.length}, '
      'conversationId: $conversationId, temporary: $temporary, '
      'vendor: ${vendor.name}, loading: $loading, model: $model, '
      'modelsInvalidKey: $modelsInvalidKey, '
      'selectionReplaced: $selectionReplaced, '
      'pendingAttachments: ${pendingAttachments.length}, '
      'attachmentNotice: ${attachmentNotice?.reason.name}, '
      'attachBlock: ${attachBlock?.name})';
}
