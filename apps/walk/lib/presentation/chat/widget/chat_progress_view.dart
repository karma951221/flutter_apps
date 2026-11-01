import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../cubit/chat_progress.dart';
import 'chat_progress_text.dart';

/// 답 말풍선 위 진행 줄(스펙 §3.2).
///
/// 진행 중이면 `◌ 지금 단계 · N초`(경과 초는 3초부터), 끝나면 접힌 요약 한 줄 `▸ 요약` —
/// 누르면 `▾` 와 단계 목록이 펼쳐진다. 펼침 상태는 이 위젯의 화면 상태다(저장 안 함, Q4).
///
/// 접근성: 단계 문구는 liveRegion 이지만 라벨은 단계 종류가 바뀔 때만 바꾼다 — 노트가
/// 자라거나 이어져도 처음 라벨 그대로, 경과 초는 읽지 않는다(R13).
/// '애니메이션 줄이기'면 전환은 모두 [Duration.zero], 스피너 대신 정지 아이콘.
class ChatProgressView extends StatefulWidget {
  const ChatProgressView({required this.progress, super.key});

  final ChatProgress progress;

  /// 진행 중 단계 문구의 liveRegion 노드.
  static const liveRegionKey = Key('chat-progress-live');

  @override
  State<ChatProgressView> createState() => _ChatProgressViewState();
}

class _ChatProgressViewState extends State<ChatProgressView> {
  /// 펼친 단계 목록이 보이는가.
  bool _expanded = false;

  /// liveRegion 이 마지막으로 알린 단계 — 단계 단위([_unitOf])가 바뀔 때만 바꾼다(R13).
  late ChatProgressStep _announced = _currentOf(widget.progress);

  /// 접힌 요약 화살표.
  static const _collapsedMark = '▸';
  static const _expandedMark = '▾';

  /// 목록 항목 머리.
  static const _bullet = '·';

  /// 스피너 굵기 — 글자 크기 대비.
  static const _strokeRatio = 0.12;

  @override
  void didUpdateWidget(ChatProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _currentOf(widget.progress);
    if (_unitOf(current) != _unitOf(_announced)) _announced = current;
  }

  static ChatProgressStep _currentOf(ChatProgress progress) =>
      progress.current ?? const ChatProgressStep.sending();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.bodySmall?.copyWith(color: color);
    final size = style?.fontSize ?? IconTheme.of(context).size;
    final motion = AppMotion.enabled(context);
    final progress = widget.progress;

    return DefaultTextStyle.merge(
      style: style,
      child: IconTheme.merge(
        data: IconThemeData(size: size, color: color),
        child: AnimatedSize(
          duration: motion ? AppMotion.medium : Duration.zero,
          curve: AppMotion.standard,
          alignment: AlignmentDirectional.topStart,
          child: progress.running
              ? _running(l10n, progress, motion, size, color)
              : _finished(l10n, progress),
        ),
      ),
    );
  }

  Widget _running(
    AppLocalizations l10n,
    ChatProgress progress,
    bool motion,
    double? size,
    Color color,
  ) {
    final step = _currentOf(progress);
    final text = chatProgressStepText(l10n, l10n.localeName, step);
    // 노트는 글자 단위로 자란다 — 반쪽 문장을 읽지 않게 고정 문구로 알린다(스펙 §3.5).
    final announced = switch (_announced) {
      StepNote() => l10n.walkChatPhaseThinking,
      final other => chatProgressStepText(l10n, l10n.localeName, other),
    };
    return Row(
      key: const ValueKey('running'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (motion)
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              strokeWidth:
                  (size ?? IconTheme.of(context).size ?? 0) * _strokeRatio,
              color: color,
            ),
          )
        else
          const Icon(Icons.more_horiz),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Semantics(
            key: ChatProgressView.liveRegionKey,
            container: true,
            liveRegion: true,
            label: announced,
            child: ExcludeSemantics(
              child: AnimatedSwitcher(
                duration: motion ? AppMotion.short : Duration.zero,
                switchInCurve: AppMotion.standard,
                switchOutCurve: AppMotion.standard,
                layoutBuilder: (current, previous) => Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [...previous, ?current],
                ),
                // 단계 단위로 키를 준다 — 같은 노트가 자라면 제자리에서 바뀌고,
                // 단위가 바뀔 때만 페이드한다.
                child: Text(
                  text,
                  key: ValueKey(_unitOf(step)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        if (progress.elapsedSeconds >= ChatProgress.elapsedVisibleFrom)
          ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: AppSpacing.xs),
                const Text(_bullet),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.walkChatProgressElapsed(progress.elapsedSeconds)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _finished(AppLocalizations l10n, ChatProgress progress) {
    final locale = l10n.localeName;
    final summary = chatProgressSummaryText(l10n, progress);
    return Column(
      key: const ValueKey('finished'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          onTapHint: _expanded ? null : l10n.walkChatProgressExpand,
          child: InkWell(
            borderRadius: AppRadius.smAll,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Text(_expanded ? _expandedMark : _collapsedMark),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (progress.stopped) ...[
                    const Icon(Icons.stop_circle_outlined),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(child: Text(summary)),
                ],
              ),
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final step in progress.steps)
                  if (step is! StepSending && step is! StepThinking)
                    Text(
                      '$_bullet ${chatProgressTimelineText(l10n, locale, step)}',
                    ),
              ],
            ),
          ),
      ],
    );
  }

  /// 단계 단위 — liveRegion 라벨 · 문구 전환 키. 노트는 이어지거나 자라도 한 단위, 도구는 호출마다.
  static String _unitOf(ChatProgressStep step) => switch (step) {
    StepSending() => 'sending',
    StepThinking() => 'thinking',
    StepNote() => 'note',
    StepTool(:final callId) => 'tool:$callId',
    StepWriting() => 'writing',
    StepStopped() => 'stopped',
  };
}
