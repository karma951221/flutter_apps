import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/diary/entity/diary_entry.dart';
import '../cubit/chat_state.dart';
import 'chat_failure_text.dart';
import 'cited_entry_chip.dart';

/// 말풍선 하나. 내 질문은 오른쪽, 답은 왼쪽. 글은 마크다운 없이 고를 수 있는 평문으로 보인다.
///
/// 답이 실패했으면 이미 받은 글 아래에 실패 문구, 멈췄으면 같은 자리에 '멈춤' 표시,
/// 인용 기록이 있으면 그 아래에 칩을 둔다. 키 · 크레딧 문제로 실패했고 [onOpenSettings] 가 있으면
/// 실패 문구 아래에 [설정 열기]를 둔다.
class ChatBubbleView extends StatelessWidget {
  const ChatBubbleView({
    required this.bubble,
    required this.onOpenCited,
    this.pending = false,
    this.onOpenSettings,
    super.key,
  });

  final ChatBubble bubble;

  /// 인용 칩을 눌렀다 — 칩 목록 전체와 누른 기록.
  final void Function(List<DiaryEntry> cited, DiaryEntry entry) onOpenCited;

  /// 아직 글이 오지 않은 답(받는 중).
  final bool pending;

  /// 실패 말풍선의 [설정 열기] — 셸이 물어보기 설정 화면을 연다. null 이면 버튼이 없다.
  final VoidCallback? onOpenSettings;

  /// 설정에서 고칠 수 있는 실패 — 키 없음 · 잘못된 키 · 크레딧 부족.
  static const _settingsFailures = {
    ChatFailure.noKey,
    ChatFailure.invalidKey,
    ChatFailure.quotaExceeded,
  };

  /// 말풍선 최대 너비(화면 너비 대비).
  static const _maxWidthFactor = 0.85;

  /// 아직 글이 오지 않은 답 자리.
  static const _pendingText = '…';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mine = bubble.role == ChatRole.user;
    final failure = bubble.failure;
    final stopped = bubble.stopped;
    final noteStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final text = bubble.text.isEmpty && pending ? _pendingText : bubble.text;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFactor,
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (text.isNotEmpty || failure != null || stopped)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: mine
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHigh,
                  borderRadius: AppRadius.lgAll,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (text.isNotEmpty)
                        SelectableText(
                          text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: mine
                                ? scheme.onPrimaryContainer
                                : scheme.onSurface,
                          ),
                        ),
                      if (text.isNotEmpty && failure != null)
                        const SizedBox(height: AppSpacing.xs),
                      if (failure != null)
                        Text(
                          chatFailureText(l10n, failure),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      if (failure != null &&
                          onOpenSettings != null &&
                          _settingsFailures.contains(failure)) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppButton.text(
                          key: const Key('chat-bubble-open-settings'),
                          label: l10n.walkChatOpenSettings,
                          onPressed: onOpenSettings,
                        ),
                      ],
                      if (stopped) ...[
                        if (text.isNotEmpty || failure != null)
                          const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stop_circle_outlined,
                              size: noteStyle?.fontSize,
                              color: noteStyle?.color,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(l10n.walkChatStopped, style: noteStyle),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (bubble.cited.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final entry in bubble.cited)
                    CitedEntryChip(
                      key: ValueKey('cited-${entry.id}'),
                      entry: entry,
                      onOpen: () => onOpenCited(bubble.cited, entry),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
