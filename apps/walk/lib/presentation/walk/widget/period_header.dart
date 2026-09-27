import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/walk/entity/activity_period.dart';
import '../../../domain/walk/entity/period_kind.dart';
import '../format/walk_format.dart';

class PeriodHeader extends StatelessWidget {
  const PeriodHeader({
    required this.period,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final ActivityPeriod period;
  final VoidCallback onPrevious;

  /// null 이면 다음 버튼을 끈다(현재 기간).
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final title = switch (period.kind) {
      PeriodKind.week => WalkFormat.weekRange(locale, period.start, period.end),
      PeriodKind.month => WalkFormat.month(locale, period.start),
    };

    return Row(
      children: [
        IconButton(
          key: const Key('walk-period-previous'),
          tooltip: l10n.walkPreviousPeriod,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: const Key('walk-period-next'),
          tooltip: l10n.walkNextPeriod,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
