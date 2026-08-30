import 'package:flutter/material.dart';

import '../../../../core/extension/date_time_format.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_list_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entity/chat_message.dart';
import '../../domain/entity/chat_room_summary.dart';

/// 채팅 탭 목록의 한 줄.
///
/// 마지막 메시지 미리보기는 서버가 문장으로 주지 않는다 — 시스템 메시지는
/// 키와 행위자 닉네임만 오므로 문장을 여기서 만든다.
class ChatRoomTile extends StatelessWidget {
  const ChatRoomTile({required this.room, required this.onTap, super.key});

  final ChatRoomSummary room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return AppListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        child: Icon(Icons.forum_outlined, color: scheme.onSecondaryContainer),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              // TODO(task-4): direct 방 표시는 Task 4 가 담당한다. 여기서는
              // ChatRoomSummary.title 이 String? 로 바뀐 것만 기계적으로
              // null-safe 하게 통과시킨다.
              room.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.chatMemberCount(room.memberCount),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: Text(
        _preview(l10n),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (room.lastMessageAt != null)
            Text(
              room.lastMessageAt!.displayShortDateTime(l10n.localeName),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (room.hasUnread) ...[
            const SizedBox(height: AppSpacing.xs),
            _UnreadBadge(count: room.unreadCount),
          ],
        ],
      ),
    );
  }

  String _preview(AppLocalizations l10n) {
    if (room.lastMessageAt == null) return l10n.chatNoMessagesYet;

    return switch (room.lastMessageType) {
      ChatMessageType.image => l10n.chatLastMessageImage,
      ChatMessageType.system => switch (room.lastMessageSystemEvent) {
        ChatSystemEvent.join => l10n.chatSystemJoined(
          room.lastMessageContent ?? '',
        ),
        ChatSystemEvent.leave => l10n.chatSystemLeft(
          room.lastMessageContent ?? '',
        ),
        null => '',
      },
      _ => room.lastMessageContent ?? '',
    };
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 세 자리를 넘어가면 배지가 줄을 밀어낸다. 카카오톡과 같은 방식으로 자른다.
    final label = count > 999 ? '999+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: scheme.onError),
      ),
    );
  }
}
