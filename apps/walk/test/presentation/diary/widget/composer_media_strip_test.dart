import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/presentation/diary/widget/composer_media_strip.dart';
import 'package:walk/presentation/diary/widget/entry_media_view.dart';

import '../../../support/diary_fixtures.dart';

class _MockStore extends Mock implements MediaStore {}

void main() {
  late List<String> log;

  setUp(() {
    log = [];
    final store = _MockStore();
    when(() => store.resolve(any())).thenAnswer((_) => File('/missing'));
    getIt.registerSingleton<MediaStore>(store);
  });

  tearDown(getIt.reset);

  Future<void> pump(
    WidgetTester tester, {
    List<EntryMedia> media = const [],
    bool importing = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListView(
          children: [
            ComposerMediaStrip(
              media: media,
              importing: importing,
              onRemove: (id) => log.add('remove $id'),
              onReorder: (from, to) => log.add('move $from→$to'),
            ),
          ],
        ),
      ),
    ),
  );

  testWidgets('비어 있고 가져오는 중도 아니면 아무것도 그리지 않는다', (tester) async {
    await pump(tester);

    expect(find.byType(EntryMediaView), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ReorderableListView), findsNothing);
  });

  testWidgets('붙인 것마다 썸네일, ✕ 로 뺀다', (tester) async {
    await pump(tester, media: [photoMedia('m1'), videoMedia('v1')]);

    expect(find.byType(EntryMediaView), findsNWidgets(2));
    expect(find.byTooltip('빼기'), findsNWidgets(2));

    await tester.tap(find.byTooltip('빼기').last);
    await tester.pump();

    expect(log, ['remove v1']);
  });

  testWidgets('끌어 놓은 자리를 뺀 뒤 목록 기준으로 넘긴다', (tester) async {
    await pump(
      tester,
      media: [photoMedia('a'), photoMedia('b'), photoMedia('c')],
    );

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorder(0, 3);
    list.onReorder(2, 0);

    expect(log, ['move 0→2', 'move 2→0']);
  });

  testWidgets('가져오는 중이면 진행 표시', (tester) async {
    await pump(tester, media: [photoMedia('m1')], importing: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
