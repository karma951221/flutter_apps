import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/chat/wiki/widget/diary_entry_picker_sheet.dart';

import '../wiki_fakes.dart';
import '../wiki_harness.dart';

void main() {
  late WikiHarness h;

  setUp(() => h = WikiHarness());
  tearDown(() => h.tearDown());

  Finder row(String id) => find.byKey(Key('wiki-pick-entry-$id'));

  Future<void> pickDay(WidgetTester tester, String day) async {
    await tester.tap(find.byKey(const Key('wiki-pick-entry-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(day));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
  }

  testWidgets('위쪽에 근거 일기(휴지통 제외)', (tester) async {
    await h.setUp(
      entries: [
        wikiEntry('e1', body: '첫 기록'),
        wikiEntry('e2', body: '버린 기록', trashed: true),
      ],
    );
    await h.pump(
      tester,
      (context) =>
          showDiaryEntryPicker(context, suggested: ['e1', 'e2', 'gone']),
    );

    expect(find.text('일기 고르기'), findsOneWidget);
    expect(find.text('이 대화의 근거 일기'), findsOneWidget);
    expect(row('e1'), findsOneWidget);
    expect(row('e2'), findsNothing);
    expect(row('gone'), findsNothing);

    await tester.tap(row('e1'));
    await tester.pumpAndSettle();
    expect(h.results, ['e1']);
  });

  testWidgets('근거 일기가 없으면 그 머리도 없다', (tester) async {
    await h.setUp();
    await h.pump(
      tester,
      (context) => showDiaryEntryPicker(context, suggested: const []),
    );
    expect(find.text('이 대화의 근거 일기'), findsNothing);
    expect(find.byKey(const Key('wiki-pick-entry-date')), findsOneWidget);
  });

  testWidgets('날짜를 고르면 그날 기록', (tester) async {
    await h.setUp(
      entries: [
        wikiEntry('a', body: '하루 전 기록', occurredAt: DateTime(2026, 11, 1, 8)),
        wikiEntry('b', body: '오늘 기록', occurredAt: DateTime(2026, 11, 2, 7)),
      ],
    );
    await h.pump(
      tester,
      (context) => showDiaryEntryPicker(context, suggested: const []),
    );

    await pickDay(tester, '1');

    expect(h.diary.searches.single.$1, DateTime(2026, 11, 1));
    expect(h.diary.searches.single.$2.isBefore(DateTime(2026, 11, 2)), isTrue);
    expect(
      h.diary.searches.single.$2.isAfter(DateTime(2026, 11, 1, 23, 59)),
      isTrue,
    );
    expect(row('a'), findsOneWidget);
    expect(row('b'), findsNothing);

    await tester.tap(row('a'));
    await tester.pumpAndSettle();
    expect(h.results, ['a']);
  });

  testWidgets('없으면 빈 안내', (tester) async {
    await h.setUp(
      entries: [wikiEntry('b', occurredAt: DateTime(2026, 11, 2, 7))],
    );
    await h.pump(
      tester,
      (context) => showDiaryEntryPicker(context, suggested: const []),
    );

    await pickDay(tester, '1');

    expect(find.text('그날 기록이 없어요'), findsOneWidget);
    expect(row('b'), findsNothing);
  });
}
