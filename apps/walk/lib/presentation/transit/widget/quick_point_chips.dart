import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/transit/entity/transit_point.dart';
import '../../../domain/transit/usecase/transit_point_suggestions.dart';
import 'point_fields.dart';

/// 빠른 칩 — 집 · 회사 · 자주 간 곳 상위 3. 누르면 [onSelected].
class QuickPointChips extends StatelessWidget {
  const QuickPointChips({
    required this.suggestions,
    required this.onSelected,
    super.key,
  });

  final TransitSuggestions suggestions;
  final ValueChanged<TransitPoint> onSelected;

  static const frequentCount = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = suggestions.home;
    final work = suggestions.work;
    final chips = <(IconData, String, TransitPoint)>[
      if (home != null) (Icons.home_outlined, l10n.walkTransitHome, home),
      if (work != null) (Icons.work_outline, l10n.walkTransitWork, work),
      for (final p in suggestions.frequent.take(frequentCount))
        (Icons.star_outline, transitPointLabel(l10n, p), p),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (final (icon, label, point) in chips)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: ActionChip(
                avatar: Icon(icon),
                label: Text(label),
                onPressed: () => onSelected(point),
              ),
            ),
        ],
      ),
    );
  }
}
