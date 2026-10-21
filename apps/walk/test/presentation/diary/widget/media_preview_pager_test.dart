import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/entry_media.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/presentation/diary/widget/entry_media_view.dart';
import 'package:walk/presentation/diary/widget/media_preview_pager.dart';
import 'package:walk/presentation/diary/widget/media_source_sheet.dart';

import '../../../support/diary_fixtures.dart';

class _MockStore extends Mock implements MediaStore {}

void main() {
  setUp(() {
    final store = _MockStore();
    when(() => store.resolve(any())).thenAnswer((_) => File('/missing'));
    getIt.registerSingleton<MediaStore>(store);
  });

  tearDown(getIt.reset);

  Widget app({
    List<EntryMedia> media = const [],
    bool importing = false,
    ValueChanged<MediaSource>? onAdd,
    ValueChanged<String>? onRemove,
  }) => MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ListView(
        children: [
          MediaPreviewPager(
            media: media,
            importing: importing,
            onAdd: onAdd ?? (_) {},
            onRemove: onRemove ?? (_) {},
            onReorder: (_, _) {},
          ),
        ],
      ),
    ),
  );

  testWidgets('비어 있으면 ＋ 칸만, 누르면 고르기 시트(글만 쓰기 없음) → 고른 곳', (tester) async {
    MediaSource? added;
    await tester.pumpWidget(app(onAdd: (s) => added = s));

    expect(find.text('사진·영상 추가'), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);

    await tester.tap(find.text('사진·영상 추가'));
    await tester.pumpAndSettle();
    expect(find.text('글만 쓰기'), findsNothing);
    await tester.tap(find.text('사진 찍기'));
    await tester.pumpAndSettle();

    expect(added, MediaSource.photo);
  });

  testWidgets('길게 누르거나 ✕ 로 뺀다', (tester) async {
    final removed = <String>[];
    await tester.pumpWidget(
      app(media: [photoMedia('m1')], onRemove: removed.add),
    );

    await tester.longPress(find.byType(EntryMediaView));
    await tester.tap(find.byTooltip('빼기'));
    await tester.pump();

    expect(removed, ['m1', 'm1']);
  });

  testWidgets('가져오는 중이면 ＋ 칸에 진행 표시, 눌러도 시트가 안 뜬다', (tester) async {
    await tester.pumpWidget(app(importing: true));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('사진·영상 추가'));
    await tester.pump();

    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('10개면 ＋ 칸이 없다', (tester) async {
    await tester.pumpWidget(
      app(media: [for (var i = 0; i < 10; i++) photoMedia('m$i')]),
    );

    for (var i = 0; i < 10; i++) {
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
    }

    expect(find.text('사진·영상 추가'), findsNothing);
  });
}
