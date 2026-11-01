import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 말풍선 길게 누르기 시트에서 고를 수 있는 일.
enum BubbleAction { deleteTurn }

/// 말풍선 길게 누르기 시트. 고른 일을, 닫으면 null 을 돌려준다.
Future<BubbleAction?> showBubbleActions(BuildContext context) =>
    showModalBottomSheet<BubbleAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
