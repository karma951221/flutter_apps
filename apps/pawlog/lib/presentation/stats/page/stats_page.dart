import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../theme/pawlog_theme.dart';
import '../cubit/stats_cubit.dart';
import '../cubit/stats_state.dart';
import '../widget/distance_bar_chart.dart';
import '../widget/period_summary_view.dart';
import '../widget/period_switcher.dart';
import '../widget/walk_records_view.dart';

/// 주 · 월 산책 통계. 라우팅은 모르고 상세로 가는 콜백만 받는다.
class StatsPage extends StatelessWidget {
  const StatsPage({required this.onOpenWalk, super.key});

  final ValueChanged<String> onOpenWalk;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<StatsCubit>()..start(),
    child: _StatsView(onOpenWalk: onOpenWalk),
  );
}

class _StatsView extends StatelessWidget {
  const _StatsView({required this.onOpenWalk});

  final ValueChanged<String> onOpenWalk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<StatsCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkStatsTitle)),
      body: SafeArea(
        child: BlocBuilder<StatsCubit, StatsState>(
          builder: (context, state) => switch (state) {
            StatsLoading() => const Center(child: CircularProgressIndicator()),
            StatsFailure(:final failure) => Center(
              child: AppPlaceholder(
                message: failure.localizedMessage(context),
                actionLabel: l10n.commonRetry,
                actionKey: const Key('stats-retry'),
                onAction: cubit.retry,
              ),
            ),
            StatsLoaded(isEmpty: true) => Center(
              child: AppPlaceholder(
                message: l10n.walkStatsEmptyTitle,
                description: l10n.walkStatsEmptyMessage,
              ),
            ),
            StatsLoaded(
              :final stats,
              :final records,
              :final canShowPrevious,
              :final canShowNext,
              :final now,
            ) =>
              ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: PawlogSize.gutter,
                  vertical: PawlogSpacing.lg,
                ),
                children: [
                  PeriodSwitcher(
                    period: stats.period,
                    range: stats.range,
                    now: now,
                    canShowPrevious: canShowPrevious,
                    canShowNext: canShowNext,
                    onSelect: cubit.selectPeriod,
                    onPrevious: cubit.showPrevious,
                    onNext: cubit.showNext,
                  ),
                  const SizedBox(height: PawlogSpacing.xl),
                  // 기간이 바뀌면 키가 바뀌어 막대 선택도 풀린다.
                  AnimatedSwitcher(
                    duration: PawlogMotion.off(context)
                        ? Duration.zero
                        : PawlogMotion.state,
                    child: Column(
                      key: ValueKey((stats.period, stats.range.start)),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PeriodSummaryView(stats: stats),
                        const SizedBox(height: PawlogSpacing.xl),
                        DistanceBarChart(
                          period: stats.period,
                          buckets: stats.buckets,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PawlogSpacing.xxl),
                  WalkRecordsView(records: records, onOpenWalk: onOpenWalk),
                ],
              ),
          },
        ),
      ),
    );
  }
}
