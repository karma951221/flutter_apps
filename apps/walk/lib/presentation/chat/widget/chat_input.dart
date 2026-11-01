import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 질문 입력칸 + 전송 버튼. [busy](답하는 중)면 전송 자리에 [■ 멈춤] — 입력은 계속 할 수 있다.
///
/// [restoredDraft] 가 새로 오면(글 없이 멈춰 되돌린 질문) 비어 있는 입력칸만 채우고
/// [onDraftRestored] 를 부른다. 쓰던 글이 있으면 덮어쓰지 않는다.
class ChatInput extends StatefulWidget {
  const ChatInput({
    required this.busy,
    required this.onSend,
    required this.onStop,
    this.restoredDraft,
    this.onDraftRestored,
    super.key,
  });

  final bool busy;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;

  /// 입력칸에 되돌릴 질문.
  final String? restoredDraft;

  /// [restoredDraft] 를 처리했다(채웠거나 덮어쓰지 않기로 했다).
  final VoidCallback? onDraftRestored;

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
    if (widget.busy) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
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
              onPressed: _submit,
            ),
        ],
      ),
    );
  }
}
