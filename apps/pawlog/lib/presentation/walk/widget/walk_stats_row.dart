import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../format/walk_format.dart';

/// 경과 시간 · 이동 거리 두 칸. 진행 화면과 이후 카드가 함께 쓴다.
class WalkStatsRow extends StatelessWidget {
  const WalkStatsRow({
    required this.distanceMeters,
    required this.elapsed,
    super.key,
  });

  final double distanceMeters;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _Stat(
            label: l10n.walkElapsedLabel,
            value: WalkFormat.clock(elapsed),
            valueKey: const Key('walk-active-elapsed'),
          ),
        ),
        Expanded(
          child: _Stat(
            label: l10n.walkDistanceLabel,
            value: WalkFormat.distance(l10n, distanceMeters),
            valueKey: const Key('walk-active-distance'),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(value, key: valueKey, style: theme.textTheme.headlineMedium),
      ],
    );
  }
}
