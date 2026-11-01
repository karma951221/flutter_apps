import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/repository/chat_history_repository.dart';
import '../../../../domain/chat/repository/wiki_repository.dart';
import '../../../../domain/chat/usecase/chat_session.dart';
import '../../../../domain/chat/usecase/wiki_distiller.dart';
import '../../../../domain/diary/repository/diary_repository.dart';
import '../../../lock/cubit/diary_lock_cubit.dart';
import '../../../lock/cubit/diary_lock_state.dart';
import '../../widget/chat_failure_text.dart';
import '../cubit/wiki_distill_cubit.dart';
import '../cubit/wiki_distill_state.dart';
import '../cubit/wiki_edit_state.dart';
import '../open_wiki.dart';
import 'wiki_link_text.dart';

/// [위키로 정리] 후보 시트(D6). 다 처리하거나 닫으면 끝 — 남은 후보는 버린다.
///
/// 모달이라 잠금 게이트 밖이다 — [DiaryLockCubit] 이 잠기면 스스로 닫힌다(W9).
/// [context] 위에 [DiaryLockCubit] 가 있어야 한다. 요청 중에 닫으면 요청을 끊는다.
Future<void> showWikiCandidatesSheet(
  BuildContext context, {
  required String conversationId,
  required ChatTarget? target,
}) {
  final lock = context.read<DiaryLockCubit>();
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: lock),
        BlocProvider(
          create: (_) => WikiDistillCubit(
            getIt<WikiDistiller>(),
            getIt<WikiRepository>(),
            getIt<ChatHistoryRepository>(),
            getIt<DiaryRepository>(),
            conversationId: conversationId,
            target: target,
          ),
        ),
      ],
      child: const _WikiCandidatesSheet(),
    ),
  );
}

class _WikiCandidatesSheet extends StatelessWidget {
  const _WikiCandidatesSheet();

  /// 시트를 닫는다. [고쳐서 저장] 편집 화면이 위에 있으면(잠겼을 때) 그 아래의 시트만 뺀다.
  static void _close(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    final navigator = Navigator.of(context);
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<DiaryLockCubit, DiaryLockState>(
        listenWhen: (_, b) => b is! LockUnlocked,
        listener: (context, _) => _close(context),
      ),
      BlocListener<WikiDistillCubit, WikiDistillState>(
        listenWhen: (_, _) => context.read<WikiDistillCubit>().allHandled,
        listener: (context, _) {
          final cubit = context.read<WikiDistillCubit>();
          AppSnackBar.show(
            context,
            message: AppLocalizations.of(
              context,
            ).walkChatWikiDistillDone(cubit.savedCount),
          );
          _close(context);
        },
      ),
    ],
    child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 1,
      builder: (context, scroll) =>
          BlocBuilder<WikiDistillCubit, WikiDistillState>(
            builder: (context, state) => switch (state) {
              WikiDistillLoading() => _Loading(scroll: scroll),
              WikiDistillReady(:final items) when items.isEmpty => _Message(
                scroll: scroll,
                icon: Icons.menu_book_outlined,
                message: AppLocalizations.of(context).walkChatWikiDistillNone,
              ),
              WikiDistillReady() => _Candidates(scroll: scroll, state: state),
              WikiDistillFailedState(:final failure) => _Message(
                scroll: scroll,
                icon: Icons.error_outline,
                message: chatFailureText(AppLocalizations.of(context), failure),
              ),
              WikiDistillUnparsableState() => _Message(
                scroll: scroll,
                icon: Icons.error_outline,
                message: AppLocalizations.of(
                  context,
                ).walkChatWikiDistillUnparsable,
              ),
            },
          ),
    ),
  );
}

/// 정리하는 동안. [취소]로 닫으면 cubit 이 닫히며 요청을 끊는다.
class _Loading extends StatelessWidget {
  const _Loading({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.walkChatWikiDistilling,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton.text(
          key: const Key('wiki-distill-cancel'),
          label: l10n.commonCancel,
          onPressed: () => _WikiCandidatesSheet._close(context),
        ),
      ],
    );
  }
}

/// 빈 결과 · 실패 안내와 [닫기].
class _Message extends StatelessWidget {
  const _Message({
    required this.scroll,
    required this.icon,
    required this.message,
  });

  final ScrollController scroll;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => ListView(
    controller: scroll,
    children: [
      AppPlaceholder(
        icon: icon,
        message: message,
        actionLabel: AppLocalizations.of(context).walkChatWikiDistillClose,
        onAction: () => _WikiCandidatesSheet._close(context),
      ),
    ],
  );
}

class _Candidates extends StatelessWidget {
  const _Candidates({required this.scroll, required this.state});

  final ScrollController scroll;
  final WikiDistillReady state;

  @override
  Widget build(BuildContext context) => ListView.separated(
    controller: scroll,
    padding: const EdgeInsets.all(AppSpacing.md),
    itemCount: state.items.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (context, i) => _CandidateCard(index: i, state: state),
  );
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.index, required this.state});

  final int index;
  final WikiDistillReady state;

  Future<void> _save(BuildContext context) async {
    final cubit = context.read<WikiDistillCubit>();
    try {
      await cubit.save(index);
    } on Object {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: AppLocalizations.of(context).walkChatWikiErrorSave,
        type: AppSnackBarType.error,
      );
    }
  }

  /// [고쳐서 저장] — 후보 값으로 편집 화면. 저장하면 이 카드는 '저장함'.
  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<WikiDistillCubit>();
    final seed = switch (state.items[index].candidate) {
      WikiCreateCandidate(:final title, :final summary, :final body) =>
        WikiEditSeed(
          title: title,
          summary: summary,
          body: body,
          sourceConversationId: cubit.conversationId,
          suggestedEntryIds: state.citedEntryIds,
        ),
      WikiUpdateCandidate(
        :final id,
        :final title,
        :final summary,
        :final body,
      ) =>
        WikiEditSeed(
          id: id,
          title: title,
          summary: summary,
          body: body,
          sourceConversationId:
              state.items[index].current?.sourceConversationId,
          suggestedEntryIds: state.citedEntryIds,
        ),
    };
    final saved = await openWikiEditor(context, seed);
    if (saved != null && !cubit.isClosed) cubit.markSaved(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final item = state.items[index];
    final candidate = item.candidate;
    final cubit = context.read<WikiDistillCubit>();
    final key = Key('wiki-candidate-$index');
    if (item.status != CandidateStatus.pending) {
      return Card(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                item.status == CandidateStatus.saved
                    ? Icons.check_circle_outline
                    : Icons.remove_circle_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  candidate.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                item.status == CandidateStatus.saved
                    ? l10n.walkChatWikiCandidateSavedLabel
                    : l10n.walkChatWikiCandidateDiscardedLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final label = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.primary,
    );
    final section = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget body(String text) => WikiLinkText(
      body: text,
      notes: state.notes,
      entries: state.entries,
      onOpenNote: null,
      onOpenEntry: null,
    );
    return Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(switch (candidate) {
              WikiCreateCandidate() => l10n.walkChatWikiCandidateNew,
              WikiUpdateCandidate(:final id) =>
                l10n.walkChatWikiCandidateUpdate(id),
            }, style: label),
            const SizedBox(height: AppSpacing.xs),
            Text(candidate.title, style: theme.textTheme.titleMedium),
            Text(
              candidate.summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (candidate is WikiUpdateCandidate) ...[
              Text(l10n.walkChatWikiCandidateCurrent, style: section),
              if (item.current case final current?) body(current.body),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.walkChatWikiCandidateProposed, style: section),
            ],
            body(candidate.body),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: l10n.commonSave,
              onPressed: () => unawaited(_save(context)),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton.secondary(
              label: l10n.walkChatWikiCandidateEdit,
              onPressed: () => unawaited(_edit(context)),
            ),
            AppButton.text(
              label: l10n.walkChatWikiCandidateDiscard,
              onPressed: () => cubit.discard(index),
            ),
          ],
        ),
      ),
    );
  }
}
