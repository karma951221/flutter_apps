import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_settings.dart';
import '../cubit/chat_settings_cubit.dart';
import '../cubit/chat_settings_state.dart';

/// 물어보기 설정의 섹션 — Anthropic API 키(보안 저장소)와 데이터 전송 안내.
class ChatSettingsSection extends StatelessWidget {
  const ChatSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatSettingsCubit(getIt<ChatSettings>())..load(),
      child: const _ChatSettingsView(),
    );
  }
}

class _ChatSettingsView extends StatelessWidget {
  const _ChatSettingsView();

  Future<void> _editKey(BuildContext context) async {
    final cubit = context.read<ChatSettingsCubit>();
    final key = await showDialog<String>(
      context: context,
      builder: (_) => const _KeyDialog(),
    );
    if (key == null) return;
    final saved = await cubit.save(key);
    if (!saved && context.mounted) _showWriteFailed(context);
  }

  void _showWriteFailed(BuildContext context) {
    AppSnackBar.show(
      context,
      message: AppLocalizations.of(context).walkChatSettingsSaveFailed,
      type: AppSnackBarType.error,
    );
  }

  Future<void> _deleteKey(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatSettingsCubit>();
    final ok = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatSettingsDeleteTitle,
      content: l10n.walkChatSettingsDeleteBody,
      confirmLabel: l10n.walkChatSettingsDelete,
    );
    if (!ok) return;
    final deleted = await cubit.delete();
    if (!deleted && context.mounted) _showWriteFailed(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocBuilder<ChatSettingsCubit, ChatSettingsState>(
      builder: (context, state) {
        final hint = state.connection?.keyPreview;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.walkChatSettings,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            AppListTile(
              key: const Key('settings-chat-key'),
              leading: const Icon(Icons.key_outlined),
              title: Text(l10n.walkChatSettingsKey),
              subtitle: hint == null ? null : Text(l10n.walkChatSettingsChange),
              trailing: Text(hint ?? l10n.walkChatSettingsAddKey),
              onTap: state.loading ? null : () => _editKey(context),
            ),
            if (hint != null)
              AppListTile(
                key: const Key('settings-chat-delete'),
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.walkChatSettingsDelete),
                onTap: () => _deleteKey(context),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.walkChatSettingsNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 가려진 입력칸. 저장하면 입력한 문자열을, 취소하면 null 을 돌려준다.
class _KeyDialog extends StatefulWidget {
  const _KeyDialog();

  @override
  State<_KeyDialog> createState() => _KeyDialogState();
}

class _KeyDialogState extends State<_KeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.walkChatSettingsKeyDialogTitle),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(hintText: 'sk-ant-…'),
      ),
      actions: [
        AppButton.text(
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton.text(
          key: const Key('chat-key-save'),
          label: l10n.walkChatSettingsSave,
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    );
  }
}
