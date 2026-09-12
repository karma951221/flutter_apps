import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/failure_localizations.dart';
import '../../../../design_system/theme/app_spacing.dart';

class FailureText extends StatelessWidget {
  const FailureText(this.failure, {super.key});

  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final f = failure;
    if (f == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        f.localizedMessage(context),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
