import 'package:design_system/design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/lock/lock_policy.dart';

/// 3×3 패턴 입력. 점 인덱스는 왼쪽 위부터 가로로 0~8.
///
/// 지나간 점에 건너뛴 가운데 점을 끼워 넣고(`PatternRule.withSkipped`), 같은 점은 한 번만
/// 센다. 손을 떼면 점이 [PatternRule.minDots] 개 이상일 때만 [onCompleted] 를 부르고,
/// 모자라면 오류 문구를 보인다(다음 그리기에서 지운다).
class PatternLock extends StatefulWidget {
  const PatternLock({
    required this.onCompleted,
    this.enabled = true,
    super.key,
  });

  /// 격자 영역. 테스트가 점 좌표를 계산할 때 쓴다.
  static const gridKey = ValueKey('pattern-lock-grid');

  final ValueChanged<List<int>> onCompleted;
  final bool enabled;

  @override
  State<PatternLock> createState() => _PatternLockState();
}

/// 점을 잡는 반경(칸 크기에 대한 비율).
const _hitRatio = 0.35;

class _PatternLockState extends State<PatternLock> {
  List<int> _dots = const [];
  Offset? _finger;
  bool _tooShort = false;
  bool _drawing = false;

  int? _dotAt(Offset p, double side) {
    final cell = side / 3;
    final col = (p.dx / cell).floor();
    final row = (p.dy / cell).floor();
    if (col < 0 || col > 2 || row < 0 || row > 2) return null;
    final center = Offset((col + 0.5) * cell, (row + 0.5) * cell);
    return (p - center).distance <= cell * _hitRatio ? row * 3 + col : null;
  }

  void _visit(Offset p, double side) {
    final dot = _dotAt(p, side);
    setState(() {
      _finger = p;
      if (dot != null && !_dots.contains(dot)) {
        _dots = PatternRule.withSkipped([..._dots, dot]);
      }
    });
  }

  void _start(Offset p, double side) {
    if (!widget.enabled) return;
    _drawing = true;
    _dots = const [];
    _tooShort = false;
    _visit(p, side);
  }

  void _end() {
    if (!_drawing) return;
    _drawing = false;
    final dots = _dots;
    setState(() {
      _finger = null;
      _dots = const [];
      _tooShort = dots.isNotEmpty && dots.length < PatternRule.minDots;
    });
    if (dots.length >= PatternRule.minDots) widget.onCompleted(dots);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = constraints.maxWidth;
              return GestureDetector(
                key: PatternLock.gridKey,
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onPanStart: (d) => _start(d.localPosition, side),
                onPanUpdate: (d) {
                  if (_drawing) _visit(d.localPosition, side);
                },
                onPanEnd: (_) => _end(),
                onPanCancel: _end,
                child: CustomPaint(
                  size: Size.square(side),
                  painter: _PatternPainter(
                    dots: _dots,
                    finger: _finger,
                    idle: scheme.outline,
                    active: _tooShort ? scheme.error : scheme.primary,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // 문구가 나타나도 격자가 움직이지 않게 줄을 늘 차지한다.
        Text(
          _tooShort ? AppLocalizations.of(context).walkLockSetupTooShort : '',
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.dots,
    required this.finger,
    required this.idle,
    required this.active,
  });

  final List<int> dots;
  final Offset? finger;
  final Color idle;
  final Color active;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 3;
    Offset center(int i) => Offset((i % 3 + 0.5) * cell, (i ~/ 3 + 0.5) * cell);

    final line = Paint()
      ..color = active
      ..strokeWidth = AppSpacing.xs
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < dots.length; i++) {
      canvas.drawLine(center(dots[i - 1]), center(dots[i]), line);
    }
    final f = finger;
    if (f != null && dots.isNotEmpty) {
      canvas.drawLine(center(dots.last), f, line);
    }

    for (var i = 0; i < 9; i++) {
      final selected = dots.contains(i);
      canvas.drawCircle(
        center(i),
        selected ? AppSpacing.sm * 1.5 : AppSpacing.sm,
        Paint()..color = selected ? active : idle,
      );
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.dots != dots ||
      old.finger != finger ||
      old.idle != idle ||
      old.active != active;
}
