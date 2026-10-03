import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 막대그래프 위 목표 위치 점선(`outline`, 1px) + 오른쪽 [gutter] 안의 `목표` 라벨.
/// [ratio] 는 차트 높이 대비 목표 높이(0~1). 부모 크기를 꽉 채운다.
/// 막대는 [gutter] 만큼 오른쪽을 비워 두므로 라벨이 막대를 가리지 않는다.
class GoalLineOverlay extends StatelessWidget {
  const GoalLineOverlay({required this.ratio, required this.gutter, super.key});

  final double ratio;
  final double gutter;

  /// 라벨 칸 높이. 글자는 이 안에 맞춰 줄어든다.
  static const _labelHeight = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final y = height * ratio;
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: gutter,
              bottom: math.min(y, height - 1),
              child: CustomPaint(
                key: const Key('walk-goal-line'),
                size: const Size.fromHeight(1),
                painter: _DashedLine(scheme.outline),
              ),
            ),
            // 선 높이에 세로 가운데를 맞추되 차트 밖으로 나가지 않게 한다.
            Positioned(
              key: const Key('walk-goal-label'),
              right: 0,
              width: gutter,
              height: _labelHeight,
              bottom: (y - _labelHeight / 2).clamp(0, height - _labelHeight),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppLocalizations.of(context).walkGoalLine,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
