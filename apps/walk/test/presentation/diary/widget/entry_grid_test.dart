import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/entity/story.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/presentation/diary/widget/entry_grid.dart';
import 'package:walk/presentation/diary/widget/entry_media_view.dart';

import '../../../support/diary_fixtures.dart';

class _MockStore extends Mock implements MediaStore {}

DiaryEntry _entry(
  String id,
  DateTime at, {
  String body = '',
  List<EntryMedia> media = const [],
}) => DiaryEntry(
  id: id,
  storyId: Story.dailyId,
  body: body,
  occurredAt: at,
  createdAt: at,
  updatedAt: at,
  media: media,
  tags: const [],
);

void main() {
  setUp(() {
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    getIt.registerSingleton<MediaStore>(store);
  });

  tearDown(getIt.reset);

  Finder tile(String id) => find.byKey(ValueKey('grid-$id'));

  testWidgets('최신 위 3열, 영상 ▶, 여러 장 아이콘, 글 타일, 탭 onOpen', (tester) async {
    final opened = <String>[];
    final entries = [
      _entry('old', DateTime(2026, 10, 1), body: '오래된 글'),
      _entry('video', DateTime(2026, 10, 3), media: [videoMedia('v1')]),
      _entry(
        'many',
        DateTime(2026, 10, 4),
        media: [photoMedia('p1'), photoMedia('p2')],
      ),
      _entry('one', DateTime(2026, 10, 2), media: [photoMedia('p3')]),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EntryGrid(entries: entries, onOpen: (e) => opened.add(e.id)),
        ),
      ),
    );

    // 최신순: many(10/4) · video(10/3) · one(10/2) / old(10/1).
    final many = tester.getTopLeft(tile('many'));
    final video = tester.getTopLeft(tile('video'));
    final one = tester.getTopLeft(tile('one'));
    final old = tester.getTopLeft(tile('old'));
    expect(many.dy, video.dy);
    expect(video.dy, one.dy);
    expect(many.dx, lessThan(video.dx));
    expect(video.dx, lessThan(one.dx));
    expect(old.dy, greaterThan(many.dy));
    expect(old.dx, many.dx);
    // 정사각.
    final size = tester.getSize(tile('many'));
    expect(size.width, closeTo(size.height, 0.01));

    // 첫 미디어 썸네일 · 영상 ▶ · 여러 장 겹침 아이콘 · 글 타일.
    expect(
      find.descendant(of: tile('many'), matching: find.byType(EntryMediaView)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: tile('many'),
        matching: find.byIcon(Icons.collections_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: tile('one'),
        matching: find.byIcon(Icons.collections_outlined),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: tile('video'),
        matching: find.byIcon(Icons.play_circle_outline),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile('old'), matching: find.text('오래된 글')),
      findsOneWidget,
    );

    await tester.tap(tile('video'));
    await tester.tap(tile('old'));
    expect(opened, ['video', 'old']);
  });

  testWidgets('슬리버로도 쓴다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverEntryGrid(
                entries: [_entry('a', diaryT0, body: '글')],
                onOpen: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tile('a'), findsOneWidget);
  });
}
