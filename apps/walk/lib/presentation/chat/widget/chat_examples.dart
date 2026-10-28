import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 대화가 비었을 때: 안내 한 줄 + 예시 질문 칩 3개. 누르면 바로 보낸다.
class ChatExamples extends StatelessWidget {
  const ChatExamples({required this.onAsk, super.key});

  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final questions = [
      l10n.walkChatExampleYesterday,
      l10n.walkChatExampleAte,
      l10n.walkChatExampleWake,
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: AppSpacing.xl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.walkChatEmptyPrompt,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final q in questions)
                  ActionChip(label: Text(q), onPressed: () => onAsk(q)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
