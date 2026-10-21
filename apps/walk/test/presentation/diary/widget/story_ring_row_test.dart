import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/presentation/diary/widget/story_ring.dart';
import 'package:walk/presentation/diary/widget/story_ring_row.dart';

import '../../../support/diary_fixtures.dart';

Story _story(
  String id,
  String title, {
  DateTime? lastPostedAt,
  DateTime? endedAt,
}) => Story(
  id: id,
  title: title,
  status: endedAt == null ? StoryStatus.open : StoryStatus.closed,
  startedAt: diaryT0,
  endedAt: endedAt,
  lastPostedAt: lastPostedAt,
  createdAt: diaryT0,
);

void main() {
  final old = _story('old', '오래', lastPostedAt: diaryT0);
  final fresh = _story(
    'fresh',
    '최근',
    lastPostedAt: diaryT0.add(const Duration(days: 2)),
  );
  final empty = _story('empty', '빈것');

  group('ringOrder', () {
    test('진행 중은 최신 기록순 · 빈 것 뒤, 닫힘은 endedAt 최신순 10개까지', () {
      final closed = [
        for (var i = 0; i < 12; i++)
          _story('c$i', 'c$i', endedAt: diaryT0.add(Duration(days: i))),
      ];
      final order = ringOrder([empty, old, fresh], closed);
      expect(order.take(3).map((s) => s.id), ['fresh', 'old', 'empty']);
      final tail = order.skip(3).map((s) => s.id).toList();
      expect(tail.length, 10);
      expect(tail.first, 'c11');
      expect(tail.last, 'c2');
    });
  });

  Future<void> pump(
    WidgetTester tester, {
    List<Story>? open,
    List<Story> archived = const [],
    String? selectedId,
    VoidCallback? onCreate,
    ValueChanged<Story>? onOpen,
    ValueChanged<Story>? onLongPress,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StoryRingRow(
          open: open ?? [empty, old, fresh],
          archived: archived,
          covers: const {},
          onCreate: onCreate ?? () {},
          onOpen: onOpen ?? (_) {},
          onLongPress: onLongPress ?? (_) {},
          onSeeAll: () {},
          selectedId: selectedId,
        ),
      ),
    ),
  );

  testWidgets('＋ · 진행 중(최신순, 빈 것 뒤) · 닫힘 10개까지 · 모두 보기 순서', (tester) async {
    tester.view.physicalSize = const Size(4000, 800);
    addTearDown(tester.view.reset);
    final closed = [
      for (var i = 0; i < 12; i++)
        _story('c$i', 'c$i', endedAt: diaryT0.add(Duration(days: i))),
    ];
    await pump(tester, archived: closed);
    final names = ['새 스토리', '최근', '오래', '빈것', 'c11', 'c2', '모두 보기'];
    final xs = [for (final n in names) tester.getTopLeft(find.text(n)).dx];
    expect([...xs]..sort(), xs);
    expect(find.text('c1'), findsNothing);
    expect(find.text('c0'), findsNothing);
  });

  testWidgets('탭은 onOpen, 길게는 onLongPress, ＋ 는 onCreate', (tester) async {
    final opened = <String>[];
    final longed = <String>[];
    var created = 0;
    await pump(
      tester,
      onCreate: () => created++,
      onOpen: (s) => opened.add(s.id),
      onLongPress: (s) => longed.add(s.id),
    );
    await tester.tap(find.text('최근'));
    await tester.longPress(find.text('오래'));
    await tester.tap(find.text('새 스토리'));
    expect(opened, ['fresh']);
    expect(longed, ['old']);
    expect(created, 1);
  });

  testWidgets('진행 중 링은 primary, 닫힘은 outlineVariant', (tester) async {
    await pump(
      tester,
      open: [fresh],
      archived: [_story('c', '닫힘', endedAt: diaryT0)],
    );
    final scheme = Theme.of(
      tester.element(find.byType(StoryRingRow)),
    ).colorScheme;
    Color ringColor(String name) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.ancestor(
                of: find.text(name),
                matching: find.byType(StoryRing),
              ),
              matching: find.byKey(StoryRing.ringKey),
            )
            .first,
      );
      return ((box.decoration as BoxDecoration).border! as Border).top.color;
    }

    expect(ringColor('최근'), scheme.primary);
    expect(ringColor('닫힘'), scheme.outlineVariant);
  });

  testWidgets('selectedId 에 체크', (tester) async {
    await pump(tester, selectedId: 'old');
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('오래'),
          matching: find.byType(StoryRing),
        ),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });
}
