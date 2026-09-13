import 'package:flutter/material.dart';

import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';
import '../../domain/entity/transit_mode.dart';
import '../../domain/entity/transit_route.dart';
import '../format/commute_format.dart';

class TransitRouteCard extends StatelessWidget {
  const TransitRouteCard({required this.route, super.key});

  final TransitRoute route;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      key: Key('commute-route-card-${route.mode.name}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(route.mode)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    CommuteFormat.mode(l10n, route.mode),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  CommuteFormat.duration(l10n, route.duration),
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.commuteTransferCount(route.transferCount)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CommuteFormat.legs(route.legs),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(TransitMode mode) => switch (mode) {
    TransitMode.subway => Icons.subway_outlined,
    TransitMode.bus => Icons.directions_bus_outlined,
    TransitMode.best => Icons.star_outline,
  };
}
