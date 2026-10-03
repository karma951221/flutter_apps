import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/walk/entity/activity_period.dart';
import '../../../domain/walk/entity/daily_activity.dart';
import '../../../domain/walk/entity/period_kind.dart';
import '../../theme/walk_motion.dart';
import '../format/walk_format.dart';
import 'goal_line_overlay.dart';

/// 날짜별 걸음 막대. 높이 기준은 max(기간 최댓값, 목표), 목표 위치에 점선.
/// 달성일은 진하게, 오늘은 테두리, 오늘 이후는 비운다. 기간이 바뀌면 왼쪽부터 자란다.
/// 막대를 누르면 위 한 줄에 그날 걸음과 목표 대비 % 를 보여준다.
class ActivityBarChart extends StatefulWidget {
  const ActivityBarChart({required this.period, required this.goal, super.key});

  final ActivityPeriod period;
  final int goal;

  /// 막대 영역 높이. 기간 스켈레톤 높이도 이것을 기준으로 잡는다.
  static const chartHeight = AppSpacing.xl * 5;

  @override
  State<ActivityBarChart> createState() => _ActivityBarChartState();
}

class _ActivityBarChartState extends State<ActivityBarChart>
    with SingleTickerProviderStateMixin {
  static const _todayBorderWidth = 2.0;

  /// 오른쪽에 비워 두는 `목표` 라벨 자리. 막대 · 날짜 줄이 같이 비운다.
  static const _labelGutter = AppSpacing.xl;
  static const _barStagger = 30;
  static const _maxStagger = 900;

  late final _growth = AnimationController(vsync: this);

  /// 날짜만 기억한다 — 같은 기간을 새로 읽으면 build 가 새 값으로 다시 찾는다.
  DateTime? _selectedDate;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (WalkMotion.off(context)) {
      _growth.value = 1;
    } else if (!_started) {
      _grow();
    }
    _started = true;
  }

  @override
  void didUpdateWidget(ActivityBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period.start != widget.period.start ||
        oldWidget.period.kind != widget.period.kind) {
      _selectedDate = null;
      if (WalkMotion.off(context)) {
        _growth.value = 1;
      } else {
        _grow();
      }
    }
  }

  @override
  void dispose() {
    _growth.dispose();
    super.dispose();
  }

  int _delayMs(int index) => math.min(index * _barStagger, _maxStagger);

  int get _totalMs =>
      _delayMs(widget.period.days.length - 1) +
      WalkMotion.medium.inMilliseconds;

  void _grow() {
    _growth
      ..duration = Duration(milliseconds: _totalMs)
      ..forward(from: 0);
  }

  double _progress(int index) {
    final total = _totalMs;
    final start = _delayMs(index) / total;
    final end = (_delayMs(index) + WalkMotion.medium.inMilliseconds) / total;
    return Interval(
      start,
      math.min(end, 1),
      curve: WalkMotion.emphasized,
    ).transform(_growth.value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final theme = Theme.of(context);
    final period = widget.period;
    final maxSteps = period.days.fold(0, (m, d) => d.steps > m ? d.steps : m);
    final scale = math.max(maxSteps, widget.goal);
    final goalRatio = scale == 0 ? 0.0 : widget.goal / scale;
    final selected = period.days
        .where((day) => day.date == _selectedDate)
        .firstOrNull;

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
                  '${l10n.walkStepsCount(WalkFormat.steps(locale, selected.steps))}'
                  '${_goalPercent(l10n, selected.steps)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge,
                ),
        ),
        SizedBox(
          height: ActivityBarChart.chartHeight,
          child: Stack(
            children: [
              Positioned.fill(
                right: _labelGutter,
                child: AnimatedBuilder(
                  animation: _growth,
                  builder: (context, _) => Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (i, day) in period.days.indexed)
                        Expanded(child: _bar(context, i, day, scale)),
                    ],
                  ),
                ),
              ),
              if (widget.goal > 0)
                // 점선 · 라벨이 막대 탭을 가로채지 않게 한다.
                Positioned.fill(
                  child: IgnorePointer(
                    child: GoalLineOverlay(
                      ratio: goalRatio,
                      gutter: _labelGutter,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(right: _labelGutter),
          child: Row(
            children: [
              for (final day in period.days)
                Expanded(
                  child: Text(
                    _label(locale, day.date),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _goalPercent(AppLocalizations l10n, int steps) => widget.goal <= 0
      ? ''
      : ' · ${l10n.walkGoalOfPercent((steps * 100 / widget.goal).round())}';

  Widget _bar(BuildContext context, int index, DailyActivity day, int scale) {
    if (day.date.isAfter(widget.period.today)) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final isToday = day.date == widget.period.today;
    final isSelected = day.date == _selectedDate;
    final ratio = scale == 0 ? 0.0 : day.steps / scale;
    final reached = widget.goal > 0 && day.steps >= widget.goal;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDate = day.date);
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedScale(
          scale: isSelected ? 1.06 : 1,
          alignment: Alignment.bottomCenter,
          duration: WalkMotion.off(context) ? Duration.zero : WalkMotion.short,
          child: Container(
            key: Key('walk-bar-${DateFormat('yyyy-MM-dd').format(day.date)}'),
            height:
                ActivityBarChart.chartHeight *
                ratio.clamp(0.02, 1.0) *
                _progress(index),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
            decoration: BoxDecoration(
              color: reached ? scheme.primary : scheme.primaryContainer,
              // 달성한 오늘은 primary 위라 테두리를 onPrimaryContainer 로 바꿔 보이게 한다.
              border: isToday
                  ? Border.all(
                      color: reached
                          ? scheme.onPrimaryContainer
                          : scheme.primary,
                      width: _todayBorderWidth,
                    )
                  : null,
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
