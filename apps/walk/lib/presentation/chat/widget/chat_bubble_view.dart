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
/// 실패 문구 아래에 [설정 열기]를 둔다. [streaming] 이면 글 끝에 커서 `▍` 가 깜빡인다.
class ChatBubbleView extends StatelessWidget {
  const ChatBubbleView({
    required this.bubble,
    required this.onOpenCited,
    this.pending = false,
    this.onOpenSettings,
    this.onLongPress,
    this.streaming = false,
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
                        if (text.isNotEmpty)
                          _withCursor(
                            text: text,
                            style: bodyStyle,
                            child: SelectableText(
                              text,
                              style: bodyStyle,
                              contextMenuBuilder: onLongPress == null
                                  ? _defaultMenu
                                  : (context, state) => _menuWithMore(
                                      state,
                                      l10n.commonMoreActions,
                                    ),
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

  /// 흐르는 중이고 받은 글이 있으면(자리 표시 `…` 가 아니면) 글 위에 커서를 겹친다.
  Widget _withCursor({
    required String text,
    required TextStyle? style,
    required Widget child,
  }) {
    if (!streaming || bubble.text.isEmpty) return child;
    return Stack(
      children: [
        child,
        IgnorePointer(
          child: ExcludeSemantics(
            child: _StreamingCursor(text: text, style: style),
          ),
        ),
      ],
    );
  }

  static Widget _defaultMenu(BuildContext context, EditableTextState state) =>
      AdaptiveTextSelectionToolbar.editableText(editableTextState: state);

  /// 글을 길게 누르면 글 고르기가 이긴다 — 고르기 메뉴 끝의 [더보기]가 [onLongPress] 를 대신한다.
  Widget _menuWithMore(EditableTextState state, String label) =>
      AdaptiveTextSelectionToolbar.buttonItems(
        anchors: state.contextMenuAnchors,
        buttonItems: [
          ...state.contextMenuButtonItems,
          ContextMenuButtonItem(
            label: label,
            onPressed: () {
              state.hideToolbar();
              onLongPress?.call();
            },
          ),
        ],
      );
}

/// 글 끝 커서. 커서는 [SelectableText] 의 글에 넣지 않는다 — 복사하면 딸려 오지 않게,
/// 같은 글을 투명하게 깐 [Text.rich] 의 별도 span 으로 글 끝 자리에 그린다.
/// 깜빡임은 [AppMotion.long] 주기, '애니메이션 줄이기'면 고정.
class _StreamingCursor extends StatefulWidget {
  const _StreamingCursor({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: AppMotion.long,
    value: 1,
  );

  /// 커서 글자. 앞의 폭 없는 빈칸은 마지막 낱말과 커서 사이 줄바꿈을 허락해
  /// 투명 글의 줄바꿈이 [SelectableText] 와 같게 한다.
  static const _cursor = '\u200B▍';

  /// [SelectableText] 가 오른쪽에 비워 두는 캐럿 자리. Flutter 의
  /// `RenderEditable._caretMargin`(= `_kCaretGap` 1 + `cursorWidth`, [SelectableText] 기본 2)과
  /// 같아야 한다 — 같은 너비로 줄을 나눠야 커서가 글 끝에 붙는다. 테스트가 양쪽(더 작음 · 더 큼)을 잡는다.
  static const _caretMargin = 3.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.enabled(context)) {
      if (!_blink.isAnimating) _blink.repeat(reverse: true);
    } else {
      _blink
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.style?.color;
    return FadeTransition(
      opacity: _blink,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: _caretMargin),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: widget.text,
                style: TextStyle(color: color?.withAlpha(0)),
              ),
              TextSpan(
                text: _cursor,
                style: TextStyle(color: color),
              ),
            ],
          ),
          style: widget.style,
          // EditableText 처럼 글꼴 strut 을 둬 줄 높이를 [SelectableText] 와 맞춘다.
          strutStyle: widget.style == null
              ? null
              : StrutStyle.fromTextStyle(widget.style!),
        ),
      ),
    );
  }
}
