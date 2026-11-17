import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/transit/entity/transit_path.dart';
import 'line_chip.dart';

/// 결과 목록의 경로 한 줄 — 총 시간 · "환승 n · 도보 n분 · 요금" · 노선 칩.
class TransitPathTile extends StatelessWidget {
  const TransitPathTile({required this.path, required this.onTap, super.key});

  final TransitPath path;
  final VoidCallback onTap;

  /// `42분` · `1시간` · `1시간 15분`.
  static String total(AppLocalizations l10n, int minutes) => minutes < 60
      ? l10n.walkTransitTotal(minutes)
      : minutes % 60 == 0
      ? l10n.walkTransitTotalHoursOnly(minutes ~/ 60)
      : l10n.walkTransitTotalHours(minutes ~/ 60, minutes % 60);

  /// `환승 1 · 도보 9분 · 1,500원` — 요금을 모르면 뺀다.
  static String summary(AppLocalizations l10n, TransitPath path) {
    final fare = path.fare;
    return [
      l10n.walkTransitTransfers(path.transferCount),
      l10n.walkTransitWalk(path.walkMinutes),
      if (fare != null)
        l10n.walkTransitFare(
          NumberFormat.decimalPattern(l10n.localeName).format(fare),
        ),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rides = [
      for (final leg in path.legs)
        if (leg is! TransitWalkLeg) leg,
    ];
    return AppListTile(
      onTap: onTap,
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: AppSpacing.sm,
        children: [
          Text(
            total(l10n, path.totalMinutes),
            style: theme.textTheme.titleLarge,
          ),
          Text(
            summary(l10n, path),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: rides.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < rides.length; i++) ...[
                    if (i > 0)
                      Icon(
                        Icons.chevron_right,
                        size: theme.textTheme.bodyMedium?.fontSize,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    LineChip(leg: rides[i]),
                  ],
                ],
              ),
            ),
    );
  }
}
