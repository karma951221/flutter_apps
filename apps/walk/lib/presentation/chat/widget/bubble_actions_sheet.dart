import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../common/row_actions_sheet.dart';

/// 말풍선 길게 누르기 시트에서 고를 수 있는 일.
enum BubbleAction { copyText, addToWiki, saveToFile, deleteTurn }

/// 말풍선 길게 누르기 시트. 고른 일을, 닫으면 null 을 돌려준다.
/// [canAddToWiki] 면 [위키에 추가]도 보인다(임시 대화 · 실패 · 빈 말풍선은 끔).
/// [canSaveToFile] 면 [파일로 저장]도 보인다(글이 있는 답 말풍선 — 임시 대화도 된다).
/// [canCopy] 면 맨 위에 [글 복사](원문 그대로 — 답의 마크다운 기호 포함).
Future<BubbleAction?> showBubbleActions(
  BuildContext context, {
  bool canCopy = false,
  bool canAddToWiki = false,
  bool canSaveToFile = false,
}) {
  final l10n = AppLocalizations.of(context);
  return showRowActions<BubbleAction>(
    context,
    // 말풍선에는 이름이 없다 — 머리 없이 동작만.
    title: null,
    actions: [
      if (canCopy)
        RowAction(
          key: const Key('chat-bubble-action-copy'),
          value: BubbleAction.copyText,
          label: l10n.walkChatCopyText,
          icon: Icons.content_copy_outlined,
        ),
      if (canAddToWiki)
        RowAction(
          key: const Key('chat-bubble-action-wiki'),
          value: BubbleAction.addToWiki,
          label: l10n.walkChatWikiAddFromBubble,
          icon: Icons.menu_book_outlined,
        ),
      if (canSaveToFile)
        RowAction(
          key: const Key('chat-bubble-action-save'),
          value: BubbleAction.saveToFile,
          label: l10n.walkChatSaveToFile,
          icon: Icons.save_alt_outlined,
        ),
      RowAction(
        key: const Key('chat-bubble-action-delete'),
        value: BubbleAction.deleteTurn,
        label: l10n.walkChatTurnDelete,
        icon: Icons.delete_outline,
        isDestructive: true,
      ),
    ],
  );
}
