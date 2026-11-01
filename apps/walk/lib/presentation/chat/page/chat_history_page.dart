import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/entity/conversation.dart';
import '../../../domain/chat/repository/chat_history_repository.dart';
import '../cubit/chat_history_cubit.dart';
import '../cubit/chat_history_state.dart';
import '../widget/rename_conversation_dialog.dart';

enum _RowAction { rename, delete }

enum _PageAction { deleteAll }

/// 저장된 대화 목록. 행을 누르면 그 id 로 pop 한다 — 여는 쪽(ChatTab)이 cubit.open 한다.
/// `pushDiaryRoute<String>` 로 연다(잠금 아래).
class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ChatHistoryCubit(getIt<ChatHistoryRepository>()),
    child: BlocBuilder<ChatHistoryCubit, ChatHistoryState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.walkChatHistoryTitle),
            actions: [
              AppOverflowMenu<_PageAction>(
                items: [
                  if (state.conversations.isNotEmpty)
                    AppOverflowMenuItem(
                      value: _PageAction.deleteAll,
                      label: l10n.walkChatHistoryDeleteAll,
                      icon: Icons.delete_sweep_outlined,
                      isDestructive: true,
                    ),
                ],
                onSelected: (_) =>
                    _deleteAll(context, state.conversations.length),
              ),
            ],
          ),
          body: _body(context, state, l10n),
        );
      },
    ),
  );

  Widget _body(
    BuildContext context,
    ChatHistoryState state,
    AppLocalizations l10n,
  ) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.conversations.isEmpty) {
      return AppPlaceholder(
        icon: Icons.forum_outlined,
        message: l10n.walkChatHistoryEmpty,
      );
    }
    final now = getIt<Clock>().now();
    return ListView.builder(
      itemCount: state.conversations.length,
      itemBuilder: (context, i) =>
          _ConversationRow(conversation: state.conversations[i], now: now),
    );
  }

  Future<void> _deleteAll(BuildContext context, int count) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatHistoryCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatHistoryDeleteAllTitle,
      content: l10n.walkChatHistoryDeleteAllBody(count),
      confirmLabel: l10n.walkChatHistoryDeleteAllConfirm,
    );
    if (!confirmed) return;
    await cubit.deleteAll();
  }
}

/// 대화 한 행 — 제목 · `시각 · 질문 n개` · 이름 바꾸기 / 삭제 메뉴.
class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.now});

  final Conversation conversation;

  /// 오늘 판단의 기준(Clock).
  final DateTime now;

  /// 오늘이면 `14:05`, 아니면 날짜.
  String _time(String locale) {
    final at = conversation.updatedAt;
    final today =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return today
        ? DateFormat.Hm(locale).format(at)
        : DateFormat.yMMMd(locale).format(at);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppListTile(
      key: Key('chat-history-${conversation.id}'),
      title: Text(
        conversation.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_time(l10n.localeName)} · '
        '${l10n.walkChatHistoryTurns(conversation.turnCount)}',
      ),
      trailing: AppOverflowMenu<_RowAction>(
        items: [
          AppOverflowMenuItem(
            value: _RowAction.rename,
            label: l10n.walkChatHistoryRename,
            icon: Icons.edit_outlined,
          ),
          AppOverflowMenuItem(
            value: _RowAction.delete,
            label: l10n.commonDelete,
            icon: Icons.delete_outline,
            isDestructive: true,
          ),
        ],
        onSelected: (action) => switch (action) {
          _RowAction.rename => _rename(context),
          _RowAction.delete => _delete(context),
        },
      ),
      onTap: () => Navigator.of(context).pop(conversation.id),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final cubit = context.read<ChatHistoryCubit>();
    final title = await showRenameConversationDialog(
      context,
      current: conversation.title,
    );
    if (title == null || title == conversation.title) return;
    await cubit.rename(conversation.id, title);
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatHistoryCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatHistoryDeleteTitle,
      content: l10n.walkChatHistoryDeleteBody,
      confirmLabel: l10n.commonDelete,
    );
    if (!confirmed) return;
    await cubit.delete(conversation.id);
  }
}
