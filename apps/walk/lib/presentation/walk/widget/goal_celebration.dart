import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/walk_motion.dart';

/// [play] 가 참으로 처음 그려지거나 거짓 → 참으로 바뀌는 순간 [child] 둘레로 점 16개가 퍼지며
/// 사라지고 진동이 한 번 온다. 애니메이션 끄기면 진동만. 같은 참이 이어지는 동안은 되풀이하지 않는다.
class GoalCelebration extends StatefulWidget {
  const GoalCelebration({
    required this.play,
    required this.child,
    this.onPlayed,
    super.key,
  });

  final bool play;
  final Widget child;

  /// 연출을 시작한 직후 불린다(build 단계일 수 있어 부모는 setState 하지 않는다).
  final VoidCallback? onPlayed;

  @override
  State<GoalCelebration> createState() => _GoalCelebrationState();
}

class _GoalCelebrationState extends State<GoalCelebration>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: WalkMotion.celebrate,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 테마 등 의존성이 바뀌어도 다시 불리므로 첫 번만.
    if (_started) return;
    _started = true;
    if (widget.play) _play();
  }

  @override
  void didUpdateWidget(GoalCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) _play();
  }

  void _play() {
    HapticFeedback.mediumImpact();
    if (!WalkMotion.off(context)) _controller.forward(from: 0);
    widget.onPlayed?.call();
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
