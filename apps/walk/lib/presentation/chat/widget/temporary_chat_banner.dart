import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_vendor.dart';
import 'chat_vendor_icon.dart';

/// 임시 대화 중 입력칸 위 한 줄 배너 — 저장되지 않지만 [vendor] 에는 전송된다는 안내.
class TemporaryChatBanner extends StatelessWidget {
  const TemporaryChatBanner({required this.vendor, super.key});

  final ChatVendor vendor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBanner(
      key: const Key('chat-temporary-banner'),
      icon: Icons.visibility_off_outlined,
      // 보관 정책을 정하는 쪽 — 제품 이름이 아니라 회사 이름.
      message: l10n.walkChatTemporaryBanner(chatVendorCompany(l10n, vendor)),
    );
  }
}
