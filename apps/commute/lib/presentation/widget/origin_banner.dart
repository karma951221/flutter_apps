import 'package:flutter/material.dart';

import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';
import '../../domain/entity/commute_direction.dart';
import '../../domain/entity/origin.dart';

class OriginBanner extends StatelessWidget {
  const OriginBanner({
    required this.origin,
    required this.direction,
    super.key,
  });

  final Origin origin;
  final CommuteDirection direction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCurrentLocation = origin is CurrentLocationOrigin;
    final message = switch (origin) {
      CurrentLocationOrigin() => l10n.commuteCurrentLocationOrigin,
      FallbackStationOrigin() => switch (direction) {
        CommuteDirection.toWork => l10n.commuteHomeFallbackOrigin,
        CommuteDirection.toHome => l10n.commuteWorkFallbackOrigin,
      },
    };
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('commute-origin-banner'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentLocation
            ? scheme.primaryContainer
            : scheme.secondaryContainer,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Icon(
            isCurrentLocation ? Icons.my_location : Icons.location_off_outlined,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
