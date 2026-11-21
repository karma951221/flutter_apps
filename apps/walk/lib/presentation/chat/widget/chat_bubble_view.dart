import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/attachment/chat_attachment.dart';
import '../../../domain/chat/usecase/chat_session.dart';
import '../../../domain/diary/entity/diary_entry.dart';
import '../cubit/chat_state.dart';
import 'answer_markdown.dart';
import 'chat_failure_text.dart';
import 'attachment_chip.dart';
import 'chat_progress_view.dart';
import 'cited_entry_chip.dart';

/// 말풍선 하나. 내 질문은 오른쪽, 답은 왼쪽. 질문은 고를 수 있는 평문, 답은 마크다운
/// ([AnswerMarkdown] — 표 · 코드 · ```svg 그림 · 작업 폴더 그림)으로 보이고 [SelectionArea] 로 고른다.
///
/// 답이 실패했으면 이미 받은 글 아래에 실패 문구, 멈췄으면 같은 자리에 '멈춤' 표시,
/// 인용 기록이 있으면 그 아래에 칩을 둔다. 키 · 크레딧 문제로 실패했고 [onOpenSettings] 가 있으면
/// 실패 문구 아래에 [설정 열기]를 둔다. [streaming] 이면 답 글 끝에 커서 `▍` 를 그린다.
/// 답에 진행([ChatBubble.progress])이 있으면 말풍선 위에 진행 줄 · 접힌 요약을 둔다(스펙 §3.2).
class ChatBubbleView extends StatelessWidget {
  const ChatBubbleView({
    required this.bubble,
    required this.onOpenCited,
    this.pending = false,
    this.onOpenSettings,
    this.onLongPress,
    this.streaming = false,
    this.attachmentExists,
    this.onOpenAttachment,
    this.readImage,
    super.key,
  });

  final ChatBubble bubble;

  /// 인용 칩을 눌렀다 — 칩 목록 전체와 누른 기록.
  final void Function(List<DiaryEntry> cited, DiaryEntry entry) onOpenCited;

  /// 아직 글이 오지 않은 답(받는 중).
  final bool pending;

  /// 실패 말풍선의 [설정 열기] — 셸이 물어보기 설정 화면을 연다. null 이면 버튼이 없다.
  final VoidCallback? onOpenSettings;

  /// 말풍선을 길게 눌렀다(턴 지우기 시트). null 이면 길게 누르기를 받지 않는다.
  final VoidCallback? onLongPress;

  /// 답 글이 흐르는 중 — 글 끝에 커서를 둔다.
  final bool streaming;

  /// 첨부가 작업 폴더에 있는지. null 이면 칩은 표시만 한다(눌리지 않고 확인하지 않는다).
  /// 있으면 경로가 있는 첨부만 묻고, 없는 파일 · 확인 실패는 회색 '지운 파일'.
  /// 경로가 없는 첨부(임시 대화 · 사본 실패)는 늘 표시만.
  final Future<bool> Function(String path)? attachmentExists;

  /// 있는 첨부 칩 · 답의 그림을 눌렀다 — 작업 폴더 상대 경로.
  final ValueChanged<String>? onOpenAttachment;

  /// 답 글의 작업 폴더 그림(`![…](out/…)`)을 읽는다. null 이면 그림 대신 설명 글.
  final Future<Uint8List?> Function(String path)? readImage;

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
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: mine ? scheme.onPrimaryContainer : scheme.onSurface,
    );
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
            if (bubble.progress case final progress? when !mine) ...[
              ChatProgressView(progress: progress),
              const SizedBox(height: AppSpacing.xs),
            ],
            // 질문에 붙인 파일 — 질문 글 위(보낸 순서와 같게).
            if (mine && bubble.attachments.isNotEmpty) ...[
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final (i, a) in bubble.attachments.indexed)
                    // 작업 폴더 경로가 없는 첨부(임시 대화 · 사본 실패)는 표시만.
                    switch ((attachmentExists, a.workspacePath)) {
                      (final exists?, final path?) => _WorkspaceChip(
                        key: ValueKey('bubble-attachment-$i'),
                        attachment: a,
                        path: path,
                        exists: exists,
                        onOpen: onOpenAttachment,
                      ),
                      _ => AttachmentChip.of(
                        a,
                        key: ValueKey('bubble-attachment-$i'),
                      ),
                    },
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            if (text.isNotEmpty || failure != null || stopped)
              GestureDetector(
                onLongPress: onLongPress,
                child: DecoratedBox(
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
                        if (text.isNotEmpty && (mine || bubble.text.isEmpty))
                          SelectableText(
                            text,
                            style: bodyStyle,
                            contextMenuBuilder: onLongPress == null
                                ? _defaultMenu
                                : (context, state) => _menuWithMore(
                                    state.contextMenuAnchors,
                                    state.contextMenuButtonItems,
                                    state.hideToolbar,
                                    l10n.commonMoreActions,
                                  ),
                          )
                        else if (text.isNotEmpty)
                          SelectionArea(
                            contextMenuBuilder: (context, state) =>
                                onLongPress == null
                                ? AdaptiveTextSelectionToolbar.selectableRegion(
                                    selectableRegionState: state,
                                  )
                                : _menuWithMore(
                                    state.contextMenuAnchors,
                                    state.contextMenuButtonItems,
                                    state.hideToolbar,
                                    l10n.commonMoreActions,
                                  ),
                            child: AnswerMarkdown(
                              text: text,
                              style: bodyStyle,
                              streaming: streaming,
                              readImage: readImage,
                              onOpenImage: onOpenAttachment,
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

  static Widget _defaultMenu(BuildContext context, EditableTextState state) =>
      AdaptiveTextSelectionToolbar.editableText(editableTextState: state);

  /// 글을 길게 누르면 글 고르기가 이긴다 — 고르기 메뉴 끝의 [더보기]가 [onLongPress] 를 대신한다.
  /// 질문([SelectableText]) · 답([SelectionArea]) 이 같이 쓴다.
  Widget _menuWithMore(
    TextSelectionToolbarAnchors anchors,
    List<ContextMenuButtonItem> items,
    void Function() hideToolbar,
    String label,
  ) => AdaptiveTextSelectionToolbar.buttonItems(
    anchors: anchors,
    buttonItems: [
      ...items,
      ContextMenuButtonItem(
        label: label,
        onPressed: () {
          hideToolbar();
          onLongPress?.call();
        },
      ),
    ],
  );
}

/// 말풍선의 첨부 칩 — 작업 폴더에 있는지 한 번 묻고, 없으면 회색 '지운 파일'.
/// 묻는 동안은 보통 칩으로 그리되 누르지 않는다. 경로가 있는 첨부에만 쓴다.
class _WorkspaceChip extends StatefulWidget {
  const _WorkspaceChip({
    required this.attachment,
    required this.path,
    required this.exists,
    required this.onOpen,
    super.key,
  });

  final ChatAttachmentRef attachment;

  /// [attachment] 의 작업 폴더 상대 경로.
  final String path;
  final Future<bool> Function(String path) exists;
  final ValueChanged<String>? onOpen;

  @override
  State<_WorkspaceChip> createState() => _WorkspaceChipState();
}

class _WorkspaceChipState extends State<_WorkspaceChip> {
  late Future<bool> _there;

  @override
  void initState() {
    super.initState();
    _there = _check();
  }

  @override
  void didUpdateWidget(_WorkspaceChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _there = _check();
    }
  }

  /// 묻다 실패하면(경계 밖 등) 없는 것으로 본다.
  Future<bool> _check() async {
    try {
      return await widget.exists(widget.path);
    } on Object {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _there,
    builder: (context, snapshot) {
      final open = widget.onOpen;
      return AttachmentChip.of(
        widget.attachment,
        missing: snapshot.data == false,
        onTap: snapshot.data == true && open != null
            ? () => open(widget.path)
            : null,
      );
    },
  );
}
