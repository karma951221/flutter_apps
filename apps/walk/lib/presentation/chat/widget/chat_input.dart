import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/attachment/chat_attachment.dart';
import 'attachment_chip.dart';

/// 질문 입력칸 + 전송 버튼. [busy](답하는 중)면 전송 자리에 [■ 멈춤] — 입력은 계속 할 수 있다.
/// [enabled] 가 false 면(저장된 대화를 읽는 중) 입력칸과 전송이 꺼져 보인다.
/// [preparing] 이면(보내기 전 첨부 사본을 넣는 중) 전송 · 첨부 빼기만 꺼진다 — 글은 계속 쓴다.
///
/// [restoredDraft] 가 새로 오면(글 없이 멈춰 되돌린 질문) 비어 있는 입력칸만 채우고
/// [onDraftRestored] 를 부른다. 쓰던 글이 있으면 덮어쓰지 않는다.
///
/// [onAttach] 가 있으면 입력칸 왼쪽에 [📎]. [canAttach] 가 false 면 꺼지고 툴팁이
/// [attachBlockedReason]. 담긴 [attachments] 는 입력칸 위에 칩(✕ 로 빼기)으로 보이고,
/// 첨부가 있으면 글이 비어도 보낸다(빈 글 그대로 [onSend]).
class ChatInput extends StatefulWidget {
  const ChatInput({
    required this.busy,
    required this.onSend,
    required this.onStop,
    this.restoredDraft,
    this.onDraftRestored,
    this.enabled = true,
    this.preparing = false,
    this.attachments = const [],
    this.onRemoveAttachment,
    this.onAttach,
    this.canAttach = true,
    this.attachBlockedReason,
    super.key,
  });

  final bool busy;

  /// false 면 입력 · 전송을 받지 않는다.
  final bool enabled;

  /// true 면 전송 · 첨부 빼기를 받지 않는다(입력칸 글은 비우지 않는다).
  final bool preparing;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;

  /// 입력칸에 되돌릴 질문.
  final String? restoredDraft;

  /// [restoredDraft] 를 처리했다(채웠거나 덮어쓰지 않기로 했다).
  final VoidCallback? onDraftRestored;

  /// 다음 질문과 함께 보낼 첨부.
  final List<ChatAttachmentRef> attachments;

  /// 칩의 ✕ — 그 첨부의 index.
  final ValueChanged<int>? onRemoveAttachment;

  /// [📎]. null 이면 버튼이 없다.
  final VoidCallback? onAttach;

  final bool canAttach;

  /// [canAttach] 가 false 일 때 [📎] 툴팁.
  final String? attachBlockedReason;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();

  /// 입력칸이 늘어나는 최대 줄 수.
  static const _maxLines = 4;

  @override
  void initState() {
    super.initState();
    _restore(widget.restoredDraft);
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.restoredDraft != oldWidget.restoredDraft) {
      _restore(widget.restoredDraft);
    }
  }

  /// 키보드는 열지 않는다 — 포커스를 요청하지 않는다.
  void _restore(String? draft) {
    if (draft == null) return;
    if (_controller.text.isEmpty) {
      _controller.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDraftRestored?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.busy || !widget.enabled || widget.preparing) return;
    final text = _controller.text.trim();
    if (text.isEmpty && widget.attachments.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onAttach = widget.onAttach;
    final onRemove = widget.onRemoveAttachment;
    final row = Row(
      children: [
        if (onAttach != null)
          IconButton(
            icon: const Icon(Icons.attach_file),
            tooltip: widget.canAttach
                ? l10n.walkChatAttach
                : widget.attachBlockedReason ?? l10n.walkChatAttach,
            onPressed: widget.enabled && widget.canAttach ? onAttach : null,
          ),
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            minLines: 1,
            maxLines: _maxLines,
            textInputAction: TextInputAction.send,
            decoration: InputDecoration(hintText: l10n.walkChatInputHint),
            onSubmitted: (_) => _submit(),
          ),
        ),
        if (widget.busy)
          IconButton(
            icon: const Icon(Icons.stop_rounded),
            tooltip: l10n.walkChatStop,
            onPressed: widget.onStop,
          )
        else
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: l10n.walkChatSend,
            onPressed: widget.enabled && !widget.preparing ? _submit : null,
          ),
      ],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        onAttach == null ? AppSpacing.md : AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: widget.attachments.isEmpty
          ? row
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final (i, a) in widget.attachments.indexed)
                        AttachmentChip.of(
                          a,
                          key: ValueKey('pending-attachment-$i'),
                          onRemove:
                              onRemove == null ||
                                  !widget.enabled ||
                                  widget.preparing
                              ? null
                              : () => onRemove(i),
                        ),
                    ],
                  ),
                ),
                row,
              ],
            ),
    );
  }
}
