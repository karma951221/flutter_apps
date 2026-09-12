import 'package:flutter/material.dart';

import 'package:l10n/l10n.dart';
import '../theme/app_spacing.dart';

/// 페이지 목록의 맨 끝에 붙는 공통 상태 줄.
class AppListFooter extends StatelessWidget {
  const AppListFooter({
    required this.isLoadingMore,
    required this.canLoadMore,
    super.key,
  });

  final bool isLoadingMore;

  /// 다음 커서가 남아 있는지. 없으면 마지막 페이지까지 읽었다는 뜻이다.
  final bool canLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (canLoadMore) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Center(
        child: Text(
          AppLocalizations.of(context).feedEndOfList,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
