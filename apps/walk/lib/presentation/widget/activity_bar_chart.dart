import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../domain/entity/activity_period.dart';
import '../../domain/entity/daily_activity.dart';
import '../../domain/entity/period_kind.dart';
import '../format/walk_format.dart';

/// 날짜별 걸음 막대. 높이는 기간 안 최댓값 기준, 오늘 막대 강조, 오늘 이후는 비운다.
/// 막대를 누르면 위 한 줄에 그날 걸음을 보여준다.
class ActivityBarChart extends StatefulWidget {
  const ActivityBarChart({required this.period, super.key});

  final ActivityPeriod period;

  static const _chartHeight = AppSpacing.xl * 5;

  @override
  State<ActivityBarChart> createState() => _ActivityBarChartState();
}

class _ActivityBarChartState extends State<ActivityBarChart> {
  DailyActivity? _selected;

  @override
  void didUpdateWidget(ActivityBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period.start != widget.period.start) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final period = widget.period;
    final maxSteps = period.days.fold(0, (m, d) => d.steps > m ? d.steps : m);
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: const Key('walk-bar-selection'),
          height: AppSpacing.lg,
          child: selected == null
              ? null
              : Text(
                  '${DateFormat.MMMEd(locale).format(selected.date)} · '
                  '${l10n.walkStepsCount(WalkFormat.steps(locale, selected.steps))}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
        ),
        SizedBox(
          height: ActivityBarChart._chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in period.days)
                Expanded(child: _bar(context, day, maxSteps)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (final day in period.days)
              Expanded(
                child: Text(
                  _label(locale, day.date),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _bar(BuildContext context, DailyActivity day, int maxSteps) {
    if (day.date.isAfter(widget.period.today)) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final isToday = day.date == widget.period.today;
    final isSelected = day.date == _selected?.date;
    final ratio = maxSteps == 0 ? 0.0 : day.steps / maxSteps;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = day),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: ratio.clamp(0.02, 1.0),
          child: Container(
            key: Key('walk-bar-${DateFormat('yyyy-MM-dd').format(day.date)}'),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
            decoration: BoxDecoration(
              color: isToday || isSelected
                  ? scheme.primary
                  : scheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sm / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 주간은 요일, 월간은 1 · 5 · 10 · 15 · 20 · 25 · 30 일만(좁아서).
  String _label(String locale, DateTime date) => switch (widget.period.kind) {
    PeriodKind.week => WalkFormat.weekday(locale, date),
    PeriodKind.month =>
      date.day == 1 || date.day % 5 == 0 ? WalkFormat.day(date) : '',
  };
}
