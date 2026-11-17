import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import 'chat_vendor_icon.dart';
import 'model_chip.dart';

/// 대화 설정 시트 본문: 모델(누르면 고르기 시트) · 내 기록 참고 스위치 · 물어보기 설정 바로가기.
///
/// [enabled] 가 false 면(답하는 중) 모델 · 스위치가 꺼진다. 물어보기 설정은 늘 열 수 있다.
class ChatSettingsSheet extends StatelessWidget {
  const ChatSettingsSheet({
    required this.model,
    required this.useRecords,
    required this.enabled,
    required this.onPickModel,
    required this.onUseRecordsChanged,
    required this.onOpenSettings,
    super.key,
  });

  final ModelChipData model;
  final bool useRecords;
  final bool enabled;
  final VoidCallback onPickModel;
  final ValueChanged<bool> onUseRecordsChanged;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vendorIcon = ChatVendorIcon(model.vendor);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l10n.walkChatQuickSettings,
              style: theme.textTheme.titleMedium,
            ),
          ),
          AppListTile(
            key: const Key('chat-settings-model'),
            enabled: enabled,
            leading: Badge(
              key: model.hasNewer ? const Key('chat-settings-model-dot') : null,
              isLabelVisible: model.hasNewer,
              child: model.hasNewer
                  ? Semantics(
                      label: l10n.walkChatModelNewerAvailable,
                      child: vendorIcon,
                    )
                  : vendorIcon,
            ),
            title: Text(l10n.walkChatModelRowTitle),
            subtitle: Row(
              children: [
                Flexible(
                  child: Text(
                    model.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (model.fastMode)
                  Icon(Icons.bolt, size: theme.textTheme.bodyMedium?.fontSize),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onPickModel,
          ),
          SwitchListTile(
            key: const Key('chat-settings-use-records'),
            secondary: Icon(
              useRecords ? Icons.auto_stories : Icons.auto_stories_outlined,
            ),
            title: Text(l10n.walkChatUseRecordsTitle),
            subtitle: Text(
              useRecords
                  ? l10n.walkChatUseRecordsOnHint
                  : l10n.walkChatUseRecordsOffHint,
            ),
            value: useRecords,
            onChanged: enabled ? onUseRecordsChanged : null,
          ),
          AppListTile(
            key: const Key('chat-settings-open'),
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.walkChatSettingsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenSettings,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
