import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_style_settings.dart';

/// 말투 이름. 직접 입력이면 적은 한 줄(비었으면 '직접 입력').
String chatToneLabel(AppLocalizations l10n, ChatTone tone, String custom) =>
    switch (tone) {
      ChatTone.standard => l10n.walkChatToneStandard,
      ChatTone.warm => l10n.walkChatToneWarm,
      ChatTone.casual => l10n.walkChatToneCasual,
      ChatTone.terse => l10n.walkChatToneTerse,
      ChatTone.custom =>
        custom.trim().isEmpty ? l10n.walkChatToneCustom : custom.trim(),
    };

/// '말투' 행 — 지금 말투를 보이고, 누르면 고르기 시트. 대화 설정 시트와 물어보기 설정이 같이 쓴다.
/// 저장은 [style] 에 바로 한다(다음 질문부터 system 프롬프트에 반영).
class ChatToneTile extends StatefulWidget {
  const ChatToneTile({required this.style, this.enabled = true, super.key});

  final ChatStyleSettings style;
  final bool enabled;

  @override
  State<ChatToneTile> createState() => _ChatToneTileState();
}

class _ChatToneTileState extends State<ChatToneTile> {
  Future<void> _pick() async {
    await showChatToneSheet(context, widget.style);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppListTile(
      key: const Key('chat-tone-tile'),
      enabled: widget.enabled,
      leading: const Icon(Icons.record_voice_over_outlined),
      title: Text(l10n.walkChatToneTitle),
      subtitle: Text(
        chatToneLabel(l10n, widget.style.tone, widget.style.customTone),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => unawaited(_pick()),
    );
  }
}

/// 말투 고르기 시트. 고르면 저장하고 닫는다. '직접 입력'은 한 줄 입력 다이얼로그를 거친다
/// (취소하면 아무것도 바꾸지 않는다).
Future<void> showChatToneSheet(BuildContext context, ChatStyleSettings style) =>
    showAppSheet<void>(
      context: context,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final current = style.tone;
        Future<void> choose(ChatTone tone) async {
          if (tone == ChatTone.custom) {
            final line = await showCustomToneDialog(
              sheetContext,
              current: style.customTone,
            );
            if (line == null) return;
            await style.setTone(ChatTone.custom, custom: line);
          } else {
            await style.setTone(tone);
          }
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        }

        return AppSheetScaffold(
          title: l10n.walkChatToneTitle,
          description: l10n.walkChatToneSheetHint,
          children: [
            for (final tone in ChatTone.values)
              AppSelectTile(
                key: Key('chat-tone-${tone.name}'),
                title: Text(
                  tone == ChatTone.custom
                      ? l10n.walkChatToneCustom
                      : chatToneLabel(l10n, tone, ''),
                ),
                subtitle: tone == ChatTone.custom && style.customTone.isNotEmpty
                    ? Text(
                        style.customTone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                selected: tone == current,
                onTap: () => unawaited(choose(tone)),
              ),
          ],
        );
      },
    );

/// 직접 입력 말투 한 줄. 저장이면 정리한 글, 취소 · 빈 글이면 null.
Future<String?> showCustomToneDialog(
  BuildContext context, {
  required String current,
}) async {
  final line = await showDialog<String>(
    context: context,
    builder: (_) => _CustomToneDialog(current: current),
  );
  final normalized = ChatTone.normalizeCustom(line ?? '');
  return normalized.isEmpty ? null : normalized;
}

class _CustomToneDialog extends StatefulWidget {
  const _CustomToneDialog({required this.current});

  final String current;

  @override
  State<_CustomToneDialog> createState() => _CustomToneDialogState();
}

class _CustomToneDialogState extends State<_CustomToneDialog> {
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
      title: Text(l10n.walkChatToneCustomTitle),
      content: TextField(
        key: const Key('chat-tone-custom-field'),
        controller: _controller,
        autofocus: true,
        maxLength: ChatTone.maxCustomChars,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: l10n.walkChatToneCustomHint),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        AppButton.text(
          label: l10n.commonCancel,
          compact: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          key: const Key('chat-tone-custom-save'),
          label: l10n.commonSave,
          compact: true,
          onPressed: _save,
        ),
      ],
    );
  }
}
