import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../cubit/period_activity_cubit.dart';
import '../cubit/period_activity_state.dart';
import 'activity_bar_chart.dart';
import 'period_header.dart';
import 'period_summary.dart';

/// 탭 하나의 내용 — 머리 · 막대그래프 · 요약.
class PeriodSection extends StatelessWidget {
  const PeriodSection({required this.cubit, super.key});

  final PeriodActivityCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<PeriodActivityCubit, PeriodActivityState>(
      bloc: cubit,
      builder: (context, state) => switch (state) {
        PeriodActivityLoading() => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        PeriodActivityFailure() => AppPlaceholder(
          message: l10n.walkLoadFailed,
          actionLabel: l10n.commonRetry,
          onAction: cubit.load,
        ),
        PeriodActivityLoaded(:final period) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PeriodHeader(
              period: period,
              onPrevious: cubit.previous,
              onNext: period.isCurrent ? null : cubit.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            ActivityBarChart(period: period),
            const SizedBox(height: AppSpacing.md),
            PeriodSummary(period: period),
          ],
        ),
      },
    );
  }
}
