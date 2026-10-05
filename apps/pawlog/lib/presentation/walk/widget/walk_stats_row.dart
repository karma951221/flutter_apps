import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../theme/pawlog_theme.dart';
import '../format/walk_format.dart';

/// 거리 · 경과 시간 두 칸. 숫자는 Pretendard 700 + 타뷸러라 1초마다 바뀌어도 흔들리지 않는다.
///
/// [hero] 면 산책 중 시트의 44 크기, 아니면 저장 폼 · 상세의 20 크기다.
class WalkStatsRow extends StatelessWidget {
  const WalkStatsRow({
    required this.distanceMeters,
    required this.elapsed,
    this.hero = false,
    super.key,
  });

  final double distanceMeters;
  final Duration elapsed;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Stat(
            label: l10n.walkDistanceLabel,
            value: WalkFormat.distance(l10n, distanceMeters),
            valueKey: const Key('walk-active-distance'),
            hero: hero,
          ),
        ),
        const SizedBox(width: PawlogSpacing.md),
        Expanded(
          child: _Stat(
            label: l10n.walkElapsedLabel,
            value: WalkFormat.clock(elapsed),
            valueKey: const Key('walk-active-elapsed'),
            hero: hero,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueKey,
    required this.hero,
  });

  final String label;
  final String value;
  final Key valueKey;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final styles = PawlogTextStyles.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: PawlogColors.of(context).textMuted,
          ),
        ),
        const SizedBox(height: PawlogSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            key: valueKey,
            maxLines: 1,
            style: hero ? styles.numberHero : styles.number,
          ),
        ),
      ],
    );
  }
}
