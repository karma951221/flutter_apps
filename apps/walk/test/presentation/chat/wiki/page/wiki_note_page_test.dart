import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/chat/wiki/open_wiki.dart';
import 'package:walk/presentation/chat/wiki/page/wiki_note_edit_page.dart';
import 'package:walk/presentation/chat/wiki/page/wiki_note_page.dart';
import 'package:walk/presentation/chat/wiki/page/wiki_page.dart';

import '../../../../support/fake_wiki_repository.dart';
import '../wiki_harness.dart';

void main() {
  late WikiHarness h;

  setUp(() => h = WikiHarness());
  tearDown(() => h.tearDown());

  final sleep = wikiNote(
    5,
    title: '수면 패턴',
    summary: '평일 7시 전후 기상',
    body: '[[3]] 출근 알람으로 깬다.',
  ).copyWith(sourceConversationId: 'c1');
  final alarm = wikiNote(3, title: '출근 알람', body: '관련: [[5]]');

  final noteMenu = find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.more_vert),
  );

  testWidgets('요약 · 본문 칩 · 역링크가 보인다', (tester) async {
    await h.setUp(notes: [sleep, alarm]);
    await h.pump(tester, (context) => openWikiNote(context, 5));

    expect(find.widgetWithText(AppBar, '수면 패턴'), findsOneWidget);
    expect(find.text('평일 7시 전후 기상'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '출근 알람'), findsOneWidget);
    expect(find.text('이 메모를 가리키는 메모'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('wiki-backlink-3')),
        matching: find.text('출근 알람'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('메모 칩을 누르면 그 메모 화면', (tester) async {
    await h.setUp(notes: [sleep, alarm]);
    await h.pump(tester, (context) => openWikiNote(context, 5));

    await tester.tap(find.widgetWithText(ActionChip, '출근 알람'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, '출근 알람'), findsOneWidget);
    expect(find.byType(WikiNotePage), findsOneWidget);
  });

  testWidgets('삭제는 확인 뒤에만, 확인하면 닫힌다', (tester) async {
    await h.setUp(notes: [sleep, alarm]);
    await h.pump(tester, (context) => openWikiNote(context, 5));

    await tester.tap(noteMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('이 메모를 지울까요?'), findsOneWidget);
    expect(find.text("다른 메모의 링크는 '지워진 메모'로 남아요."), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, '취소'));
    await tester.pumpAndSettle();
    expect(h.wiki.deleted, isEmpty);
    expect(find.byType(WikiNotePage), findsOneWidget);

    await tester.tap(noteMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(AppButton, '삭제'),
      ),
    );
    await tester.pumpAndSettle();

    expect(h.wiki.deleted, [5]);
    expect(find.byType(WikiNotePage), findsNothing);
    expect(find.text('home'), findsOneWidget);
    expect(h.results, [null]);
  });

  testWidgets('삭제가 실패하면 스낵바, 화면은 그대로', (tester) async {
    await h.setUp(notes: [sleep]);
    h.wiki.failWrites = true;
    await h.pump(tester, (context) => openWikiNote(context, 5));

    await tester.tap(noteMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(AppButton, '삭제'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('메모를 지우지 못했어요'), findsOneWidget);
    expect(find.byType(WikiNotePage), findsOneWidget);
  });

  testWidgets('출처 대화가 있으면 [대화 보기] → 그 id 로 끝나 위키 화면까지 넘어간다', (tester) async {
    await h.setUp(notes: [sleep, alarm], conversations: {'c1'});
    await h.pump(tester, openWikiPage);

    await tester.tap(find.byKey(const Key('wiki-note-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, '대화 보기'));
    await tester.pumpAndSettle();

    expect(find.byType(WikiNotePage), findsNothing);
    expect(find.byType(WikiPage), findsNothing);
    expect(h.results, ['c1']);
  });

  testWidgets('링크로 연 메모에서 [대화 보기]도 끝까지 넘어간다', (tester) async {
    final linked = alarm.copyWith(sourceConversationId: 'c3');
    await h.setUp(notes: [sleep, linked], conversations: {'c3'});
    await h.pump(tester, openWikiPage);

    await tester.tap(find.byKey(const Key('wiki-note-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, '출근 알람'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, '대화 보기'));
    await tester.pumpAndSettle();

    expect(find.byType(WikiPage), findsNothing);
    expect(h.results, ['c3']);
  });

  testWidgets('출처가 지워졌으면 [대화 보기] 없음', (tester) async {
    await h.setUp(notes: [sleep, alarm]);
    await h.pump(tester, (context) => openWikiNote(context, 5));

    expect(find.text('대화 보기'), findsNothing);
  });

  testWidgets('[편집] → 메모 값이 채워진 편집, 저장하면 메모 화면이 바뀐다', (tester) async {
    await h.setUp(notes: [sleep, alarm]);
    await h.pump(tester, (context) => openWikiNote(context, 5));

    await tester.tap(find.byKey(const Key('wiki-note-edit')));
    await tester.pumpAndSettle();
    expect(find.byType(WikiNoteEditPage), findsOneWidget);
    expect(find.text('메모 편집'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('wiki-edit-summary')),
      '주말엔 9시',
    );
    await tester.tap(find.byKey(const Key('wiki-edit-save')));
    await tester.pumpAndSettle();

    expect(find.byType(WikiNoteEditPage), findsNothing);
    expect(find.text('주말엔 9시'), findsOneWidget);
    expect(h.wiki.updated.single.$1, 5);
  });
}
