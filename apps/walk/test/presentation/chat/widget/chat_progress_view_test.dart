import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/presentation/chat/cubit/chat_progress.dart';
import 'package:walk/presentation/chat/widget/chat_progress_view.dart';

void main() {
  final start = DateTime(2026, 11, 1);

  Widget app(ChatProgress progress, {bool reduceMotion = false}) => MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: Scaffold(body: ChatProgressView(progress: progress)),
  );

  ChatProgress running(List<ChatProgressStep> steps, {int seconds = 0}) =>
      ChatProgress(startedAt: start, steps: steps, elapsedSeconds: seconds);

  const searching = ChatProgressStep.tool(
    callId: 'a',
    kind: ChatToolKind.searchDiary,
    result: ToolSummary(kind: ChatToolKind.searchDiary, count: 5),
  );

  testWidgets('진행 중이면 지금 단계 문구와 스피너', (tester) async {
    await tester.pumpWidget(
      app(
        running(const [
          ChatProgressStep.sending(),
          ChatProgressStep.thinking(),
        ]),
      ),
    );

    expect(find.text('생각하는 중'), findsOneWidget);
    expect(find.text('보내는 중'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('경과 초는 3초부터 보인다', (tester) async {
    await tester.pumpWidget(
      app(running(const [ChatProgressStep.thinking()], seconds: 2)),
    );
    expect(find.textContaining('2초'), findsNothing);

    await tester.pumpWidget(
      app(running(const [ChatProgressStep.thinking()], seconds: 3)),
    );
    expect(find.textContaining('3초'), findsOneWidget);
  });

  testWidgets('끝나면 접힌 요약, 누르면 단계 목록이 펼쳐지고 다시 누르면 접힌다', (tester) async {
    await tester.pumpWidget(
      app(
        ChatProgress(
          startedAt: start,
          steps: const [
            ChatProgressStep.note('기록을 볼게요'),
            searching,
            ChatProgressStep.writing(),
          ],
          elapsedSeconds: 9,
          running: false,
        ),
      ),
    );

    expect(find.textContaining('기록 1번 찾아봄 · 9초'), findsOneWidget);
    expect(find.textContaining('▸'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('답 쓰기'), findsNothing);

    await tester.tap(find.textContaining('기록 1번 찾아봄'));
    await tester.pumpAndSettle();
    expect(find.textContaining('▾'), findsOneWidget);
    expect(find.text('· 기록을 볼게요'), findsOneWidget);
    expect(find.text('· 일기 찾는 중 — 일기 5개 찾음'), findsOneWidget);
    expect(find.text('· 답 쓰기'), findsOneWidget);

    await tester.tap(find.textContaining('기록 1번 찾아봄'));
    await tester.pumpAndSettle();
    expect(find.textContaining('▸'), findsOneWidget);
    expect(find.text('· 답 쓰기'), findsNothing);
  });

  testWidgets("멈춤이면 정지 아이콘과 '멈춤'", (tester) async {
    await tester.pumpWidget(
      app(
        ChatProgress(
          startedAt: start,
          steps: const [searching, ChatProgressStep.stopped()],
          elapsedSeconds: 4,
          running: false,
        ),
      ),
    );

    expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
    expect(find.textContaining('멈춤 · 기록 1번 찾아봄 · 4초'), findsOneWidget);

    await tester.tap(find.textContaining('멈춤 ·'));
    await tester.pumpAndSettle();
    expect(find.text('· 멈춤'), findsOneWidget);
  });

  testWidgets('줄이기 모드면 스피너가 없고 AnimatedSwitcher · AnimatedSize duration 이 0', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(running(const [ChatProgressStep.thinking()]), reduceMotion: true),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    for (final switcher in tester.widgetList<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    )) {
      expect(switcher.duration, Duration.zero);
    }
    for (final size in tester.widgetList<AnimatedSize>(
      find.byType(AnimatedSize),
    )) {
      expect(size.duration, Duration.zero);
    }
    expect(find.byType(AnimatedSwitcher), findsWidgets);
    expect(find.byType(AnimatedSize), findsWidgets);
  });

  testWidgets('단계 문구는 liveRegion, 경과 초는 시맨틱에 없다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      app(running(const [ChatProgressStep.thinking()], seconds: 5)),
    );

    expect(
      tester.getSemantics(find.byKey(ChatProgressView.liveRegionKey)),
      matchesSemantics(isLiveRegion: true, label: '생각하는 중'),
    );
    expect(find.bySemanticsLabel(RegExp('5초')), findsNothing);
    handle.dispose();
  });

  SemanticsNode live(WidgetTester tester) =>
      tester.getSemantics(find.byKey(ChatProgressView.liveRegionKey));

  testWidgets('자라는 노트는 제자리에서 바뀌고 페이드하지 않는다', (tester) async {
    await tester.pumpWidget(app(running(const [ChatProgressStep.note('지')])));
    await tester.pump(AppMotion.short);
    await tester.pumpWidget(
      app(running(const [ChatProgressStep.note('지난주 기록을')])),
    );

    final texts = find.descendant(
      of: find.byType(AnimatedSwitcher),
      matching: find.byType(Text),
    );
    expect(texts, findsOneWidget);
    expect(find.text('지난주 기록을'), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue); // 스피너만 돈다
    final fades = tester.widgetList<FadeTransition>(
      find.descendant(
        of: find.byType(AnimatedSwitcher),
        matching: find.byType(FadeTransition),
      ),
    );
    for (final fade in fades) {
      expect(fade.opacity.value, 1);
    }
  });

  testWidgets('노트는 자라도 이어져도 라벨이 생각하는 중, 도구로 바뀌면 바뀐다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(running(const [ChatProgressStep.note('지')])));
    expect(live(tester).label, '생각하는 중');

    await tester.pumpWidget(
      app(running(const [ChatProgressStep.note('지난주 기록을 볼게요')])),
    );
    await tester.pumpWidget(
      app(
        running(const [
          ChatProgressStep.note('지난주 기록을 볼게요'),
          ChatProgressStep.note('둘'),
        ]),
      ),
    );
    await tester.pump(AppMotion.short);
    expect(live(tester).label, '생각하는 중');
    expect(find.text('둘'), findsOneWidget);

    await tester.pumpWidget(
      app(
        running(const [
          ChatProgressStep.note('둘'),
          ChatProgressStep.tool(callId: 'a', kind: ChatToolKind.viewPhotos),
        ]),
      ),
    );
    await tester.pump(AppMotion.short);
    expect(live(tester).label, '사진 보는 중');

    // 같은 도구 호출에 결과가 붙어도 라벨은 그대로, 다음 단위(답 쓰는 중)에서 바뀐다.
    await tester.pumpWidget(
      app(
        running(const [
          ChatProgressStep.tool(
            callId: 'a',
            kind: ChatToolKind.viewPhotos,
            result: ToolSummary(kind: ChatToolKind.viewPhotos, count: 2),
          ),
        ]),
      ),
    );
    await tester.pump(AppMotion.short);
    expect(find.text('사진 2장'), findsOneWidget);
    expect(live(tester).label, '사진 보는 중');

    await tester.pumpWidget(app(running(const [ChatProgressStep.writing()])));
    await tester.pump(AppMotion.short);
    expect(live(tester).label, '답 쓰는 중');
    handle.dispose();
  });

  testWidgets('색은 onSurfaceVariant', (tester) async {
    await tester.pumpWidget(
      app(running(const [ChatProgressStep.thinking()], seconds: 4)),
    );

    final context = tester.element(find.byType(ChatProgressView));
    final theme = Theme.of(context);
    final text = tester.widget<Text>(find.text('생각하는 중'));
    final style = DefaultTextStyle.of(
      tester.element(find.text('생각하는 중')),
    ).style.merge(text.style);
    expect(style.color, theme.colorScheme.onSurfaceVariant);
    expect(style.fontSize, theme.textTheme.bodySmall?.fontSize);
  });
}
