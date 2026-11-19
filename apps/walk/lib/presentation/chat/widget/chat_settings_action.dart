import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_vendor.dart';
import 'chat_vendor_icon.dart';

/// 물어보기 앱바의 [대화 설정] 버튼: 누르면 대화 설정 시트(모델 · 내 기록 참고 · 물어보기 설정).
/// 아이콘은 지금 답하는 모델의 벤더 로고 — 조절 막대(tune)보다 '이 AI 를 바꾸고 고른다'가
/// 바로 읽힌다. 안 본 새 모델이 있으면 아이콘 오른쪽 위에 점.
class ChatSettingsAction extends StatelessWidget {
  const ChatSettingsAction({
    required this.vendor,
    required this.hasNewer,
    required this.onPressed,
    super.key = const Key('chat-settings-action'),
  });

  final ChatVendor vendor;
  final bool hasNewer;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final icon = ChatVendorIcon(vendor);
    return IconButton(
      tooltip: l10n.walkChatQuickSettings,
      onPressed: onPressed,
      icon: Badge(
        key: hasNewer ? const Key('chat-settings-action-dot') : null,
        isLabelVisible: hasNewer,
        child: hasNewer
            ? Semantics(label: l10n.walkChatModelNewerAvailable, child: icon)
            : icon,
      ),
    );
  }
}
