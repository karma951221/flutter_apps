import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/walk_motion.dart';

/// [play] 가 처음 참이 되는 순간 [child] 둘레로 점 16개가 퍼지며 사라지고 진동이 한 번 온다.
/// 애니메이션 끄기면 진동만.
class GoalCelebration extends StatefulWidget {
  const GoalCelebration({required this.play, required this.child, super.key});

  final bool play;
  final Widget child;

  @override
  State<GoalCelebration> createState() => _GoalCelebrationState();
}

class _GoalCelebrationState extends State<GoalCelebration>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: WalkMotion.celebrate,
  );
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybePlay();
  }

  @override
  void didUpdateWidget(GoalCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePlay();
  }

  void _maybePlay() {
    if (!widget.play || _played) return;
    _played = true;
    HapticFeedback.mediumImpact();
    if (!WalkMotion.off(context)) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      foregroundPainter: _ParticlePainter(
        animation: _controller,
        colors: (scheme.primary, scheme.tertiary),
      ),
      child: widget.child,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.animation, required this.colors})
    : super(repaint: animation);

  static const _count = 16;

  final Animation<double> animation;
  final (Color, Color) colors;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0 || t >= 1) return;
    final eased = WalkMotion.emphasized.transform(t);
    final center = size.center(Offset.zero);
    final distance = size.shortestSide / 2 + AppSpacing.xl * eased;
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final angle = 2 * math.pi * i / _count;
      final color = i.isEven ? colors.$1 : colors.$2;
      paint.color = color.withValues(alpha: 1 - t);
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        AppSpacing.xs,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.animation != animation || old.colors != colors;
}
