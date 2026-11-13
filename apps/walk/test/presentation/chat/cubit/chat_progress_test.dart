import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/presentation/chat/cubit/chat_progress.dart';

void main() {
  final t0 = DateTime(2026, 11, 1, 9);

  test('toolCalls 는 서로 다른 callId 수', () {
    final progress = ChatProgress(
      startedAt: t0,
      steps: const [
        ChatProgressStep.sending(),
        ChatProgressStep.tool(callId: 'a', kind: ChatToolKind.searchDiary),
        ChatProgressStep.thinking(),
        ChatProgressStep.tool(callId: 'b', kind: ChatToolKind.dailySteps),
        ChatProgressStep.tool(callId: 'a', kind: ChatToolKind.searchDiary),
      ],
    );

    expect(progress.toolCalls, 2);
    expect(progress.current, isA<StepTool>());
  });

  test('toolCalls 는 웹 검색을 세지 않는다(기록을 찾아본 수)', () {
    final progress = ChatProgress(
      startedAt: t0,
      steps: const [
        ChatProgressStep.tool(callId: 'a', kind: ChatToolKind.searchDiary),
        ChatProgressStep.tool(callId: 'w', kind: ChatToolKind.webSearch),
      ],
    );

    expect(progress.toolCalls, 1);
  });

  test('keepSummary — 2초 끝남 false · 3초 true · 1초 멈춤 true', () {
    ChatProgress done(int seconds, {bool stopped = false}) => ChatProgress(
      startedAt: t0,
      elapsedSeconds: seconds,
      running: false,
      steps: [
        const ChatProgressStep.sending(),
        if (stopped) const ChatProgressStep.stopped(),
      ],
    );

    expect(done(2).keepSummary, isFalse);
    expect(done(3).keepSummary, isTrue);
    expect(done(1, stopped: true).keepSummary, isTrue);
    expect(done(1, stopped: true).stopped, isTrue);
    expect(ChatProgress(startedAt: t0).current, isNull);
  });

  test('StepNote.toString 에 글이 없다', () {
    const note = ChatProgressStep.note('비밀 노트');
    expect(note.toString(), isNot(contains('비밀')));
    final progress = ChatProgress(startedAt: t0, steps: const [note]);
    expect(progress.toString(), isNot(contains('비밀')));
  });
}
