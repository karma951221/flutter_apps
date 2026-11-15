import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/diary/entity/media_limits.dart';
import 'package:walk/presentation/diary/widget/composer_toolbar.dart';
import 'package:walk/presentation/diary/widget/media_source_sheet.dart';

void main() {
  late List<String> log;

  setUp(() => log = []);

  Future<void> pump(
    WidgetTester tester, {
    int count = 0,
    bool importing = false,
    VoidCallback? onDraft,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ComposerToolbar(
          count: count,
          importing: importing,
          onAdd: (s) => log.add(s.name),
          onDraft: onDraft,
        ),
      ),
    ),
  );

  IconButton button(WidgetTester tester, String tooltip) => tester.widget(
    find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(IconButton),
    ),
  );

  testWidgets('앨범 · 사진 · 영상 버튼이 각 고르기를 부른다', (tester) async {
    await pump(tester);

    for (final label in ['앨범에서 고르기', '사진 찍기', '영상 찍기']) {
      await tester.tap(find.byTooltip(label));
      await tester.pump();
    }

    expect(log, [
      MediaSource.gallery.name,
      MediaSource.photo.name,
      MediaSource.video.name,
    ]);
  });

  testWidgets('한도를 다 채우면 앨범 · 사진 · 영상 버튼이 꺼진다', (tester) async {
    await pump(tester, count: MediaLimits.maxItems);

    for (final label in ['앨범에서 고르기', '사진 찍기', '영상 찍기']) {
      expect(button(tester, label).onPressed, isNull, reason: label);
    }
  });

  testWidgets('가져오는 중이면 버튼이 꺼진다', (tester) async {
    await pump(tester, count: 1, importing: true);

    for (final label in ['앨범에서 고르기', '사진 찍기', '영상 찍기']) {
      expect(button(tester, label).onPressed, isNull, reason: label);
    }
  });

  testWidgets('onDraft 가 없으면 초안 버튼을 두지 않는다', (tester) async {
    await pump(tester);

    expect(find.byTooltip('초안 쓰기'), findsNothing);
  });

  testWidgets('onDraft 가 있으면 초안 버튼이 그것을 부른다', (tester) async {
    await pump(tester, onDraft: () => log.add('draft'));

    await tester.tap(find.byTooltip('초안 쓰기'));
    await tester.pump();

    expect(log, ['draft']);
  });
}
