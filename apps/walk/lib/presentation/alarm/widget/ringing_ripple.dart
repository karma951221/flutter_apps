import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../theme/walk_motion.dart';

/// 울림 화면 아이콘 둘레로 퍼지는 파문 세 겹. 2.4초 주기로 반복한다.
/// 시스템 "애니메이션 제거"면 돌리지 않고 [child] 만 그린다.
class RingingRipple extends StatefulWidget {
  const RingingRipple({required this.child, super.key});

  final Widget child;

  @override
  State<RingingRipple> createState() => _RingingRippleState();
}

class _RingingRippleState extends State<RingingRipple>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool? _off;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final off = WalkMotion.off(context);
    if (off == _off) return;
    _off = off;
    if (off) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_off ?? false) return widget.child;
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => CustomPaint(
        painter: _RipplePainter(phase: _controller.value, color: color),
        child: child,
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  static const _rings = 3;
  static const _spread = AppSpacing.xl * 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = math.min(size.width, size.height) / 2;
    for (var k = 0; k < _rings; k++) {
      final t = (phase + k / _rings) % 1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.35 * (1 - t));
      canvas.drawCircle(center, base + _spread * t, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.phase != phase || old.color != color;
}
