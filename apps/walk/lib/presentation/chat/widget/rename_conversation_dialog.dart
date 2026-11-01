import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 대화 이름 바꾸기 — [current] 를 채운 입력 다이얼로그. 저장이면 trim 한 글, 취소 · 빈 글이면 null.
///
/// 공통 위젯에 입력 다이얼로그가 없어 이 feature 에 둔다. 위키 2단계(메모 제목)에서 다시 쓰게
/// 되면 `design_system` 으로 승격을 검토한다.
Future<String?> showRenameConversationDialog(
  BuildContext context, {
  required String current,
}) async {
  final title = await showDialog<String>(
    context: context,
    builder: (_) => _RenameConversationDialog(current: current),
  );
  final trimmed = title?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

class _RenameConversationDialog extends StatefulWidget {
  const _RenameConversationDialog({required this.current});

  final String current;

  @override
  State<_RenameConversationDialog> createState() =>
      _RenameConversationDialogState();
}

class _RenameConversationDialogState extends State<_RenameConversationDialog> {
  late final _controller = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.walkChatHistoryRename),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: l10n.walkChatHistoryRenameHint),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        AppButton.text(
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.text(label: l10n.commonSave, onPressed: _save),
      ],
    );
  }
}
