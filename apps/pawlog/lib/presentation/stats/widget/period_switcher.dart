import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/period_range.dart';
import '../../../domain/stats/entity/stats_period.dart';
import '../../theme/pawlog_theme.dart';
import '../format/stats_format.dart';

/// `[주 | 월]` 알약 토글과 그 아래 `‹ 기간 라벨 ›` 한 줄.
class PeriodSwitcher extends StatelessWidget {
  const PeriodSwitcher({
    required this.period,
    required this.range,
    required this.now,
    required this.canShowPrevious,
    required this.canShowNext,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final StatsPeriod period;
  final PeriodRange range;
  final DateTime now;
  final bool canShowPrevious;
  final bool canShowNext;
  final ValueChanged<StatsPeriod> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: PawlogRadius.fullAll,
            border: Border.all(color: colors.rule),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlogSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (value, label) in [
                  (StatsPeriod.week, l10n.walkStatsWeek),
                  (StatsPeriod.month, l10n.walkStatsMonth),
                ])
                  _Segment(
                    key: Key('stats-period-${value.name}'),
                    label: label,
                    selected: value == period,
                    onTap: () => onSelect(value),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PawlogSpacing.md),
        Row(
          children: [
            _Arrow(
              key: const Key('stats-previous'),
              icon: Icons.chevron_left,
              tooltip: l10n.walkStatsPreviousTooltip,
              enabled: canShowPrevious,
              onPressed: onPrevious,
            ),
            Expanded(
              child: Text(
                StatsFormat.rangeLabel(l10n.localeName, period, range, now),
                key: const Key('stats-range-label'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            _Arrow(
              key: const Key('stats-next'),
              icon: Icons.chevron_right,
              tooltip: l10n.walkStatsNextTooltip,
              enabled: canShowNext,
              onPressed: onNext,
            ),
          ],
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = PawlogColors.of(context);
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: PawlogMotion.off(context)
              ? Duration.zero
              : PawlogMotion.state,
          curve: PawlogMotion.move,
          decoration: BoxDecoration(
            color: selected ? colors.primary : null,
            borderRadius: PawlogRadius.fullAll,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: PawlogSpacing.lg,
            vertical: PawlogSpacing.sm,
          ),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: selected ? colors.onPrimary : colors.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// 비활성은 주 버튼 비활성과 같은 투명도로 흐리게 남긴다.
class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = PawlogColors.of(context);
    return Opacity(
      opacity: enabled ? 1 : PawlogMotion.disabledOpacity,
      child: IconButton(
        icon: Icon(icon),
        color: colors.primary,
        disabledColor: colors.primary,
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}
