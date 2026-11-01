import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_usage_log.dart';
import '../../../domain/chat/entity/chat_usage_summary.dart';
import '../../../domain/chat/repository/chat_usage_repository.dart';
import '../../chat/widget/chat_vendor_icon.dart';
import '../cubit/chat_usage_cubit.dart';
import '../cubit/chat_usage_state.dart';
import '../widget/settings_widgets.dart';

enum _PageAction { clear }

/// 물어보기 사용량 — 달마다 질문 수 · 토큰 합계와 모델별 줄. 금액은 보이지 않는다.
/// 물어보기 설정의 사용량 행이 `pushDiaryRoute` 로 연다(잠금 아래).
class ChatUsagePage extends StatelessWidget {
  const ChatUsagePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ChatUsageCubit(getIt<ChatUsageRepository>(), getIt<Clock>())..load(),
    child: const _ChatUsageView(),
  );
}

class _ChatUsageView extends StatelessWidget {
  const _ChatUsageView();

  Future<void> _clear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatUsageCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatUsageClearTitle,
      content: l10n.walkChatUsageClearBody,
      confirmLabel: l10n.commonDelete,
    );
    if (!confirmed || cubit.isClosed) return;
    try {
      await cubit.clear();
    } on Object {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.walkChatUsageClearFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ChatUsageCubit, ChatUsageState>(
      builder: (context, state) {
        final cubit = context.read<ChatUsageCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.walkChatUsageTitle),
            actions: [
              AppOverflowMenu<_PageAction>(
                items: [
                  AppOverflowMenuItem(
                    value: _PageAction.clear,
                    label: l10n.walkChatUsageClear,
                    icon: Icons.delete_sweep_outlined,
                    isDestructive: true,
                  ),
                ],
                onSelected: (_) => _clear(context),
              ),
            ],
          ),
          body: ListView(
            children: [
              _MonthBar(
                year: state.year,
                month: state.month,
                onPrevious: cubit.canGoBack ? cubit.previousMonth : null,
                onNext: cubit.canGoForward ? cubit.nextMonth : null,
              ),
              ..._content(context, state, l10n),
              _CostNote(text: l10n.walkChatUsageCostNote),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _content(
    BuildContext context,
    ChatUsageState state,
    AppLocalizations l10n,
  ) {
    final usage = state.usage;
    if (state.loading && usage == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (usage == null) {
      return [
        AppPlaceholder(
          icon: Icons.error_outline,
          message: l10n.walkChatUsageLoadFailed,
        ),
      ];
    }
    if (usage.rows.isEmpty) {
      return [
        AppPlaceholder(
          icon: Icons.bar_chart_outlined,
          message: l10n.walkChatUsageEmpty,
        ),
      ];
    }
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final totals = usage.totals;
    return [
      for (final (key, label, value) in [
        ('questions', l10n.walkChatUsageQuestions, totals.questions),
        ('input', l10n.walkChatUsageInput, totals.inputTokens),
        ('output', l10n.walkChatUsageOutput, totals.outputTokens),
        ('cache-read', l10n.walkChatUsageCacheRead, totals.cacheReadTokens),
      ])
        AppListTile(
          key: Key('chat-usage-$key'),
          title: Text(label),
          trailing: Text(number.format(value)),
        ),
      SettingsSectionHeader(l10n.walkChatUsageByModel),
      for (final row in usage.rows) _ModelRow(row: row, number: number),
      ..._wiki(usage.wiki, l10n, number),
    ];
  }

  /// 위키 절 — 질문당 평균 색인, read_wiki 를 부른 질문 비율. 질문이 없으면 없다.
  List<Widget> _wiki(
    ChatUsageWikiStats wiki,
    AppLocalizations l10n,
    NumberFormat number,
  ) {
    if (wiki.questions == 0) return const [];
    // 평균 메모 수는 소수 한 자리까지("23.5"), 정수면 소수점 없이.
    final notes = NumberFormat.decimalPattern(l10n.localeName)
      ..maximumFractionDigits = 1;
    return [
      SettingsSectionHeader(l10n.walkChatUsageWiki),
      AppListTile(
        key: const Key('chat-usage-wiki-index'),
        title: Text(l10n.walkChatUsageWikiIndexAvg),
        trailing: Text(
          l10n.walkChatUsageWikiIndexAvgValue(
            notes.format(wiki.avgIndexNotes),
            number.format(wiki.avgIndexChars.round()),
          ),
        ),
      ),
      AppListTile(
        key: const Key('chat-usage-wiki-read'),
        title: Text(l10n.walkChatUsageWikiReadRatio),
        trailing: Text(
          l10n.walkChatUsageWikiReadRatioValue(
            number.format(wiki.questionsWithReadWiki),
            number.format(wiki.questions),
          ),
        ),
      ),
    ];
  }
}

/// ‹ 2026년 11월 › — 보관 기간(13개월)과 이번 달 밖으로는 버튼이 꺼진다.
class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.year,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final int year;
  final int month;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('chat-usage-prev'),
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.walkChatUsagePrevMonth,
            onPressed: onPrevious,
          ),
          Expanded(
            child: Text(
              DateFormat.yMMMM(l10n.localeName).format(DateTime(year, month)),
              key: const Key('chat-usage-month'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const Key('chat-usage-next'),
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.walkChatUsageNextMonth,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// `Anthropic · claude-… (· 위키 정리)` / `질문 n · 입력 n · 출력 n`.
class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.row, required this.number});

  final ChatUsageModelRow row;
  final NumberFormat number;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = StringBuffer(
      '${chatVendorName(l10n, row.vendor)} · ${row.model}',
    );
    if (row.purpose == ChatUsagePurpose.wikiDistill) {
      title.write(' · ${l10n.walkChatUsageWikiDistill}');
    }
    return AppListTile(
      title: Text(title.toString()),
      subtitle: Text(
        l10n.walkChatUsageModelLine(
          number.format(row.questions),
          number.format(row.inputTokens),
          number.format(row.outputTokens),
        ),
      ),
    );
  }
}

class _CostNote extends StatelessWidget {
  const _CostNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
