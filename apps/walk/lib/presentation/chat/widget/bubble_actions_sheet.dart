import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 말풍선 길게 누르기 시트에서 고를 수 있는 일.
enum BubbleAction { addToWiki, deleteTurn }

/// 말풍선 길게 누르기 시트. 고른 일을, 닫으면 null 을 돌려준다.
/// [canAddToWiki] 면 [위키에 추가]도 보인다(임시 대화 · 실패 · 빈 말풍선은 끔).
Future<BubbleAction?> showBubbleActions(
  BuildContext context, {
  bool canAddToWiki = false,
}) => showModalBottomSheet<BubbleAction>(
  context: context,
  showDragHandle: true,
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canAddToWiki)
            AppListTile(
              key: const Key('chat-bubble-action-wiki'),
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.walkChatWikiAddFromBubble),
              onTap: () => Navigator.pop(context, BubbleAction.addToWiki),
            ),
          AppListTile(
            key: const Key('chat-bubble-action-delete'),
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.walkChatTurnDelete),
            onTap: () => Navigator.pop(context, BubbleAction.deleteTurn),
          ),
        ],
      ),
    );
  },
);
