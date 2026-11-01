import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/chat_history_repository.dart';
import '../../../../domain/chat/repository/wiki_repository.dart';
import '../../../../domain/diary/repository/diary_repository.dart';
import '../../../diary/viewer/story_viewer_page.dart';
import '../cubit/wiki_note_cubit.dart';
import '../cubit/wiki_note_state.dart';
import '../open_wiki.dart';
import '../widget/wiki_link_text.dart';

enum _NoteAction { delete }

/// 위키 메모 하나 — 요약 · 링크 칩 본문 · 수정일 · [대화 보기] · 역링크(스펙 §3 위키 화면).
/// [대화 보기]를 고르면 출처 대화 id 로 pop 한다. 메모가 사라지면 닫힌다.
/// [openWikiNote] 로 연다(잠금 아래).
class WikiNotePage extends StatelessWidget {
  const WikiNotePage({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => WikiNoteCubit(
      getIt<WikiRepository>(),
      getIt<DiaryRepository>(),
      getIt<ChatHistoryRepository>(),
      id: id,
    ),
    child: BlocConsumer<WikiNoteCubit, WikiNoteState>(
      listenWhen: (a, b) => !a.deleted && b.deleted,
      listener: (context, _) => _close(context),
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final note = state.note;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              note?.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              AppOverflowMenu<_NoteAction>(
                items: [
                  if (note != null)
                    AppOverflowMenuItem(
                      value: _NoteAction.delete,
                      label: l10n.commonDelete,
                      icon: Icons.delete_outline,
                      isDestructive: true,
                    ),
                ],
                onSelected: (_) => _delete(context),
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
    WikiNoteState state,
    AppLocalizations l10n,
  ) {
    final note = state.note;
    if (note == null) {
      if (state.failed) {
        return AppPlaceholder(
          icon: Icons.error_outline,
          message: l10n.walkChatWikiLoadFailed,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(l10n.localeName).format(note.updatedAt);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.summary, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.md),
              WikiLinkText(
                body: note.body,
                notes: state.linkedNotes,
                entries: state.linkedEntries,
                onOpenNote: (id) => _openNote(context, id),
                onOpenEntry: (id) => _openEntry(context, note, state, id),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.walkChatWikiUpdated(date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (state.sourceExists && note.sourceConversationId != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: AppButton.text(
                label: l10n.walkChatWikiOpenConversation,
                onPressed: () =>
                    Navigator.of(context).pop(note.sourceConversationId),
              ),
            ),
          ),
        if (state.backlinks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.walkChatWikiBacklinks,
              style: theme.textTheme.titleSmall,
            ),
          ),
          for (final b in state.backlinks)
            AppListTile(
              key: Key('wiki-backlink-${b.id}'),
              title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                b.summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _openNote(context, b.id),
            ),
        ],
      ],
    );
  }

  /// 다른 메모를 연다. 거기서 [대화 보기]를 고르면 그 id 를 위로 넘긴다.
  Future<void> _openNote(BuildContext context, int id) async {
    final cubit = context.read<WikiNoteCubit>();
    final conversationId = await openWikiNote(context, id);
    if (!context.mounted) return;
    if (conversationId != null) {
      Navigator.of(context).pop(conversationId);
      return;
    }
    await cubit.reload();
  }

  /// 본문의 살아 있는 일기들을 한 그룹으로 열고 [entryId] 에서 시작한다.
  Future<void> _openEntry(
    BuildContext context,
    WikiNote note,
    WikiNoteState state,
    String entryId,
  ) async {
    final cubit = context.read<WikiNoteCubit>();
    final ids = [
      for (final link in wikiLinksIn(note.body))
        if (link case WikiDiaryLink(:final entryId))
          if (state.linkedEntries.containsKey(entryId)) entryId,
    ];
    await openStoryViewer(
      context,
      ViewerSource.entries(
        ids,
        AppLocalizations.of(context).walkChatWikiDiaryTitle,
      ),
      entryId: entryId,
    );
    await cubit.reload();
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WikiNoteCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatWikiNoteDeleteTitle,
      content: l10n.walkChatWikiNoteDeleteBody,
      confirmLabel: l10n.commonDelete,
    );
    if (!confirmed) return;
    try {
      await cubit.delete();
    } on Object {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: l10n.walkChatWikiDeleteFailed,
          type: AppSnackBarType.error,
        );
      }
      return;
    }
    if (context.mounted) _close(context);
  }

  /// 이 화면을 닫는다 — 이미 닫히는 중이면 그대로, 위에 다른 화면이 있으면 이 화면만 뺀다.
  static void _close(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    if (route.isCurrent) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).removeRoute(route);
    }
  }
}
