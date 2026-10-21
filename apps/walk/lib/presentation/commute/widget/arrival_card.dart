import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/commute/entity/commute_result.dart';
import '../../../domain/commute/entity/train_arrival.dart';
import '../../../domain/commute/entity/transit_route.dart';

/// 첫 승차역 카드 — 역 · 노선 · 방면, 다음 열차 최대 두 대, 역까지 도보 분.
class ArrivalCard extends StatelessWidget {
  const ArrivalCard({
    required this.leg,
    required this.arrivals,
    required this.realtime,
    required this.walkMinutes,
    super.key,
  });

  /// 첫 지하철 구간.
  final SubwayLeg leg;
  final List<TrainArrival> arrivals;
  final RealtimeStatus realtime;
  final int walkMinutes;

  static const _maxTrains = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final notice = switch (realtime) {
      RealtimeStatus.ok => null,
      RealtimeStatus.unavailable => l10n.walkCommuteRealtimeUnavailable,
      RealtimeStatus.failed => l10n.walkCommuteRealtimeFailed,
    };
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.walkCommuteStationHeader(
                leg.startStation,
                leg.lineName,
                leg.wayName,
              ),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (notice != null)
              Text(notice, style: muted)
            else
              for (final train in arrivals.take(_maxTrains))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    trainLine(l10n, train),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.walkCommuteWalkToStation(walkMinutes), style: muted),
          ],
        ),
      ),
    );
  }

  /// `4분 후 · 3번째 전역` · `약 6분 후` · `곧 도착`. 분을 모르면 원문 메시지.
  static String trainLine(AppLocalizations l10n, TrainArrival train) {
    final minutes = train.minutes;
    if (minutes == null) return train.message;
    final time = minutes == 0
        ? l10n.walkCommuteTrainArriving
        : train.estimated
        ? l10n.walkCommuteTrainMinutesEstimated(minutes)
        : l10n.walkCommuteTrainMinutes(minutes);
    final away = train.stationsAway;
    if (away == null || away <= 0) return time;
    return '$time · ${l10n.walkCommuteTrainStationsAway(away)}';
  }
}
