import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/tracking/entity/walk_session.dart';
import '../../theme/pawlog_theme.dart';
import '../../walk/format/walk_format.dart';

/// 피드 맨 위의 진행 배너 — 남색 바탕(design.md Components · 진행 배너).
///
/// 추적 중이면 왼쪽에 연두 점이 1.6초 주기로 점멸하고 오른쪽에 경과 시간이 붙는다.
/// 저장 전이면 안내 문구만 — '진행 중' 이 아니므로 연두를 쓰지 않는다.
class ActiveWalkBanner extends StatelessWidget {
  const ActiveWalkBanner.tracking({
    required this.session,
    required this.elapsed,
    required this.onTap,
    super.key,
  }) : unsaved = false;

  const ActiveWalkBanner.unsaved({required this.onTap, super.key})
    : unsaved = true,
      session = null,
      elapsed = Duration.zero;

  final bool unsaved;
  final WalkSession? session;
  final Duration elapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);
    final styles = PawlogTextStyles.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PawlogSize.gutter,
        PawlogSpacing.sm,
        PawlogSize.gutter,
        PawlogSpacing.sm,
      ),
      child: Material(
        key: const Key('walk-feed-banner'),
        color: colors.primary,
        borderRadius: PawlogRadius.controlAll,
        child: InkWell(
          borderRadius: PawlogRadius.controlAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PawlogSpacing.md,
              vertical: PawlogSpacing.md,
            ),
            child: Row(
              children: [
                if (!unsaved) ...[
                  PulseDot(color: colors.accent),
                  const SizedBox(width: PawlogSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    unsaved
                        ? l10n.walkUnsavedBanner
                        : l10n.walkInProgressBanner,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!unsaved) ...[
                  const SizedBox(width: PawlogSpacing.sm),
                  Text(
                    WalkFormat.clock(elapsed),
                    key: const Key('walk-feed-banner-elapsed'),
                    style: styles.number.copyWith(color: colors.onPrimary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// '진행 중' 연두 점. [PawlogMotion.pulse] 주기로 옅어졌다 돌아온다.
/// 애니메이션 줄이기가 켜져 있으면 멈춘 채 꽉 찬 점이다.
class PulseDot extends StatefulWidget {
  const PulseDot({required this.color, super.key});

  final Color color;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  /// 점멸의 가장 옅은 순간.
  static const _dimmest = 0.25;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    // 반 주기씩 옅어지고 돌아와 한 주기가 1.6초다.
    duration: PawlogMotion.pulse ~/ 2,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (PawlogMotion.off(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(
      begin: 1,
      end: _dimmest,
    ).animate(CurvedAnimation(parent: _controller, curve: PawlogMotion.move)),
    child: SizedBox.square(
      dimension: PawlogSize.pulseDot,
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    ),
  );
}
