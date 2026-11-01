import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_vendor.dart';
import '../../chat/widget/chat_vendor_icon.dart';

/// MVP 벤더(Claude · GPT)만. Grok 없음(Q12).
const chatVendorChoices = [ChatVendor.anthropic, ChatVendor.openai];

/// 벤더 고르기 시트(스펙 §5.1) — 로고 · 이름 · 회사 한 줄.
class VendorPickerSheet extends StatelessWidget {
  const VendorPickerSheet._({this.current});

  /// 지금 연결된 벤더. 체크 표시하고 누를 수 없다.
  final ChatVendor? current;

  /// 고른 벤더, 닫으면 null. [current] 는 체크 · 비활성.
  static Future<ChatVendor?> show(BuildContext context, {ChatVendor? current}) =>
      showModalBottomSheet<ChatVendor>(
        context: context,
        showDragHandle: true,
        builder: (_) => VendorPickerSheet._(current: current),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              l10n.walkChatVendorSheetTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          for (final vendor in chatVendorChoices)
            AppListTile(
              key: Key('vendor-row-${vendor.name}'),
              leading: ChatVendorIcon(vendor),
              title: Text(chatVendorName(l10n, vendor)),
              subtitle: Text(chatVendorCompany(l10n, vendor)),
              trailing: vendor == current
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: vendor == current
                  ? null
                  : () => Navigator.pop(context, vendor),
            ),
        ],
      ),
    );
  }
}
