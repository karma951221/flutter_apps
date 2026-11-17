import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/transit/entity/transit_path.dart';
import 'line_chip.dart';

/// 경로 구간을 위에서 아래로 잇는 세로 타임라인.
///
/// `도보 5분(320m)` → `7호선 장승배기 → 고속터미널` / `6개 역 · 12분 · 온수 방면` →
/// `환승 도보 3분` → … 탈것 사이 도보는 "환승 도보"로 적는다. 0분 · 0m 도보는 뺀다.
class LegTimeline extends StatelessWidget {
  const LegTimeline({required this.legs, super.key});

  final List<TransitLeg> legs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = [
      for (var i = 0; i < legs.length; i++)
        if (!_empty(legs[i])) (index: i, leg: legs[i]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shown.length; i++)
          _LegRow(
            leg: shown[i].leg,
            lines: _lines(l10n, shown[i].index),
            last: i == shown.length - 1,
          ),
      ],
    );
  }

  static bool _empty(TransitLeg leg) =>
      leg is TransitWalkLeg && leg.minutes == 0 && leg.distanceM == 0;

  bool _isRide(int index) =>
      index >= 0 && index < legs.length && legs[index] is! TransitWalkLeg;

  /// 첫 줄 · 둘째 줄(없으면 null).
  (String, String?) _lines(
    AppLocalizations l10n,
    int index,
  ) => switch (legs[index]) {
    TransitWalkLeg(:final minutes, :final distanceM) =>
      _isRide(index - 1) && _isRide(index + 1)
          ? (l10n.walkTransitLegTransferWalk(minutes), null)
          : (l10n.walkTransitLegWalk(minutes, distanceM), null),
    TransitSubwayLeg(
      :final lineName,
      :final start,
      :final end,
      :final stationCount,
      :final minutes,
      :final way,
    ) =>
      (
        '$lineName ${l10n.walkTransitLegStops(start, end)}',
        [
          l10n.walkTransitLegSubwayInfo(stationCount, minutes),
          if (way.isNotEmpty) l10n.walkTransitLegWay(way),
        ].join(' · '),
      ),
    final TransitBusLeg bus => (
      '${LineChip.labelOf(bus)} ${l10n.walkTransitLegStops(bus.start, bus.end)}',
      l10n.walkTransitLegBusInfo(bus.stationCount, bus.minutes),
    ),
  };
}

class _LegRow extends StatelessWidget {
  const _LegRow({required this.leg, required this.lines, required this.last});

  final TransitLeg leg;
  final (String, String?) lines;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, color) = switch (leg) {
      TransitWalkLeg() => (Icons.directions_walk, scheme.onSurfaceVariant),
      TransitSubwayLeg() => (Icons.subway, scheme.primary),
      TransitBusLeg() => (Icons.directions_bus, scheme.secondary),
    };
    final (title, subtitle) = lines;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Icon(icon, color: color),
              if (!last)
                Expanded(child: VerticalDivider(color: scheme.outlineVariant)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: leg is TransitWalkLeg
                        ? theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          )
                        : theme.textTheme.titleSmall,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
