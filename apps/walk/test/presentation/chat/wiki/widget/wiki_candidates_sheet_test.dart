import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/usecase/wiki_distiller.dart';
import 'package:walk/presentation/chat/wiki/page/wiki_note_edit_page.dart';
import 'package:walk/presentation/chat/wiki/widget/wiki_candidates_sheet.dart';

import '../../../../support/fake_wiki_repository.dart';
import '../wiki_fakes.dart';
import '../wiki_harness.dart';

class _MockDistiller extends Mock implements WikiDistiller {}

void main() {
  final h = WikiHarness();
  late _MockDistiller distiller;

  const created = WikiCandidate.create(
    title: '기상 시간',
    summary: '평일 7시',
    body: '평일엔 7시에 일어난다 [[일기:e1]]',
  );
  const updated = WikiCandidate.update(
    id: 3,
    title: '수면',
    summary: '늦게 잔다',
    body: '자정 넘어 잔다',
  );

  final turns = {
    'c1': [
      ChatTurnRecord(
        conversationId: 'c1',
        seq: 1,
        question: '요즘 몇 시에 일어나?',
        answer: '7시',
        citedEntryIds: const ['e1'],
        stopped: false,
        vendor: ChatVendor.anthropic,
        model: 'claude-x',
        askedAt: DateTime(2026, 11, 1),
      ),
    ],
  };

  Future<void> setUp({required WikiDistillResult result}) async {
    await h.setUp(
      notes: [wikiNote(3, title: '수면', body: '11시에 잔다')],
      entries: [wikiEntry('e1')],
      conversations: {'c1'},
      turns: turns,
    );
    distiller = _MockDistiller();
    when(
      () => distiller.distill(
        conversationId: any(named: 'conversationId'),
        target: any(named: 'target'),
      ),
    ).thenAnswer((_) async => result);
    getIt.registerSingleton<WikiDistiller>(distiller);
  }

  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester) => h.pump(
    tester,
    (context) => showWikiCandidatesSheet(
      context,
      conversationId: 'c1',
      target: claudeTarget,
    ),
  );

  Finder inCard(int i, Finder f) =>
      find.descendant(of: find.byKey(Key('wiki-candidate-$i')), matching: f);

  Future<void> tapIn(WidgetTester tester, int i, String text) async {
    final target = inCard(i, find.text(text));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  final sheet = find.byType(BottomSheet);

  testWidgets('카드마다 저장 · 고쳐서 저장 · 버림', (tester) async {
    await setUp(result: const WikiDistillResult.candidates([created, updated]));
    await open(tester);

    for (final i in [0, 1]) {
      expect(inCard(i, find.text('저장')), findsOneWidget);
      expect(inCard(i, find.text('고쳐서 저장')), findsOneWidget);
      expect(inCard(i, find.text('버림')), findsOneWidget);
    }
    expect(inCard(0, find.text('새 메모')), findsOneWidget);
    expect(inCard(0, find.text('기상 시간')), findsOneWidget);
    expect(inCard(0, find.text('평일 7시')), findsOneWidget);
    expect(inCard(1, find.text('[[3]] 고치기')), findsOneWidget);
    // 링크 칩은 있지만 누를 수 없다.
    final chip = tester.widget<ActionChip>(
      find.descendant(
        of: inCard(0, find.byKey(const Key('wiki-link-entry-e1'))),
        matching: find.byType(ActionChip),
      ),
    );
    expect(chip.onPressed, isNull);
  });

  testWidgets('[저장]한 것만 저장소에 남고 [버림]은 아무것도 안 쓴다', (tester) async {
    await setUp(result: const WikiDistillResult.candidates([created, updated]));
    await open(tester);

    await tapIn(tester, 0, '저장');
    expect(inCard(0, find.text('저장함')), findsOneWidget);
    expect(sheet, findsOneWidget);
    await tapIn(tester, 1, '버림');

    expect(h.wiki.created, [
      const WikiNoteDraft(
        title: '기상 시간',
        summary: '평일 7시',
        body: '평일엔 7시에 일어난다 [[일기:e1]]',
        sourceConversationId: 'c1',
      ),
    ]);
    expect(h.wiki.updated, isEmpty);
    // 모두 처리하면 알리고 닫힌다.
    expect(find.text('메모 1개를 저장했어요'), findsOneWidget);
    expect(sheet, findsNothing);
  });

  testWidgets('닫으면 남은 후보는 저장되지 않는다', (tester) async {
    await setUp(result: const WikiDistillResult.candidates([created, updated]));
    await open(tester);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(sheet, findsNothing);
    expect(h.wiki.created, isEmpty);
    expect(h.wiki.updated, isEmpty);
  });

  testWidgets('update 카드에 지금 · 바뀔 내용이 둘 다', (tester) async {
    await setUp(result: const WikiDistillResult.candidates([updated]));
    await open(tester);

    expect(inCard(0, find.text('지금')), findsOneWidget);
    expect(inCard(0, find.text('바뀔 내용')), findsOneWidget);
    expect(inCard(0, find.text('11시에 잔다', findRichText: true)), findsOneWidget);
    expect(
      inCard(0, find.text('자정 넘어 잔다', findRichText: true)),
      findsOneWidget,
    );
    final current = tester.getTopLeft(
      inCard(0, find.text('11시에 잔다', findRichText: true)),
    );
    final proposed = tester.getTopLeft(
      inCard(0, find.text('자정 넘어 잔다', findRichText: true)),
    );
    expect(current.dy, lessThan(proposed.dy));

    await tapIn(tester, 0, '저장');
    expect(h.wiki.updated.single.$1, 3);
    expect(h.wiki.updated.single.$2.sourceConversationId, isNull);
  });

  testWidgets('빈 후보면 안내', (tester) async {
    await setUp(result: const WikiDistillResult.candidates([]));
    await open(tester);

    expect(find.text('남길 만한 내용을 찾지 못했어요'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
  });

  testWidgets("unparsable 이면 '정리하지 못했어요'", (tester) async {
    await setUp(result: const WikiDistillResult.unparsable());
    await open(tester);

    expect(find.text('정리하지 못했어요. 다시 해 보세요'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
  });

  testWidgets('failed 면 물어보기와 같은 실패 문구', (tester) async {
    await setUp(result: const WikiDistillResult.failed(ChatFailure.invalidKey));
    await open(tester);

    expect(find.text('키를 확인해 주세요'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
  });

  testWidgets('정리하는 동안 진행 표시, [취소]면 요청을 끊고 닫힌다', (tester) async {
    await setUp(result: const WikiDistillResult.cancelled());
    final pending = Completer<WikiDistillResult>();
    when(
      () => distiller.distill(
        conversationId: any(named: 'conversationId'),
        target: any(named: 'target'),
      ),
    ).thenAnswer((_) => pending.future);
    late BuildContext home;
    await h.pump(tester, (context) async => home = context);
    unawaited(
      showWikiCandidatesSheet(home, conversationId: 'c1', target: claudeTarget),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('이 대화에서 남길 내용을 고르는 중…'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    verify(() => distiller.cancel()).called(1);
    expect(sheet, findsNothing);
    pending.complete(const WikiDistillResult.cancelled());
  });

  testWidgets("[고쳐서 저장] → 편집 화면이 후보 값으로 열리고 저장하면 카드가 '저장함'", (tester) async {
    await setUp(result: const WikiDistillResult.candidates([created, updated]));
    await open(tester);

    await tapIn(tester, 0, '고쳐서 저장');
    expect(find.byType(WikiNoteEditPage), findsOneWidget);
    String text(String key) =>
        tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
    expect(text('wiki-edit-title'), '기상 시간');
    expect(text('wiki-edit-summary'), '평일 7시');
    expect(text('wiki-edit-body'), '평일엔 7시에 일어난다 [[일기:e1]]');

    await tester.enterText(find.byKey(const Key('wiki-edit-title')), '기상');
    await tester.tap(find.byKey(const Key('wiki-edit-save')));
    await tester.pumpAndSettle();

    expect(find.byType(WikiNoteEditPage), findsNothing);
    expect(h.wiki.created.single.title, '기상');
    expect(h.wiki.created.single.sourceConversationId, 'c1');
    expect(inCard(0, find.text('저장함')), findsOneWidget);
    expect(sheet, findsOneWidget);
  });

  testWidgets('update 의 [고쳐서 저장]은 그 메모를 고친다', (tester) async {
    await setUp(result: const WikiDistillResult.candidates([updated]));
    await open(tester);

    await tapIn(tester, 0, '고쳐서 저장');
    await tester.tap(find.byKey(const Key('wiki-edit-save')));
    await tester.pumpAndSettle();

    expect(h.wiki.created, isEmpty);
    expect(h.wiki.updated.single.$1, 3);
    // 하나뿐이라 모두 처리 — 닫힌다.
    expect(sheet, findsNothing);
    expect(find.text('메모 1개를 저장했어요'), findsOneWidget);
  });

  testWidgets('잠기면 시트가 닫힌다', (tester) async {
    await setUp(result: const WikiDistillResult.candidates([created, updated]));
    await open(tester);
    expect(sheet, findsOneWidget);

    await h.relock(tester);

    expect(sheet, findsNothing);
    expect(find.text('기상 시간', skipOffstage: false), findsNothing);
    expect(h.wiki.created, isEmpty);
  });

  testWidgets('[고쳐서 저장] 화면이 떠 있는 중 잠겨도 아래 시트가 빠진다', (tester) async {
    await setUp(result: const WikiDistillResult.candidates([created, updated]));
    await open(tester);
    await tapIn(tester, 0, '고쳐서 저장');

    await h.relock(tester);

    expect(find.byType(BottomSheet, skipOffstage: false), findsNothing);
    expect(
      find.byKey(const Key('wiki-candidate-1'), skipOffstage: false),
      findsNothing,
    );
  });
}
