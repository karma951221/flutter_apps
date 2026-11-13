import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/chat/tool/tool_summary.dart';

part 'chat_progress.freezed.dart';

/// 진행 줄 단계 하나. 문구는 화면이 l10n 으로 만든다.
@freezed
sealed class ChatProgressStep with _$ChatProgressStep {
  const ChatProgressStep._();

  const factory ChatProgressStep.sending() = StepSending;
  const factory ChatProgressStep.thinking() = StepThinking;

  /// 모델의 진행 노트. toString 에 글 없음.
  const factory ChatProgressStep.note(String text) = StepNote;
  const factory ChatProgressStep.tool({
    required String callId,
    required ChatToolKind kind,
    ToolInputSummary? input,
    ToolSummary? result,
  }) = StepTool;
  const factory ChatProgressStep.writing() = StepWriting;
  const factory ChatProgressStep.stopped() = StepStopped;

  /// 노트는 글 길이만. 도구 입력은 [ToolInputSummary.toString] 이라 검색어가 없다.
  @override
  String toString() => switch (this) {
    StepSending() => 'StepSending()',
    StepThinking() => 'StepThinking()',
    StepNote(:final text) => 'StepNote(${text.length} chars)',
    StepTool(:final callId, :final kind, :final input, :final result) =>
      'StepTool(callId: $callId, kind: $kind, input: $input, result: $result)',
    StepWriting() => 'StepWriting()',
    StepStopped() => 'StepStopped()',
  };
}

/// 답 말풍선 하나의 진행. 저장하지 않는다(Q4).
@freezed
class ChatProgress with _$ChatProgress {
  /// 시간 순. 펼친 타임라인이 그대로 쓴다.
  @override
  final List<ChatProgressStep> steps;

  @override
  final DateTime startedAt;

  /// 1초마다 cubit 이 올림, 끝나면 고정.
  @override
  final int elapsedSeconds;

  @override
  final bool running;

  const ChatProgress({
    required this.startedAt,
    this.steps = const [],
    this.elapsedSeconds = 0,
    this.running = true,
  });

  /// 끝난 뒤 접힌 요약을 남기는 최소 초(Q2).
  static const summaryMinSeconds = 3;

  /// 진행 중 경과 초를 보이기 시작하는 초(빠른 답에서 숫자가 깜빡이지 않게).
  static const elapsedVisibleFrom = 3;

  /// 지금 단계.
  ChatProgressStep? get current => steps.lastOrNull;

  /// 기록 도구 호출 수(서로 다른 callId). 웹 검색은 기록을 찾아본 것이 아니라 세지 않는다.
  int get toolCalls => {
    for (final step in steps)
      if (step is StepTool && step.kind != ChatToolKind.webSearch) step.callId,
  }.length;

  /// [■ 멈춤]으로 끊겼다.
  bool get stopped => steps.lastOrNull is StepStopped;

  /// 끝난 뒤 접힌 요약을 남길까 — 3초 이상이거나 멈췄으면(Q2).
  bool get keepSummary => stopped || elapsedSeconds >= summaryMinSeconds;
}
