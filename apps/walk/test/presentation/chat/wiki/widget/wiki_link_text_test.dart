import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/presentation/chat/widget/cited_entry_chip.dart';
import 'package:walk/presentation/chat/wiki/widget/wiki_link_text.dart';

import '../../../../support/fake_wiki_repository.dart';
import '../wiki_fakes.dart';

void main() {
  final openedNotes = <int>[];
  final openedEntries = <String>[];

  setUp(() {
    openedNotes.clear();
    openedEntries.clear();
  });

  Future<void> pump(
    WidgetTester tester,
    String body, {
    Map<int, WikiNote> notes = const {},
    Map<String, DiaryEntry> entries = const {},
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: WikiLinkText(
          body: body,
          notes: notes,
          entries: entries,
          onOpenNote: openedNotes.add,
          onOpenEntry: openedEntries.add,
        ),
      ),
    ),
  );

  ActionChip chip(WidgetTester tester, String label) => tester.widget(
    find.ancestor(of: find.text(label), matching: find.byType(ActionChip)),
  );

  testWidgets('[[3]] 은 메모 제목 칩, 누르면 onOpenNote(3)', (tester) async {
    await pump(
      tester,
      '관련: [[3]]',
      notes: {3: wikiNote(3, title: '출근 알람')},
    );

    expect(chip(tester, '출근 알람').onPressed, isNotNull);
    await tester.tap(find.text('출근 알람'));
    expect(openedNotes, [3]);
  });

  testWidgets('[[일기:e1]] 은 날짜 · 본문 앞부분 칩', (tester) async {
    final entry = wikiEntry('e1', body: '한강을 따라 오래 걸었다. 바람이 차가웠지만 좋았다.');
    await pump(tester, '근거: [[일기:e1]]', entries: {'e1': entry});

    final label = CitedEntryChip.label(entry, 'ko');
    expect(find.text(label), findsOneWidget);
    await tester.tap(find.text(label));
    expect(openedEntries, ['e1']);
  });

  testWidgets("없는 메모 · 일기는 '지워진 메모' · '지워진 일기' 흐린 칩이고 눌러도 아무 일 없다", (
    tester,
  ) async {
    await pump(tester, '[[9]] 그리고 [[일기:gone]]');

    expect(chip(tester, '지워진 메모').onPressed, isNull);
    expect(chip(tester, '지워진 일기').onPressed, isNull);
    await tester.tap(find.text('지워진 메모'), warnIfMissed: false);
    await tester.tap(find.text('지워진 일기'), warnIfMissed: false);
    expect(openedNotes, isEmpty);
    expect(openedEntries, isEmpty);
  });

  testWidgets('링크가 아닌 글은 그대로', (tester) async {
    await pump(tester, '평일 [[012]] 07:00 [[x]]');

    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('평일 [[012]] 07:00 [[x]]', findRichText: true), findsOneWidget);
  });
}
