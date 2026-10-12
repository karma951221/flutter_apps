import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/presentation/diary/widget/story_avatar.dart';
import 'package:walk/presentation/diary/widget/story_bar.dart';

import '../../../support/diary_fixtures.dart';

Story _story(String id, String title, {bool closed = false}) => Story(
  id: id,
  title: title,
  status: closed ? StoryStatus.closed : StoryStatus.open,
  startedAt: diaryT0,
  endedAt: closed ? diaryT0 : null,
  createdAt: diaryT0,
);

void main() {
  final daily = _story(Story.dailyId, '');
  final jeju = _story('jeju', '제주 여행');
  final trip = _story('trip', '출장');
  final busan = _story('busan', '부산', closed: true);

  Future<List<String?>> pump(
    WidgetTester tester, {
    List<Story>? open,
    List<Story> archived = const [],
    String? selectedId,
    Map<String, File> covers = const {},
  }) async {
    final selected = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StoryBar(
            open: open ?? [jeju, daily, trip],
            archived: archived,
            selectedId: selectedId,
            onSelect: selected.add,
            covers: covers,
          ),
        ),
      ),
    );
    return selected;
  }

  List<String> labelsInOrder(WidgetTester tester) {
    final avatars = tester.widgetList<StoryAvatar>(find.byType(StoryAvatar));
    final sorted = avatars.toList()
      ..sort(
        (a, b) => tester
            .getTopLeft(find.byWidget(a))
            .dx
            .compareTo(tester.getTopLeft(find.byWidget(b)).dx),
      );
    return [for (final a in sorted) a.label];
  }

  bool isSelected(WidgetTester tester, String label) => tester
      .widget<StoryAvatar>(find.widgetWithText(StoryAvatar, label))
      .selected;

  testWidgets('전체 → 열린 스토리(받은 순서) → 끝에 보관함, 기본 스토리 이름은 일상', (tester) async {
    await pump(tester, archived: [busan]);

    expect(labelsInOrder(tester), ['전체', '제주 여행', '일상', '출장', '보관함']);
  });

  testWidgets('보관함이 비면 보관함 항목이 없다', (tester) async {
    await pump(tester);

    expect(find.text('보관함'), findsNothing);
  });

  testWidgets('사용자가 이름을 바꾼 기본 스토리는 그 이름', (tester) async {
    await pump(tester, open: [_story(Story.dailyId, '하루하루')]);

    expect(find.text('하루하루'), findsOneWidget);
    expect(find.text('일상'), findsNothing);
  });

  testWidgets('고른 스토리 · 전체를 표시한다', (tester) async {
    await pump(tester, selectedId: 'jeju');
    expect(isSelected(tester, '제주 여행'), isTrue);
    expect(isSelected(tester, '전체'), isFalse);

    await pump(tester);
    expect(isSelected(tester, '전체'), isTrue);
    expect(isSelected(tester, '제주 여행'), isFalse);
  });

  testWidgets('누르면 그 스토리 id, 전체는 null', (tester) async {
    final selected = await pump(tester, selectedId: 'jeju');

    await tester.tap(find.text('출장'));
    await tester.tap(find.text('전체'));

    expect(selected, ['trip', null]);
  });

  testWidgets('보관함을 누르면 닫힌 스토리 목록이 열리고, 고르면 그 스토리', (tester) async {
    final selected = await pump(tester, archived: [busan]);

    await tester.tap(find.text('보관함'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppListTile, '부산'), findsOneWidget);

    await tester.tap(find.text('부산'));
    await tester.pumpAndSettle();

    expect(selected, ['busan']);
    expect(find.byType(AppListTile), findsNothing);
  });

  testWidgets('닫힌 스토리를 보는 중이면 보관함을 표시한다', (tester) async {
    await pump(tester, archived: [busan], selectedId: 'busan');

    expect(isSelected(tester, '보관함'), isTrue);
    expect(isSelected(tester, '전체'), isFalse);
  });

  testWidgets('표지 파일이 있는 스토리는 그 사진, 없으면 이니셜(R17)', (tester) async {
    final file = File('/fake/media/p1.jpg');
    await pump(tester, covers: {'jeju': file});

    StoryAvatar avatar(String label) => tester.widget<StoryAvatar>(
      find.byWidgetPredicate((w) => w is StoryAvatar && w.label == label),
    );
    expect(avatar('제주 여행').image, file);
    expect(avatar('출장').image, isNull);
    final circle = tester.widget<CircleAvatar>(
      find.descendant(
        of: find.byWidget(avatar('제주 여행')),
        matching: find.byType(CircleAvatar),
      ),
    );
    expect(circle.foregroundImage, isNotNull);
    // 파일을 읽지 못해도 이니셜이 남는다.
    expect(
      find.descendant(
        of: find.byWidget(avatar('제주 여행')),
        matching: find.text('제'),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
