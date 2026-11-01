import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_vendor.dart';
import 'chat_vendor_icon.dart';

/// 처음 쓰기 전 · 벤더를 바꾼 뒤 데이터 전송 안내와 [동의하고 시작](스펙 §5.3).
class ChatConsentView extends StatelessWidget {
  const ChatConsentView({
    required this.vendor,
    required this.continuing,
    required this.onAccept,
    super.key,
  });

  /// 보낼 곳 — 지금 연결된 벤더.
  final ChatVendor vendor;

  /// 이어 갈 대화가 있다 — 이전 내용도 [vendor] 로 간다는 한 줄을 더한다.
  final bool continuing;

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = chatVendorName(l10n, vendor);
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
              l10n.walkChatConsentNotice(name),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (continuing) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.walkChatConsentContinues(name),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
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
