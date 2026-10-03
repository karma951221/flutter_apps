import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 막대그래프 위 목표 위치 점선(`outline`, 1px) + 오른쪽 끝 `목표` 라벨.
/// [ratio] 는 차트 높이 대비 목표 높이(0~1). 부모 크기를 꽉 채운다.
class GoalLineOverlay extends StatelessWidget {
  const GoalLineOverlay({required this.ratio, super.key});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: math.min(
              constraints.maxHeight * ratio,
              constraints.maxHeight - 1,
            ),
            child: CustomPaint(
              key: const Key('walk-goal-line'),
              size: const Size.fromHeight(1),
              painter: _DashedLine(scheme.outline),
            ),
          ),
          // 라벨 바탕이 점선을 가려 `----- 목표` 처럼 읽힌다.
          Align(
            alignment: Alignment(1, 1 - 2 * ratio),
            child: ColoredBox(
              color: scheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  AppLocalizations.of(context).walkGoalLine,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 가로 점선 한 줄.
class _DashedLine extends CustomPainter {
  const _DashedLine(this.color);

  final Color color;

  static const _dash = AppSpacing.xs;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += _dash * 2) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + _dash, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedLine oldDelegate) => oldDelegate.color != color;
}
