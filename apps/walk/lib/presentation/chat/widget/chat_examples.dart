import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/suggest/chat_suggester.dart';
import '../cubit/chat_suggestions_cubit.dart';
import '../cubit/chat_suggestions_state.dart';

/// 대화가 비었을 때의 추천 질문 영역. 뜰 때마다 [ChatSuggestionsCubit.load] 한다 —
/// 저장된 AI 추천(없으면 기본 예시)을 보이고, 조건이 맞으면 뒤에서 새로 만든다.
class ChatSuggestionArea extends StatelessWidget {
  const ChatSuggestionArea({required this.onAsk, super.key});

  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) {
        final cubit = ChatSuggestionsCubit(getIt<ChatSuggester>());
        unawaited(cubit.load(locale: locale));
        return cubit;
      },
      child: BlocBuilder<ChatSuggestionsCubit, ChatSuggestionsState>(
        builder: (context, state) => ChatExamples(
          onAsk: onAsk,
          suggestions: state.questions,
          canRefresh: state.canRefresh,
          refreshing: state.refreshing,
          onRefresh: () => unawaited(_refresh(context)),
        ),
      ),
    );
  }

  static Future<void> _refresh(BuildContext context) async {
    final cubit = context.read<ChatSuggestionsCubit>();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final ok = await cubit.refresh(locale: locale);
    if (ok || !context.mounted) return;
    AppSnackBar.show(
      context,
      message: l10n.walkChatSuggestFailed,
      type: AppSnackBarType.error,
    );
  }
}

/// 대화가 비었을 때: 안내 한 줄 + 질문 칩. 누르면 바로 보낸다.
///
/// [suggestions] 가 있으면 AI 추천과 작은 안내, 없으면 기본 예시 질문 3개.
/// [canRefresh] 면 칩 아래에 새로 만들기 버튼(도는 동안 진행 표시).
class ChatExamples extends StatelessWidget {
  const ChatExamples({
    required this.onAsk,
    this.suggestions,
    this.canRefresh = false,
    this.refreshing = false,
    this.onRefresh,
    super.key,
  });

  final ValueChanged<String> onAsk;
  final List<String>? suggestions;
  final bool canRefresh;
  final bool refreshing;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ai = suggestions;
    final questions =
        ai ??
        [
          l10n.walkChatExampleYesterday,
          l10n.walkChatExampleAte,
          l10n.walkChatExampleWake,
        ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: AppSpacing.xl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.walkChatEmptyPrompt,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (ai != null) ...[
              Text(
                l10n.walkChatSuggestCaption,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final q in questions)
                  ActionChip(label: Text(q), onPressed: () => onAsk(q)),
              ],
            ),
            if (canRefresh) ...[
              const SizedBox(height: AppSpacing.sm),
              if (refreshing)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                  child: SizedBox.square(
                    dimension: AppSpacing.lg,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  tooltip: l10n.walkChatSuggestRefresh,
                  icon: const Icon(Icons.refresh),
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: onRefresh,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
