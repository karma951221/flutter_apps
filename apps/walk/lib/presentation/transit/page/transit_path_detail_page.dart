import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/transit/entity/transit_path.dart';
import '../widget/leg_timeline.dart';
import '../widget/transit_path_tile.dart';

/// 경로 상세 — 맨 위 총 시간 · 환승 · 도보 · 요금, 아래 구간 타임라인.
class TransitPathDetailPage extends StatelessWidget {
  const TransitPathDetailPage({required this.path, super.key});

  final TransitPath path;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkTransitDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            TransitPathTile.total(l10n, path.totalMinutes),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            TransitPathTile.summary(l10n, path),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          LegTimeline(legs: path.legs),
        ],
      ),
    );
  }
}
