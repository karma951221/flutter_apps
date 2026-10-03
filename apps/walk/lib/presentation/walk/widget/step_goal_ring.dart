import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../theme/walk_motion.dart';

/// 오늘 목표 진행 링. 처음엔 0 에서 [ratio] 까지, 값이 바뀌면 직전 값에서 새 값까지만 그린다.
/// 1 을 넘는 비율은 꽉 찬 원에서 멈춘다(넘친 걸음은 숫자로만 보인다).
class StepGoalRing extends StatelessWidget {
  const StepGoalRing({
    required this.ratio,
    required this.child,
    this.size = AppSpacing.xl * 6,
    super.key,
  });

  final double ratio;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // TweenAnimationBuilder 는 tween 의 끝이 바뀌면 지금 보이는 값을 새 시작으로 삼는다 —
    // begin 0 은 첫 진입에만 쓰인다.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio.clamp(0, 1).toDouble()),
      duration: WalkMotion.off(context) ? Duration.zero : WalkMotion.long,
      curve: WalkMotion.emphasized,
      builder: (context, progress, child) => CustomPaint(
        painter: StepGoalRingPainter(
          progress: progress,
          // 카드(primaryContainer) 위에서 라이트 · 다크 모두 옅게 보이도록 카드 글자색을 낮춘 알파로.
          track: scheme.onPrimaryContainer.withValues(alpha: 0.12),
          color: scheme.primary,
          strokeWidth: AppSpacing.md,
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ),
      ),
    );
  }
}

class StepGoalRingPainter extends CustomPainter {
  StepGoalRingPainter({
    required double progress,
    required this.track,
    required this.color,
    required this.strokeWidth,
  }) : _progress = progress;

  final double _progress;
  final Color track;
  final Color color;
  final double strokeWidth;

  @visibleForTesting
  double get progress => _progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, stroke..color = track);
    if (_progress <= 0) return;
    stroke.color = color;
    if (_progress >= 1) {
      // 끝 캡이 겹쳐 보이지 않게 완전한 원으로.
      canvas.drawCircle(center, radius, stroke);
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * _progress,
      false,
      stroke..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(StepGoalRingPainter old) =>
      old._progress != _progress ||
      old.track != track ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
