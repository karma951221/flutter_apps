import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/presentation/diary/widget/story_avatar.dart';
import 'package:walk/presentation/diary/widget/story_row.dart';

import '../../../support/diary_fixtures.dart';

Story _story({DateTime? end, String title = '제주 여행'}) => Story(
  id: 'jeju',
  title: title,
  status: end == null ? StoryStatus.open : StoryStatus.closed,
  startedAt: DateTime(2026, 10, 1),
  endedAt: end,
  createdAt: DateTime(2026, 10, 1),
);

void main() {
  Future<void> pump(WidgetTester tester, Widget row) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: row),
    ),
  );

  testWidgets('표지 원 · 이름 · 기간 · 기록 수', (tester) async {
    await pump(
      tester,
      StoryRow(story: _story(), now: DateTime(2026, 11, 1), count: 3),
    );

    expect(find.byType(StoryCoverCircle), findsOneWidget);
    expect(find.text('제주 여행'), findsOneWidget);
    expect(find.textContaining('진행 중 · 기록 3개'), findsOneWidget);
    expect(find.byType(AppSelectTile), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('수를 모르면 기간만, 끝난 스토리는 끝 날짜', (tester) async {
    await pump(
      tester,
      StoryRow(
        story: _story(end: DateTime(2026, 10, 3)),
        now: DateTime(2026, 11, 1),
      ),
    );

    expect(find.textContaining('기록'), findsNothing);
    expect(find.textContaining('진행 중'), findsNothing);
    expect(find.textContaining('10월 3일'), findsOneWidget);
  });

  testWidgets('이름이 비면 기본 이름(일상)', (tester) async {
    await pump(
      tester,
      StoryRow(
        story: _story(title: ''),
        now: diaryT0,
      ),
    );

    expect(find.text('일상'), findsOneWidget);
  });

  testWidgets('selected 면 고르기 행 — 고른 행에만 primary 체크, 누르면 onTap', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      Column(
        children: [
          StoryRow(
            key: const Key('a'),
            story: _story(),
            now: diaryT0,
            selected: true,
            onTap: () => taps++,
          ),
          StoryRow(
            key: const Key('b'),
            story: _story(title: '부산'),
            now: diaryT0,
            selected: false,
          ),
        ],
      ),
    );

    expect(find.byType(AppSelectTile), findsNWidgets(2));
    final check = find.descendant(
      of: find.byKey(const Key('a')),
      matching: find.byIcon(Icons.check),
    );
    expect(check, findsOneWidget);
    expect(
      tester.widget<Icon>(check).color,
      Theme.of(tester.element(check)).colorScheme.primary,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('b')),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('a')));
    expect(taps, 1);
  });
}
