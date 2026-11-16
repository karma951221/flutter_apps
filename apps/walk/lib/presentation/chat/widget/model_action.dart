import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'chat_vendor_icon.dart';
import 'model_chip.dart';

/// 물어보기 앱바의 모델 버튼: 벤더 아이콘. 툴팁에 지금 모델 이름이 있고, 누르면 고르기 시트.
/// 안 본 새 모델이 있으면 아이콘 오른쪽 위에 점.
class ModelAction extends StatelessWidget {
  const ModelAction({required this.data, required this.onPressed, super.key});

  final ModelChipData data;

  /// null 이면 비활성(답을 받는 중).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      key: const Key('chat-model-action'),
      tooltip: l10n.walkChatModelActionTooltip(data.label),
      onPressed: onPressed,
      icon: Badge(
        key: data.hasNewer ? const Key('chat-model-action-dot') : null,
        isLabelVisible: data.hasNewer,
        child: data.hasNewer
            ? Semantics(
                label: l10n.walkChatModelNewerAvailable,
                child: ChatVendorIcon(data.vendor),
              )
            : ChatVendorIcon(data.vendor),
      ),
    );
  }
}
