import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';
import 'package:walk/presentation/chat/wiki/cubit/wiki_edit_state.dart';
import 'package:walk/presentation/chat/wiki/open_wiki.dart';
import 'package:walk/presentation/chat/wiki/page/wiki_note_edit_page.dart';

import '../../../../support/fake_wiki_repository.dart';
import '../wiki_fakes.dart';
import '../wiki_harness.dart';

void main() {
  late WikiHarness h;

  setUp(() => h = WikiHarness());
  tearDown(() => h.tearDown());

  const seed = WikiEditSeed(
    title: '수면 패턴',
    summary: '평일 7시 기상',
    body: '앞뒤',
    sourceConversationId: 'c1',
    suggestedEntryIds: ['e1'],
  );

  TextField field(WidgetTester tester, String key) =>
      tester.widget<TextField>(find.byKey(Key(key)));

  String text(WidgetTester tester, String key) =>
      field(tester, key).controller!.text;

  /// 본문 칸의 커서를 [offset] 에 둔다.
  Future<void> putCursor(WidgetTester tester, int offset) async {
    field(tester, 'wiki-edit-body').controller!.selection =
        TextSelection.collapsed(offset: offset);
    await tester.pump();
  }

  ChatTurnRecord turn(String conversationId, List<String> cited) =>
      ChatTurnRecord(
        conversationId: conversationId,
        seq: 1,
        question: '질문',
        answer: '답',
        citedEntryIds: cited,
        stopped: false,
        vendor: ChatVendor.anthropic,
        model: 'claude-x',
        askedAt: DateTime(2026, 10, 3),
      );

  testWidgets('seed 값이 칸에 채워진다', (tester) async {
    await h.setUp();
    await h.pump(tester, (context) => openWikiEditor(context, seed));

    expect(find.byType(WikiNoteEditPage), findsOneWidget);
    expect(find.text('새 메모'), findsOneWidget);
    expect(text(tester, 'wiki-edit-title'), '수면 패턴');
    expect(text(tester, 'wiki-edit-summary'), '평일 7시 기상');
    expect(text(tester, 'wiki-edit-body'), '앞뒤');
    expect(find.text('질문할 때마다 모델에게 보여요'), findsOneWidget);
  });

  testWidgets('기존 메모면 앱바가 메모 편집', (tester) async {
    await h.setUp(notes: [wikiNote(3)]);
    await h.pump(
      tester,
      (context) => openWikiEditor(context, WikiEditSeed.fromNote(wikiNote(3))),
    );
    expect(find.text('메모 편집'), findsOneWidget);
    expect(text(tester, 'wiki-edit-title'), '메모3');
  });

  testWidgets('빈 제목으로 저장하면 오류 문구', (tester) async {
    await h.setUp();
    await h.pump(tester, (context) => openWikiEditor(context, seed));

    await tester.enterText(find.byKey(const Key('wiki-edit-title')), ' ');
    await tester.tap(find.byKey(const Key('wiki-edit-save')));
    await tester.pumpAndSettle();

    expect(find.text('제목을 적어 주세요'), findsOneWidget);
    expect(find.byType(WikiNoteEditPage), findsOneWidget);
    expect(h.wiki.created, isEmpty);
  });

  testWidgets('[메모 링크] → 고르면 커서 자리에 [[id]]', (tester) async {
    await h.setUp(notes: [wikiNote(3, title: '출근 알람')]);
    await h.pump(tester, (context) => openWikiEditor(context, seed));
    await putCursor(tester, 1);

    await tester.tap(find.byKey(const Key('wiki-edit-link-note')));
    await tester.pumpAndSettle();
    expect(find.text('메모 고르기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wiki-pick-note-3')));
    await tester.pumpAndSettle();

    expect(text(tester, 'wiki-edit-body'), '앞[[3]]뒤');
  });

  testWidgets('선택 영역이 있으면 링크로 바꿔 넣는다', (tester) async {
    await h.setUp(notes: [wikiNote(3)]);
    await h.pump(tester, (context) => openWikiEditor(context, seed));
    field(tester, 'wiki-edit-body').controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 1,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('wiki-edit-link-note')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wiki-pick-note-3')));
    await tester.pumpAndSettle();

    expect(text(tester, 'wiki-edit-body'), '[[3]]뒤');
  });

  testWidgets('링크를 넣으면 본문 상한을 넘을 때는 넣지 않고 스낵바', (tester) async {
    await h.setUp(notes: [wikiNote(3)]);
    final full = '가' * (wikiBodyMax - 2);
    await h.pump(
      tester,
      (context) => openWikiEditor(context, seed.copyWith(body: full)),
    );

    final link = find.byKey(const Key('wiki-edit-link-note'));
    await tester.scrollUntilVisible(
      link,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(link);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wiki-pick-note-3')));
    await tester.pumpAndSettle();

    expect(text(tester, 'wiki-edit-body'), full);
    expect(find.text('본문이 길어 링크를 넣지 못했어요'), findsOneWidget);
  });

  testWidgets('[일기 링크] → 근거 일기를 고르면 [[일기:id]]', (tester) async {
    await h.setUp(
      entries: [
        wikiEntry('e1', body: '첫 기록'),
        wikiEntry('e2', body: '둘째 기록'),
      ],
      turns: {
        'c1': [
          turn('c1', ['e2', 'e1']),
        ],
      },
    );
    await h.pump(tester, (context) => openWikiEditor(context, seed));
    await putCursor(tester, 2);

    await tester.tap(find.byKey(const Key('wiki-edit-link-entry')));
    await tester.pumpAndSettle();
    expect(find.text('이 대화의 근거 일기'), findsOneWidget);
    // seed 의 근거 + 출처 대화의 인용, 중복 없이.
    expect(find.byKey(const Key('wiki-pick-entry-e1')), findsOneWidget);
    expect(find.byKey(const Key('wiki-pick-entry-e2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('wiki-pick-entry-e2')));
    await tester.pumpAndSettle();

    expect(text(tester, 'wiki-edit-body'), '앞뒤[[일기:e2]]');
  });

  testWidgets('저장하면 pop(id)', (tester) async {
    await h.setUp(notes: [wikiNote(3)]);
    await h.pump(tester, (context) => openWikiEditor(context, seed));

    await tester.tap(find.byKey(const Key('wiki-edit-save')));
    await tester.pumpAndSettle();

    expect(find.byType(WikiNoteEditPage), findsNothing);
    expect(h.results, [4]);
    expect(h.wiki.created.single.title, '수면 패턴');
    expect(h.wiki.created.single.sourceConversationId, 'c1');
    expect(find.text('위키에 저장했어요'), findsOneWidget);
  });

  testWidgets('저장하지 못하면 화면에 남고 스낵바', (tester) async {
    await h.setUp();
    h.wiki.failWrites = true;
    await h.pump(tester, (context) => openWikiEditor(context, seed));

    await tester.tap(find.byKey(const Key('wiki-edit-save')));
    await tester.pumpAndSettle();

    expect(find.byType(WikiNoteEditPage), findsOneWidget);
    expect(find.text('저장하지 못했어요'), findsOneWidget);
    expect(h.results, isEmpty);
  });

  testWidgets('뒤로 가면 null', (tester) async {
    await h.setUp();
    await h.pump(tester, (context) => openWikiEditor(context, seed));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(h.results, [null]);
    expect(h.wiki.created, isEmpty);
  });

  testWidgets('잠겼다 풀려도 쓰던 글이 남는다', (tester) async {
    await h.setUp();
    await h.pump(tester, (context) => openWikiEditor(context, seed));
    await tester.enterText(find.byKey(const Key('wiki-edit-title')), '고친 제목');
    await tester.enterText(find.byKey(const Key('wiki-edit-body')), '고친 본문');

    await h.relock(tester);
    expect(find.byType(WikiNoteEditPage), findsNothing);
    await h.unlock(tester);

    expect(text(tester, 'wiki-edit-title'), '고친 제목');
    expect(text(tester, 'wiki-edit-summary'), '평일 7시 기상');
    expect(text(tester, 'wiki-edit-body'), '고친 본문');
  });
}
