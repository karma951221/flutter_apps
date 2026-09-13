import 'package:flutter/material.dart';

import 'package:l10n/l10n.dart';
import '../../domain/entity/commute_direction.dart';

class DirectionToggle extends StatelessWidget {
  const DirectionToggle({
    required this.direction,
    required this.onChanged,
    super.key,
  });

  final CommuteDirection direction;
  final ValueChanged<CommuteDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<CommuteDirection>(
      key: const Key('commute-direction-toggle'),
      segments: [
        ButtonSegment(
          value: CommuteDirection.toWork,
          icon: const Icon(Icons.business_center_outlined),
          label: Text(l10n.commuteDirectionToWork),
        ),
        ButtonSegment(
          value: CommuteDirection.toHome,
          icon: const Icon(Icons.home_outlined),
          label: Text(l10n.commuteDirectionToHome),
        ),
      ],
      selected: {direction},
      onSelectionChanged: (selected) => onChanged(selected.single),
    );
  }
}
