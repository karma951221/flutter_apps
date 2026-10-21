import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/commute/commute_policy.dart';
import '../../../domain/commute/entity/commute_result.dart';
import '../../../domain/commute/entity/transit_route.dart';

/// 도착 예상 · 총 시간 · 환승, 구간 줄, 다른 경로 개수.
class RouteSummary extends StatelessWidget {
  const RouteSummary({required this.result, this.onShowRoutes, super.key});

  final CommuteResult result;

  /// "다른 경로 n개"를 눌렀을 때.
  final VoidCallback? onShowRoutes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final route = result.route;
    final alternatives = result.alternatives.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                l10n.walkCommuteEta(clockTime(result.eta)),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            if (_estimated) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.walkCommuteEtaEstimated,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.walkCommuteSummary(route.totalMinutes, route.transferCount),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          legsLine(l10n, route),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (alternatives > 0)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton.text(
              label: l10n.walkCommuteAlternatives(alternatives),
              onPressed: onShowRoutes ?? () {},
            ),
          ),
      ],
    );
  }

  /// 실시간 열차가 아니라 시간표 · 정거장 수 추정으로 낸 도착 예상인지.
  bool get _estimated {
    if (!result.etaFromRealtime) return true;
    return boardingTrain(result.arrivals, result.verdict)?.estimated ?? false;
  }

  /// `도보 6 → 7호선 장승배기→논현 16 → …`
  static String legsLine(AppLocalizations l10n, TransitRoute route) => route
      .legs
      .map(
        (leg) => switch (leg) {
          WalkLeg(:final minutes) => l10n.walkCommuteLegWalk(minutes),
          SubwayLeg(
            :final lineName,
            :final startStation,
            :final endStation,
            :final minutes,
          ) =>
            l10n.walkCommuteLegSubway(
              lineName,
              startStation,
              endStation,
              minutes,
            ),
        },
      )
      .join(' → ');

  /// `08:35`
  static String clockTime(DateTime at) => DateFormat('HH:mm').format(at);
}
