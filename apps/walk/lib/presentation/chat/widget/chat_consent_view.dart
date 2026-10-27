import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 처음 쓰기 전 데이터 전송 안내와 [동의하고 시작].
class ChatConsentView extends StatelessWidget {
  const ChatConsentView({required this.onAccept, super.key});

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: AppSpacing.xl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.walkChatConsentNotice,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: l10n.walkChatConsentAccept,
              onPressed: onAccept,
            ),
          ],
        ),
      ),
    );
  }
}
