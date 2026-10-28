import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 질문 입력칸 + 전송 버튼. [enabled] 가 false(답하는 중)면 전송 버튼을 끈다 — 입력은 계속 할 수 있다.
class ChatInput extends StatefulWidget {
  const ChatInput({required this.enabled, required this.onSend, super.key});

  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();

  /// 입력칸이 늘어나는 최대 줄 수.
  static const _maxLines = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.enabled) return;
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
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: l10n.walkChatSend,
            onPressed: widget.enabled ? _submit : null,
          ),
        ],
      ),
    );
  }
}
