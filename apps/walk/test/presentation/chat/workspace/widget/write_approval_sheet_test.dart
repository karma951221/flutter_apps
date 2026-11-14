import 'dart:convert';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/tool/write_plan.dart';
import 'package:walk/presentation/chat/workspace/widget/write_approval_sheet.dart';

const _create = WritePlan.create(
  path: 'out/영수증-정리.csv',
  name: '영수증-정리.csv',
  content: '날짜,가게,금액\n2026-11-02,편의점,4500',
);

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// [showWriteApprovalSheet] 로 시트를 연다. 결과는 [log] 에 'approve' · 'decline' 으로 쌓인다.
Future<List<String>> _open(
  WidgetTester tester,
  WritePlan plan, {
  ValueNotifier<bool>? dismiss,
}) async {
  final log = <String>[];
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showWriteApprovalSheet(
              context,
              plan: plan,
              assistant: 'Claude',
              onApprove: () => log.add('approve'),
              onDecline: () => log.add('decline'),
              dismiss: dismiss,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return log;
}

/// 시트 본문(고정폭 상자)들의 글.
List<String> _boxes(WidgetTester tester) => tester
    .widgetList<SelectableText>(find.byType(SelectableText))
    .map((t) => t.data ?? t.textSpan!.toPlainText())
    .toList();

void main() {
  testWidgets('만들기: 제목 · 경로 그대로 · 크기 · 한 줄 · 내용이 보인다', (tester) async {
    await _open(tester, _create);

    expect(find.text('파일 만들기'), findsOneWidget);
    // 크기는 새 내용 UTF-8 바이트: 한글 9자 × 3 + ASCII 19 = 46.
    expect(utf8.encode((_create as WriteCreate).content).length, 46);
    expect(find.text('out/영수증-정리.csv · 46B'), findsOneWidget);
    expect(find.text('Claude 가 이 파일을 만들려고 해요'), findsOneWidget);
    expect(_boxes(tester), contains('날짜,가게,금액\n2026-11-02,편의점,4500'));
    expect(find.text('거절'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
  });

  testWidgets('[저장]을 두 번 눌러도 onApprove 는 한 번', (tester) async {
    final log = await _open(tester, _create);

    await tester.tap(find.text('저장'));
    await tester.tap(find.text('저장'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(log, ['approve']);
    expect(find.text('파일 만들기'), findsNothing);
    // 아래 화면은 그대로다(두 번 닫지 않았다).
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('위젯만: [저장] 연타 → onApprove 한 번, 버튼이 꺼진다', (tester) async {
    var approved = 0;
    var declined = 0;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: WriteApprovalSheet(
            plan: _create,
            assistant: 'Claude',
            onApprove: () => approved++,
            onDecline: () => declined++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('저장'));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.tap(find.text('거절'));
    await tester.pump();

    expect(approved, 1);
    expect(declined, 0);
  });

  testWidgets('[거절] → onDecline', (tester) async {
    final log = await _open(tester, _create);

    await tester.tap(find.text('거절'));
    await tester.pumpAndSettle();

    expect(log, ['decline']);
  });

  testWidgets('밖을 누르면 거절', (tester) async {
    final log = await _open(tester, _create);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(log, ['decline']);
    expect(find.text('파일 만들기'), findsNothing);
  });

  testWidgets('뒤로 가면 거절', (tester) async {
    final log = await _open(tester, _create);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(log, ['decline']);
  });

  testWidgets('dismiss 신호로 닫히면 아무것도 부르지 않는다', (tester) async {
    final dismiss = ValueNotifier(false);
    addTearDown(dismiss.dispose);
    final log = await _open(tester, _create, dismiss: dismiss);

    dismiss.value = true;
    await tester.pumpAndSettle();

    expect(find.text('파일 만들기'), findsNothing);
    expect(log, isEmpty);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('덮어쓰기: 제목과 "지금 내용 N자를 바꿔요"', (tester) async {
    await _open(
      tester,
      const WritePlan.overwrite(
        path: 'out/a.md',
        name: 'a.md',
        content: '새 내용',
        previous: '옛 내용 다섯',
      ),
    );

    expect(find.text('파일 덮어쓰기'), findsOneWidget);
    expect(find.text('지금 내용 7자를 바꿔요'), findsOneWidget);
    expect(find.text('Claude 가 이 파일을 덮어쓰려고 해요'), findsOneWidget);
    expect(_boxes(tester), contains('새 내용'));
    expect(find.text('저장'), findsOneWidget);
  });

  testWidgets('고치기: 지울 부분 · 넣을 부분 두 상자에 old/new 그대로, 위에 앞뒤 한 줄 맥락', (
    tester,
  ) async {
    const previous = '첫 줄\n둘째 줄\n셋째 바꿀 곳 끝\n넷째 줄\n다섯째 줄';
    await _open(
      tester,
      const WritePlan.edit(
        path: 'out/note.md',
        name: 'note.md',
        oldText: '바꿀 곳',
        newText: '바뀐 곳\u202E',
        previous: previous,
        content: '첫 줄\n둘째 줄\n셋째 바뀐 곳\u202E 끝\n넷째 줄\n다섯째 줄',
      ),
    );

    expect(find.text('파일 고치기'), findsOneWidget);
    expect(find.text('지울 부분'), findsOneWidget);
    expect(find.text('넣을 부분'), findsOneWidget);
    final boxes = _boxes(tester);
    expect(boxes, contains('바꿀 곳'));
    expect(boxes, contains('바뀐 곳⟨U+202E⟩'));
    // 맥락: 앞 한 줄 + 그 줄의 앞부분 · 뒷부분 + 뒤 한 줄. 첫 줄 · 다섯째 줄은 없다.
    final context = boxes.firstWhere((b) => b.contains('둘째 줄'));
    expect(context, contains('셋째 '));
    expect(context, contains(' 끝\n넷째 줄'));
    expect(context, isNot(contains('첫 줄')));
    expect(context, isNot(contains('다섯째')));
    expect(find.text('고치기'), findsOneWidget);
  });

  testWidgets('지우기: 크기는 sizeBytes, 앞 20줄, [지우기] 버튼', (tester) async {
    final previous = List.generate(30, (i) => '줄 ${i + 1}').join('\n');
    final log = await _open(
      tester,
      WritePlan.delete(
        path: 'out/old.txt',
        name: 'old.txt',
        previous: previous,
        sizeBytes: 2048,
      ),
    );

    expect(find.text('파일 지우기'), findsOneWidget);
    expect(find.text('out/old.txt · 2KB'), findsOneWidget);
    expect(find.text('Claude 가 이 파일을 지우려고 해요'), findsOneWidget);
    final preview = _boxes(tester).single;
    expect(preview, contains('줄 20'));
    expect(preview, isNot(contains('줄 21')));
    expect(find.text('지우기'), findsOneWidget);

    await tester.tap(find.text('지우기'));
    await tester.pumpAndSettle();
    expect(log, ['approve']);
  });

  group('지우기: 남은 줄 수 — 끝 줄바꿈은 줄로 세지 않는다', () {
    String lines(int n) => List.generate(n, (i) => '줄 ${i + 1}').join('\n');
    WritePlan plan(String previous) => WritePlan.delete(
      path: 'out/old.txt',
      name: 'old.txt',
      previous: previous,
      sizeBytes: 10,
    );

    testWidgets('30줄은 10줄 더', (tester) async {
      await _open(tester, plan(lines(30)));
      expect(find.text('… 10줄 더'), findsOneWidget);
    });

    testWidgets('20줄 + 끝 줄바꿈은 더 없음', (tester) async {
      await _open(tester, plan('${lines(20)}\n'));
      expect(find.textContaining('줄 더'), findsNothing);
    });

    testWidgets('21줄 + 끝 줄바꿈은 1줄 더', (tester) async {
      await _open(tester, plan('${lines(21)}\n'));
      expect(find.text('… 1줄 더'), findsOneWidget);
    });
  });

  testWidgets('마크다운 · 링크는 글자 그대로(링크 위젯 없음)', (tester) async {
    const content = '# 제목\n[a](http://x)';
    await _open(
      tester,
      const WritePlan.create(path: 'out/m.md', name: 'm.md', content: content),
    );

    expect(_boxes(tester), contains(content));
    expect(find.text('제목'), findsNothing);
  });

  testWidgets('보이지 않는 글자는 시트에서 드러난다', (tester) async {
    await _open(
      tester,
      const WritePlan.create(
        path: 'out/x.txt',
        name: 'x.txt',
        content: 'a\u202Eb\u200Bc',
      ),
    );

    expect(_boxes(tester), contains('a⟨U+202E⟩b⟨U+200B⟩c'));
  });

  testWidgets('경로의 방향 바꾸는 글자도 머리에서 드러난다', (tester) async {
    await _open(
      tester,
      const WritePlan.create(
        path: 'out/a\u202Edm.txt',
        name: 'a\u202Edm.txt',
        content: 'x',
      ),
    );

    expect(find.text('out/a⟨U+202E⟩dm.txt · 1B'), findsOneWidget);
  });

  testWidgets('5,000줄 · 아주 긴 줄 → 넘치지 않고 시트 안에서 스크롤된다', (tester) async {
    final long = 'x' * 3000;
    final content = [long, ...List.generate(5000, (i) => '줄 $i')].join('\n');
    await _open(
      tester,
      WritePlan.create(path: 'out/big.txt', name: 'big.txt', content: content),
    );

    expect(tester.takeException(), isNull);
    // 버튼은 화면 안에 있다.
    final screen = tester.getRect(find.byType(Scaffold).first);
    expect(screen.contains(tester.getCenter(find.text('저장'))), isTrue);
    // 시트 본문 스크롤(안쪽 SelectableText 의 스크롤은 넘침 없이 다 그려진다).
    final scrollable = find
        .descendant(
          of: find.byType(WriteApprovalSheet),
          matching: find.byType(Scrollable),
        )
        .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));

    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
