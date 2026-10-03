import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 불러오는 동안 자리를 지키는 둥근 사각형. 왼쪽에서 오른쪽으로 옅은 띠가 지나간다.
/// 애니메이션 끄기면 멈춘 채로 그린다.
class WalkSkeleton extends StatefulWidget {
  const WalkSkeleton({required this.height, super.key});

  final double height;

  @override
  State<WalkSkeleton> createState() => _WalkSkeletonState();
}

class _WalkSkeletonState extends State<WalkSkeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            gradient: LinearGradient(
              colors: [
                scheme.surfaceContainerHighest,
                scheme.surfaceContainerLow,
                scheme.surfaceContainerHighest,
              ],
              stops: const [0.3, 0.5, 0.7],
              transform: _Slide(_controller.value),
            ),
          ),
        ),
      ),
    );
  }
}

/// 띠를 상자 왼쪽 밖(-1 폭)에서 오른쪽 밖(+1 폭)까지 옮긴다.
class _Slide extends GradientTransform {
  const _Slide(this.t);

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (2 * t - 1), 0, 0);
}
