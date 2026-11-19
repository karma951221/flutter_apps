import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/presentation/diary/widget/story_picker_sheet.dart';
import 'package:walk/presentation/diary/widget/story_row.dart';

import '../../../support/diary_fixtures.dart';

final _stories = [
  Story(
    id: Story.dailyId,
    title: '',
    status: StoryStatus.open,
    startedAt: diaryT0,
    createdAt: diaryT0,
  ),
  Story(
    id: 'jeju',
    title: '제주 여행',
    status: StoryStatus.open,
    startedAt: diaryT0,
    createdAt: diaryT0,
  ),
];

void main() {
  String? picked;

  setUp(() => picked = null);

  Future<void> open(WidgetTester tester, {bool allowCreate = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => picked = await StoryPickerSheet.show(
                context,
                stories: _stories,
                selectedId: Story.dailyId,
                now: diaryT0,
                allowCreate: allowCreate,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('기본은 새 스토리 항목이 없다', (tester) async {
    await open(tester);

    expect(find.text('제주 여행'), findsOneWidget);
    expect(find.text('새 스토리'), findsNothing);
  });

  testWidgets('allowCreate 면 새 스토리 항목, 누르면 createNew 로 닫힌다', (tester) async {
    await open(tester, allowCreate: true);

    await tester.tap(find.text('새 스토리'));
    await tester.pumpAndSettle();

    expect(picked, StoryPickerSheet.createNew);
  });

  testWidgets('행은 StoryRow 이고 고른 스토리에만 primary 체크', (tester) async {
    await open(tester);

    expect(find.byType(StoryRow), findsNWidgets(2));
    final check = find.byIcon(Icons.check);
    expect(check, findsOneWidget);
    expect(
      find.ancestor(of: check, matching: find.byType(StoryRow)),
      findsOneWidget,
    );
    final theme = Theme.of(tester.element(check));
    expect(tester.widget<Icon>(check).color, theme.colorScheme.primary);
    // 일상(selectedId) 행에 체크.
    expect(
      find.descendant(
        of: find.ancestor(of: find.text('일상'), matching: find.byType(StoryRow)),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });
}
