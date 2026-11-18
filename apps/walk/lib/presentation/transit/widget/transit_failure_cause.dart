import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 실패 원인 원문(예외 타입 · HTTP 상태 · ODsay code · msg). 길게 눌러 선택 · 복사할 수
/// 있어 실사용 중 원인을 그대로 옮겨 적을 수 있다. 키 값은 만드는 쪽에서 가린다.
class TransitFailureCause extends StatelessWidget {
  const TransitFailureCause(this.detail, {super.key});

  final String detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const Key('transit-failure-cause'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.smAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.walkTransitFailureCause,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(detail, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
