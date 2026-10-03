import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../domain/entity/walk_session.dart';
import 'walk_stats_row.dart';

/// 피드 맨 위의 추적 상태 배너. 추적 중이면 통계를, 저장 전이면 안내 문구만 보인다.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = this.session;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Material(
        key: const Key('walk-feed-banner'),
        color: scheme.primaryContainer,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          borderRadius: AppRadius.lgAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  unsaved ? l10n.walkUnsavedBanner : l10n.walkInProgressBanner,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                if (session != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  WalkStatsRow(
                    distanceMeters: session.distanceMeters,
                    elapsed: elapsed,
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
