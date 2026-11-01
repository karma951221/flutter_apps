import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/presentation/chat/wiki/open_wiki.dart';
import 'package:walk/presentation/chat/wiki/page/wiki_note_edit_page.dart';
import 'package:walk/presentation/chat/wiki/page/wiki_note_page.dart';
import 'package:walk/presentation/chat/wiki/page/wiki_page.dart';
import 'package:walk/presentation/lock/widget/lock_secret_input.dart';

import '../../../../support/fake_wiki_repository.dart';
import '../wiki_harness.dart';

void main() {
  late WikiHarness h;

  setUp(() => h = WikiHarness());
  tearDown(() => h.tearDown());

  Finder row(int id) => find.byKey(Key('wiki-note-$id'));
  final appBarMenu = find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.more_vert),
  );

  testWidgets('최근 순 행 — 제목 · 요약', (tester) async {
    await h.setUp(
      notes: [
        wikiNote(2, title: '출근 알람', summary: '평일 07:00 기상'),
        wikiNote(1, title: '수면 패턴', summary: '주말은 늦게'),
      ],
    );
    await h.pump(tester, openWikiPage);

    expect(find.widgetWithText(AppBar, '위키'), findsOneWidget);
    expect(
      tester.getTopLeft(row(2)).dy,
      lessThan(tester.getTopLeft(row(1)).dy),
    );
    final date = DateFormat.yMMMd('ko').format(wikiNote(2).updatedAt);
    expect(
      find.descendant(of: row(2), matching: find.text('출근 알람')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row(2), matching: find.text('평일 07:00 기상\n$date 수정')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('wiki-not-indexed')), findsNothing);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
  });

  testWidgets('빈 상태 문구', (tester) async {
    await h.setUp();
    await h.pump(tester, openWikiPage);

    expect(
      find.widgetWithText(
        AppPlaceholder,
        '대화에서 [위키로 정리]를 누르면 남길 내용을 골라 저장할 수 있어요',
      ),
      findsOneWidget,
    );
  });

  testWidgets('벤더 이름이 든 안내', (tester) async {
    await h.setUp(notes: [wikiNote(1)]);
    await h.pump(tester, openWikiPage);

    expect(
      find.text(
        '위키 색인(제목 · 요약)은 질문할 때마다, 본문은 모델이 필요할 때 Claude로 보내져요. '
        '임시 대화에는 보내지 않아요.',
      ),
      findsOneWidget,
    );
  });

  testWidgets("색인 밖 메모가 있으면 'n개' 행과 행 표시", (tester) async {
    await h.setUp(
      notes: [for (var id = 51; id >= 1; id--) wikiNote(id)],
      size: WikiIndexSize.small,
    );
    await h.pump(tester, openWikiPage);

    expect(
      find.descendant(
        of: find.byKey(const Key('wiki-not-indexed')),
        matching: find.text('색인에 안 실린 메모 1개 · 색인 크기 바꾸기'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row(51),
        matching: find.byIcon(Icons.visibility_off_outlined),
      ),
      findsNothing,
    );
    await tester.scrollUntilVisible(row(1), 200);
    final hidden = find.descendant(
      of: row(1),
      matching: find.byIcon(Icons.visibility_off_outlined),
    );
    expect(hidden, findsOneWidget);
    expect(tester.widget<Icon>(hidden).semanticLabel, '색인에 안 실림');
  });

  testWidgets("'색인에 안 실린 메모' 행을 누르면 크기 시트, '크게'를 고르면 행이 사라진다", (tester) async {
    await h.setUp(
      notes: [for (var id = 51; id >= 1; id--) wikiNote(id)],
      size: WikiIndexSize.small,
    );
    await h.pump(tester, openWikiPage);

    await tester.tap(find.byKey(const Key('wiki-not-indexed')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wiki-size-large')), findsOneWidget);
    expect(find.textContaining('지금 위키 51개'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wiki-size-large')));
    await tester.pumpAndSettle();

    expect(h.settings.wikiIndexSize, WikiIndexSize.large);
    expect(find.byKey(const Key('wiki-not-indexed')), findsNothing);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
  });

  testWidgets('행을 누르면 그 메모 화면', (tester) async {
    await h.setUp(
      notes: [wikiNote(1, title: '수면 패턴', summary: '주말은 늦게')],
    );
    await h.pump(tester, openWikiPage);

    await tester.tap(row(1));
    await tester.pumpAndSettle();
    expect(find.byType(WikiNotePage), findsOneWidget);
    expect(find.widgetWithText(AppBar, '수면 패턴'), findsOneWidget);
  });

  testWidgets('모두 지우기는 확인 뒤에만, 취소면 그대로', (tester) async {
    await h.setUp(notes: [wikiNote(2), wikiNote(1)]);
    await h.pump(tester, openWikiPage);

    await tester.tap(appBarMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('위키 모두 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('위키를 모두 지울까요?'), findsOneWidget);
    expect(find.text('메모 2개를 지워요. 대화와 사용량 기록은 남아요.'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, '취소'));
    await tester.pumpAndSettle();
    expect(h.wiki.deleteAllCalls, 0);
    expect(row(2), findsOneWidget);

    await tester.tap(appBarMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('위키 모두 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, '모두 지우기'));
    await tester.pumpAndSettle();

    expect(h.wiki.deleteAllCalls, 1);
    expect(row(2), findsNothing);
    expect(row(1), findsNothing);
  });

  testWidgets('모두 지우기가 실패하면 스낵바, 목록은 그대로', (tester) async {
    await h.setUp(notes: [wikiNote(1)]);
    h.wiki.failWrites = true;
    await h.pump(tester, openWikiPage);

    await tester.tap(appBarMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('위키 모두 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, '모두 지우기'));
    await tester.pumpAndSettle();

    expect(find.text('메모를 지우지 못했어요'), findsOneWidget);
    expect(row(1), findsOneWidget);
  });

  testWidgets('메모가 없으면 ⋮ 항목 없음', (tester) async {
    await h.setUp();
    await h.pump(tester, openWikiPage);

    expect(appBarMenu, findsNothing);
  });

  testWidgets('목록을 읽지 못하면 오류 안내', (tester) async {
    await h.setUp(notes: [wikiNote(1)]);
    h.wiki.failList = true;
    await h.pump(tester, openWikiPage);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.widgetWithText(AppPlaceholder, '위키를 불러오지 못했어요'),
      findsOneWidget,
    );
  });

  testWidgets('잠겨 있으면 목록이 트리에 없다', (tester) async {
    await h.setUp(notes: [wikiNote(1)]);
    await h.lockRepo.setSecret(LockMethod.pin, '1234');
    await h.lockRepo.saveConfig(const LockConfig(enabled: true));
    h.lock.start();
    await h.pump(tester, openWikiPage);

    expect(find.byType(LockSecretInput), findsOneWidget);
    expect(find.byType(WikiPage), findsNothing);
    expect(row(1), findsNothing);

    await h.lock.submit('1234');
    await tester.pumpAndSettle();
    expect(row(1), findsOneWidget);
  });

  testWidgets('[추가] → 빈 새 메모 편집, 저장하면 목록에 보인다', (tester) async {
    await h.setUp(notes: [wikiNote(1)]);
    await h.pump(tester, openWikiPage);

    await tester.tap(find.byKey(const Key('wiki-add')));
    await tester.pumpAndSettle();
    expect(find.byType(WikiNoteEditPage), findsOneWidget);
    expect(find.text('새 메모'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('wiki-edit-title')), '새 제목');
    await tester.enterText(find.byKey(const Key('wiki-edit-summary')), '새 요약');
    await tester.tap(find.byKey(const Key('wiki-edit-save')));
    await tester.pumpAndSettle();

    expect(find.byType(WikiNoteEditPage), findsNothing);
    expect(row(2), findsOneWidget);
    expect(h.wiki.created.single.sourceConversationId, isNull);
  });
}
