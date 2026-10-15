import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/stats/entity/stats_bucket.dart';
import '../../../domain/stats/entity/stats_period.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';
import '../format/stats_format.dart';

/// 거리 막대. 남색 막대, 0 인 칸은 바닥선만 — 연두는 쓰지 않는다(design.md Colors).
///
/// 막대가 자라는 연출은 없다 — 앱의 연출은 경로 그리기 하나다. 칸을 탭하면 그 위에 값이 뜨고,
/// 다른 칸을 탭하면 옮겨 가고, 같은 칸을 다시 탭하면 사라진다.
class DistanceBarChart extends StatefulWidget {
  const DistanceBarChart({
    required this.period,
    required this.buckets,
    super.key,
  });

  final StatsPeriod period;
  final List<StatsBucket> buckets;

  @override
  State<DistanceBarChart> createState() => _DistanceBarChartState();
}

class _DistanceBarChartState extends State<DistanceBarChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final maxDistance = widget.buckets.fold<double>(
      0,
      (max, bucket) => math.max(max, bucket.distanceMeters),
    );
    return SizedBox(
      height: PawlogSize.statsChart,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.buckets.length; i++)
            Expanded(child: _bar(context, i, maxDistance)),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, int index, double maxDistance) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final theme = Theme.of(context);
    final bucket = widget.buckets[index];
    final label = StatsFormat.bucketLabel(
      l10n.localeName,
      widget.period,
      bucket.range,
    );
    final distance = WalkFormat.distance(l10n, bucket.distanceMeters);
    final fraction = maxDistance == 0
        ? 0.0
        : bucket.distanceMeters / maxDistance;
    final selected = _selected == index;
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: colors.textMuted,
    );

    void toggle() => setState(() => _selected = selected ? null : index);

    // excludeSemantics 는 GestureDetector 의 탭 동작까지 지우므로 여기서 다시 단다.
    return Semantics(
      label: l10n.walkStatsBarSemantics(label, distance),
      button: true,
      selected: selected,
      excludeSemantics: true,
      onTap: toggle,
      child: GestureDetector(
        key: Key('stats-bar-$index'),
        behavior: HitTestBehavior.opaque,
        onTap: toggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PawlogSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: PawlogSpacing.lg,
                child: selected
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          distance,
                          key: const Key('stats-bar-value'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Align(
                    alignment: Alignment.bottomCenter,
                    child: fraction == 0
                        ? SizedBox(
                            height: PawlogSize.hairline,
                            width: double.infinity,
                            child: ColoredBox(color: colors.rule),
                          )
                        : SizedBox(
                            // 아주 짧은 산책도 보이도록 바닥선 두 배는 남긴다.
                            height: math.max(
                              constraints.maxHeight * fraction,
                              PawlogSize.hairline * 2,
                            ),
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(PawlogRadius.photo),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: PawlogSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: labelStyle, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
