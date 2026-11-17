import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../domain/transit/entity/transit_path.dart';

/// 탈것 구간 하나의 노선 칩 — 지하철은 노선 이름, 버스는 번호들.
///
/// 지하철은 primary, 버스는 secondary 컨테이너 색이다(노선 고유색 토큰은 아직 없다).
class LineChip extends StatelessWidget {
  const LineChip({required this.leg, super.key});

  /// 지하철 · 버스 구간. 도보 구간은 넘기지 않는다.
  final TransitLeg leg;

  /// 칩 글자 — 지하철 노선 이름, 버스 번호들. 도보면 null.
  static String? labelOf(TransitLeg leg) => switch (leg) {
    TransitSubwayLeg(:final lineName) => lineName,
    TransitBusLeg(:final busNumbers) => busNumbers.join(' · '),
    TransitWalkLeg() => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground, icon) = switch (leg) {
      TransitBusLeg() => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.directions_bus,
      ),
      _ => (scheme.primaryContainer, scheme.onPrimaryContainer, Icons.subway),
    };
    final style = theme.textTheme.labelMedium?.copyWith(color: foreground);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: style?.fontSize, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Flexible(child: Text(labelOf(leg) ?? '', style: style)),
          ],
        ),
      ),
    );
  }
}
