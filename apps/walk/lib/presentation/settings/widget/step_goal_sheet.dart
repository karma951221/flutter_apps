import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/walk/entity/step_goal.dart';
import '../../walk/format/walk_format.dart';

/// 하루 걸음 목표를 슬라이더로 고르는 바텀시트. 저장하면 고른 값을, 닫으면 null 을 돌려준다.
class StepGoalSheet extends StatefulWidget {
  const StepGoalSheet({required this.initial, super.key});

  final int initial;

  static Future<int?> show(BuildContext context, {required int initial}) =>
      showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => StepGoalSheet(initial: initial),
      );

  @override
  State<StepGoalSheet> createState() => _StepGoalSheetState();
}

class _StepGoalSheetState extends State<StepGoalSheet> {
  late int _value = StepGoal.clamp(widget.initial);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.walkSettingsStepGoal, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.walkStepsCount(WalkFormat.steps(locale, _value)),
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            Slider(
              key: const Key('step-goal-slider'),
              min: StepGoal.min.toDouble(),
              max: StepGoal.max.toDouble(),
              divisions: (StepGoal.max - StepGoal.min) ~/ StepGoal.step,
              value: _value.toDouble(),
              onChanged: (v) {
                final next = StepGoal.clamp(v.round());
                if (next == _value) return;
                HapticFeedback.selectionClick();
                setState(() => _value = next);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                key: const Key('step-goal-save'),
                label: l10n.walkSettingsStepGoalSave,
                onPressed: () => Navigator.pop(context, _value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
