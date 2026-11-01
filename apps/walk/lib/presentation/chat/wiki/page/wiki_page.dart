import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../../domain/chat/chat_history_settings.dart';
import '../../../../domain/chat/chat_settings.dart';
import '../../../../domain/chat/chat_vendor.dart';
import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/wiki_repository.dart';
import '../../../../domain/chat/usecase/chat_session.dart';
import '../../../../domain/chat/wiki/wiki_index.dart';
import '../../../settings/widget/wiki_index_size_sheet.dart';
import '../../widget/chat_vendor_icon.dart';
import '../cubit/wiki_cubit.dart';
import '../cubit/wiki_state.dart';
import '../open_wiki.dart';

enum _PageAction { deleteAll }

/// 위키 메모 목록(스펙 §3 위키 화면). 행을 누르면 메모 화면 — 거기서 [대화 보기]를 고르면
/// 그 대화 id 로 pop 한다. [openWikiPage] 로 연다(잠금 아래).
class WikiPage extends StatelessWidget {
  const WikiPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        WikiCubit(getIt<WikiRepository>(), getIt<ChatHistorySettings>()),
    child: BlocBuilder<WikiCubit, WikiState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.walkChatWikiTitle),
            actions: [
              AppOverflowMenu<_PageAction>(
                items: [
                  if (state.notes.isNotEmpty)
                    AppOverflowMenuItem(
                      value: _PageAction.deleteAll,
                      label: l10n.walkChatWikiDeleteAll,
                      icon: Icons.delete_sweep_outlined,
                      isDestructive: true,
                    ),
                ],
                onSelected: (_) => _deleteAll(context, state.notes.length),
              ),
            ],
          ),
          body: _body(context, state, l10n),
        );
      },
    ),
  );

  Widget _body(BuildContext context, WikiState state, AppLocalizations l10n) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.failed && state.notes.isEmpty) {
      return AppPlaceholder(
        icon: Icons.error_outline,
        message: l10n.walkChatWikiLoadFailed,
      );
    }
    if (state.notes.isEmpty) {
      return Column(
        children: [
          const _Notice(),
          Expanded(
            child: AppPlaceholder(
              icon: Icons.menu_book_outlined,
              message: l10n.walkChatWikiEmpty,
            ),
          ),
        ],
      );
    }
    final notIndexed = state.notIndexed;
    return ListView(
      children: [
        const _Notice(),
        if (notIndexed > 0)
          AppListTile(
            key: const Key('wiki-not-indexed'),
            title: Text(l10n.walkChatWikiNotIndexed(notIndexed)),
            onTap: () => _pickSize(context, state),
          ),
        for (final note in state.notes)
          _NoteRow(note: note, indexed: state.indexedIds.contains(note.id)),
      ],
    );
  }

  /// 색인 크기 시트 — 고르면 저장하고, 돌아오면 색인 표시를 다시 계산한다.
  Future<void> _pickSize(BuildContext context, WikiState state) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WikiCubit>();
    final settings = getIt<ChatHistorySettings>();
    final picked = await showWikiIndexSizeSheet(
      context,
      current: state.size,
      noteCount: state.notes.length,
      indexChars: buildWikiIndex(state.notes, state.size).chars,
    );
    if (picked != null) {
      try {
        await settings.setWikiIndexSize(picked);
      } on Object {
        if (context.mounted) {
          AppSnackBar.show(
            context,
            message: l10n.walkChatWikiIndexSizeFailed,
            type: AppSnackBarType.error,
          );
        }
      }
    }
    if (!cubit.isClosed) cubit.refreshSize();
  }

  Future<void> _deleteAll(BuildContext context, int count) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WikiCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatWikiDeleteAllTitle,
      content: l10n.walkChatWikiDeleteAllBody(count),
      confirmLabel: l10n.walkChatWikiDeleteAllConfirm,
    );
    if (!confirmed) return;
    try {
      await cubit.deleteAll();
    } on Object {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: l10n.walkChatWikiDeleteFailed,
          type: AppSnackBarType.error,
        );
      }
    }
  }
}

/// 맨 위 안내 한 줄 — 색인 · 본문이 어느 벤더로 가는지.
class _Notice extends StatelessWidget {
  const _Notice();

  /// 다음 질문의 벤더. 모델 목록이 없으면(target null) 연결 벤더로.
  static ChatVendor _vendor() =>
      getIt<ChatSession>().target?.vendor ??
      getIt<ChatSettings>().connectedVendor ??
      ChatVendor.anthropic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        l10n.walkChatWikiNotice(chatVendorName(l10n, _vendor())),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 메모 한 행 — 제목 · 요약 · 수정일, 색인 밖이면 표시.
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.indexed});

  final WikiNote note;
  final bool indexed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = DateFormat.yMMMd(l10n.localeName).format(note.updatedAt);
    return AppListTile(
      key: Key('wiki-note-${note.id}'),
      title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${note.summary}\n${l10n.walkChatWikiUpdated(date)}'),
      trailing: indexed
          ? null
          : Icon(
              Icons.visibility_off_outlined,
              semanticLabel: l10n.walkChatWikiNotIndexedRow,
            ),
      onTap: () async {
        final id = await openWikiNote(context, note.id);
        if (id != null && context.mounted) Navigator.of(context).pop(id);
      },
    );
  }
}
