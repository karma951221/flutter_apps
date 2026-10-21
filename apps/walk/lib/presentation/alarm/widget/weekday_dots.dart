import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../domain/alarm/entity/alarm.dart';

/// 반복 알람 행의 요일 점 7개(월~일). 켜진 요일은 primary, 나머지는 outlineVariant.
/// 꺼진 알람([dimmed])이면 켜진 요일도 흐린 onSurfaceVariant.
///
/// 같은 행의 반복 요약 글자가 이미 읽히므로 접근성 트리에서는 뺀다.
class WeekdayDots extends StatelessWidget {
  const WeekdayDots({required this.days, this.dimmed = false, super.key});

  final Set<Weekday> days;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final on = dimmed ? colorScheme.onSurfaceVariant : colorScheme.primary;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final day in Weekday.values) ...[
            if (day != Weekday.values.first) const SizedBox(width: AppSpacing.xs),
            DecoratedBox(
              key: ValueKey('weekday-dot-${day.name}'),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: days.contains(day) ? on : colorScheme.outlineVariant,
              ),
              // 점 지름은 가장 작은 여백 토큰 둘 — 글자 한 줄보다 작게.
              child: const SizedBox.square(dimension: AppSpacing.sm),
            ),
          ],
        ],
      ),
    );
  }
}
