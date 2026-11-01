import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_history_settings.dart';
import '../../../domain/chat/repository/chat_history_repository.dart';
import '../../diary/page/diary_route.dart';
import '../cubit/chat_history_settings_cubit.dart';
import '../cubit/chat_history_settings_state.dart';
import '../page/chat_usage_page.dart';
import 'settings_widgets.dart';

/// 물어보기 설정 화면에서 ChatSettingsSection 아래. 2단계가 위키 색인 크기 · 위키 모두 지우기 행을 더한다.
///
/// 대화 보관 기간 · 사용량 화면 바로가기 · 대화 모두 지우기. cubit 은 이 섹션이 소유한다.
class ChatHistorySettingsSection extends StatelessWidget {
  const ChatHistorySettingsSection({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ChatHistorySettingsCubit(
      getIt<ChatHistorySettings>(),
      getIt<ChatHistoryRepository>(),
    )..load(),
    child: const _ChatHistorySettingsView(),
  );
}

class _ChatHistorySettingsView extends StatelessWidget {
  const _ChatHistorySettingsView();

  Future<void> _pickRetention(
    BuildContext context,
    ChatRetention current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatHistorySettingsCubit>();
    final picked = await SettingsChoiceSheet.show<ChatRetention>(
      context,
      title: l10n.walkChatHistoryRetention,
      current: current,
      options: [
        for (final r in ChatRetention.values) (r, retentionLabel(l10n, r)),
      ],
    );
    if (picked == null || cubit.isClosed) return;
    try {
      await cubit.setRetention(picked);
    } on Object {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.walkChatHistoryRetentionFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _deleteAll(BuildContext context, int count) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatHistorySettingsCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatHistoryDeleteAllTitle,
      content: l10n.walkChatHistoryDeleteAllBody(count),
      confirmLabel: l10n.walkChatHistoryDeleteAllConfirm,
    );
    if (!confirmed || cubit.isClosed) return;
    try {
      await cubit.deleteAllConversations();
    } on Object {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.walkChatHistoryDeleteAllFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocBuilder<ChatHistorySettingsCubit, ChatHistorySettingsState>(
      builder: (context, state) {
        final count = state.conversationCount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(l10n.walkChatHistorySettingsHeader),
            AppListTile(
              key: const Key('chat-history-retention'),
              leading: const Icon(Icons.auto_delete_outlined),
              title: Text(l10n.walkChatHistoryRetention),
              trailing: Text(retentionLabel(l10n, state.retention)),
              onTap: () => _pickRetention(context, state.retention),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.walkChatHistoryRetentionNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            AppListTile(
              key: const Key('chat-history-usage'),
              leading: const Icon(Icons.bar_chart_outlined),
              title: Text(l10n.walkChatUsageTitle),
              onTap: () => pushDiaryRoute<void>(
                context,
                page: (_) => const ChatUsagePage(),
              ),
            ),
            AppListTile(
              key: const Key('chat-history-delete-all'),
              leading: const Icon(Icons.delete_sweep_outlined),
              title: Text(l10n.walkChatHistoryDeleteAll),
              enabled: count > 0,
              onTap: count > 0 ? () => _deleteAll(context, count) : null,
            ),
          ],
        );
      },
    );
  }

  static String retentionLabel(AppLocalizations l10n, ChatRetention r) =>
      switch (r) {
        ChatRetention.never => l10n.walkChatHistoryRetentionNever,
        ChatRetention.day30 => l10n.walkChatHistoryRetention30d,
        ChatRetention.day90 => l10n.walkChatHistoryRetention90d,
      };
}
