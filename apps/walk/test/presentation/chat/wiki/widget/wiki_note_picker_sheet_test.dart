import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/chat/wiki/widget/wiki_note_picker_sheet.dart';

import '../../../../support/fake_wiki_repository.dart';
import '../wiki_harness.dart';

void main() {
  late WikiHarness h;

  setUp(() => h = WikiHarness());
  tearDown(() => h.tearDown());

  Finder row(int id) => find.byKey(Key('wiki-pick-note-$id'));

  final notes = [
    wikiNote(3, title: '출근 알람', summary: '평일 7시'),
    wikiNote(2, title: 'Sleep 기록', summary: '주말'),
    wikiNote(1, title: '산책 코스', summary: '한강 SLEEPY 길'),
  ];

  testWidgets('제목 검색으로 좁힌다(요약 포함, 대소문자 무시)', (tester) async {
    await h.setUp(notes: notes);
    await h.pump(tester, (context) => showWikiNotePicker(context));

    expect(find.text('메모 고르기'), findsOneWidget);
    expect(row(3), findsOneWidget);
    expect(row(2), findsOneWidget);
    expect(row(1), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('wiki-pick-note-search')),
      'sleep',
    );
    await tester.pumpAndSettle();
    expect(row(3), findsNothing);
    expect(row(2), findsOneWidget);
    expect(row(1), findsOneWidget);
  });

  testWidgets('지금 메모는 빠진다', (tester) async {
    await h.setUp(notes: notes);
    await h.pump(tester, (context) => showWikiNotePicker(context, exclude: 2));

    expect(row(2), findsNothing);
    expect(row(3), findsOneWidget);
  });

  testWidgets('행을 누르면 그 id', (tester) async {
    await h.setUp(notes: notes);
    await h.pump(tester, (context) => showWikiNotePicker(context));

    await tester.tap(row(3));
    await tester.pumpAndSettle();
    expect(h.results, [3]);
  });
}
