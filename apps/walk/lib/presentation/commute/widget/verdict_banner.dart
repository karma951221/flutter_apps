import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/commute/entity/catch_verdict.dart';

/// 걸어서 열차를 탈 수 있는지 알리는 배너. 판단할 수 없으면 그리지 않는다.
class VerdictBanner extends StatelessWidget {
  const VerdictBanner({required this.verdict, super.key});

  final CatchVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (String text, IconData icon, Color background, Color foreground)?
    look = switch (verdict) {
      CatchFirst() => (
        l10n.walkCommuteVerdictCatchFirst,
        Icons.check_circle_outline,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      CatchSecond() => (
        l10n.walkCommuteVerdictCatchSecond,
        Icons.schedule,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      MissBoth() => (
        l10n.walkCommuteVerdictMissBoth,
        Icons.error_outline,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      CatchUnknown() => null,
    };
    if (look == null) return const SizedBox.shrink();
    final (text, icon, background, foreground) = look;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
