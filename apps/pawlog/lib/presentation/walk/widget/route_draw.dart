import 'package:flutter/widgets.dart';

import '../../theme/pawlog_theme.dart';

/// 경로가 출발점에서 도착점까지 1.6초에 걸쳐 그려지는 연출 — pawlog 의 유일한 연출이다
/// (design.md Motion · The one authored moment).
///
/// [animate] 가 참이면 처음 그려질 때 한 번 0 → 1 로 간다. 거짓이거나 시스템
/// '애니메이션 줄이기' 가 켜져 있으면 처음부터 1(완성된 선)이다.
class RouteDraw extends StatefulWidget {
  const RouteDraw({required this.animate, required this.builder, super.key});

  final bool animate;

  /// [progress] 는 0(아무것도 없음) ~ 1(전체 경로). 곡선(`move`)이 이미 적용돼 있다.
  final Widget Function(BuildContext context, double progress) builder;

  @override
  State<RouteDraw> createState() => _RouteDrawState();
}

class _RouteDrawState extends State<RouteDraw>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PawlogMotion.routeDraw,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: PawlogMotion.move,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || PawlogMotion.off(context)) {
      _controller.value = 1;
    } else if (!_started) {
      _controller.forward(from: 0);
    }
    _started = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    builder: (context, _) => widget.builder(context, _progress.value),
  );
}
