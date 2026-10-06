import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// 아이콘 + 개수로 된 작은 동작 버튼.
///
/// 좋아요·싫어요·댓글처럼 "누르는 곳이자 개수를 읽는 곳"인 표시가 게시물 카드와
/// 댓글 목록 양쪽에 반복된다. [AppButton] 은 아이콘 자리가 없고, 화면마다
/// `TextButton.icon` 을 직접 꾸미면 선택 상태 색과 여백이 곧 어긋난다.
///
/// [isActive] 는 "내가 누른 상태"다. 색만 바꾸고 모양은 그대로 둔다 — 목록에서
/// 여러 개가 나란히 보이므로 크기가 흔들리면 읽기 어렵다.
///
/// [animate] 를 켜면 개수가 바뀔 때 숫자가 세로로 미끄러지고(늘면 위로, 줄면
/// 아래로), [isActive] 가 켜지는 순간 아이콘이 한 번 튀며, 색이 부드럽게 바뀐다.
/// 아이콘이 튀는 것도 원래 크기로 돌아오는 순간 효과라 나란한 버튼의 자리는
/// 흔들지 않는다. 기본은 꺼짐 — 켜도 시스템 '애니메이션 줄이기'면 최종 상태만 그린다.
class AppCountAction extends StatefulWidget {
  const AppCountAction({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.animate = false,
    super.key,
  });

  final IconData icon;
  final int count;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;

  /// 개수·선택 상태 변화를 애니메이션으로 보여줄지. 기본 false.
  final bool animate;

  @override
  State<AppCountAction> createState() => _AppCountActionState();
}

class _AppCountActionState extends State<AppCountAction>
    with SingleTickerProviderStateMixin {
  /// 아이콘이 가장 크게 튀는 배율.
  static const _popScale = 1.25;

  /// 마지막 개수 변화의 방향. 늘었으면 1(아래에서 올라옴), 줄었으면 -1.
  int _direction = 1;

  /// 아이콘을 튀게 하는 컨트롤러. 애니메이션을 켠 버튼만 만든다 — 목록에 수십 개가
  /// 깔리는 위젯이라 꺼진 버튼까지 Ticker 를 들고 있을 이유가 없다.
  AnimationController? _popController;
  Animation<double>? _popScaleAnimation;

  AnimationController _ensurePopController() {
    final existing = _popController;
    if (existing != null) return existing;
    final controller = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
    );
    _popController = controller;
    _popScaleAnimation = controller.drive(
      TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1,
            end: _popScale,
          ).chain(CurveTween(curve: AppMotion.standard)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: _popScale,
            end: 1,
          ).chain(CurveTween(curve: AppMotion.emphasized)),
          weight: 1,
        ),
      ]),
    );
    return controller;
  }

  @override
  void didUpdateWidget(AppCountAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      _direction = widget.count > oldWidget.count ? 1 : -1;
    }
    if (widget.animate &&
        !oldWidget.isActive &&
        widget.isActive &&
        AppMotion.enabled(context)) {
      _ensurePopController().forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = widget.isActive ? scheme.primary : scheme.onSurfaceVariant;

    if (!widget.animate || !AppMotion.enabled(context)) {
      return _buildButton(
        color: color,
        icon: Icon(widget.icon, size: 18, color: color),
        label: Text(
          '${widget.count}',
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
      );
    }

    _ensurePopController();
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: AppMotion.short,
      curve: AppMotion.standard,
      builder: (context, animatedColor, _) => _buildButton(
        color: animatedColor ?? color,
        icon: ScaleTransition(
          scale: _popScaleAnimation!,
          child: Icon(widget.icon, size: 18, color: animatedColor),
        ),
        label: ClipRect(
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            // 들어오는 숫자는 방향 쪽에서, 나가는 숫자는 반대쪽으로 빠진다.
            // 나가는 쪽은 애니메이션이 거꾸로 재생되므로 시작점을 뒤집어 둔다.
            transitionBuilder: (child, animation) {
              final isIncoming = child.key == ValueKey<int>(widget.count);
              final dy = (isIncoming ? _direction : -_direction).toDouble();
              final from = Offset(0, dy);
              return SlideTransition(
                position: animation.drive(
                  Tween<Offset>(begin: from, end: Offset.zero),
                ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              '${widget.count}',
              key: ValueKey<int>(widget.count),
              style: theme.textTheme.labelMedium?.copyWith(
                color: animatedColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required Color color,
    required Widget icon,
    required Widget label,
  }) {
    return Tooltip(
      message: widget.tooltip,
      child: TextButton.icon(
        onPressed: widget.onPressed,
        icon: icon,
        label: label,
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
