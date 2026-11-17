import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 물어보기 앱바의 [대화 설정] 버튼: 누르면 대화 설정 시트(모델 · 내 기록 참고 · 물어보기 설정).
/// 안 본 새 모델이 있으면 아이콘 오른쪽 위에 점.
class ChatSettingsAction extends StatelessWidget {
  const ChatSettingsAction({
    required this.hasNewer,
    required this.onPressed,
    super.key = const Key('chat-settings-action'),
  });

  final bool hasNewer;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const icon = Icon(Icons.tune);
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
