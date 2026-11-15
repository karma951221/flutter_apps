import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/diary/entity/media_limits.dart';
import 'package:walk/presentation/diary/widget/composer_toolbar.dart';

void main() {
  late List<String> log;

  setUp(() => log = []);

  Future<void> pump(
    WidgetTester tester, {
    int count = 0,
    bool importing = false,
    VoidCallback? onDraft,
    bool drafting = false,
    bool canRewrite = false,
    bool draftEnabled = true,
    bool? photosOn,
    bool photosSupported = true,
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
          drafting: drafting,
          onStopDraft: () => log.add('stop'),
          canRewrite: canRewrite,
          draftEnabled: draftEnabled,
          photosOn: photosOn,
          photosSupported: photosSupported,
          onPhotosChanged: (on) => log.add('photos:$on'),
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

  testWidgets('초안을 받은 뒤에는 같은 자리가 다시 쓰기다', (tester) async {
    await pump(tester, onDraft: () => log.add('draft'), canRewrite: true);

    await tester.tap(find.byTooltip('다시 쓰기'));
    await tester.pump();

    expect(find.byTooltip('초안 쓰기'), findsNothing);
    expect(log, ['draft']);
  });

  testWidgets('쓰는 중에는 ✨ 자리가 멈추기다', (tester) async {
    await pump(tester, onDraft: () => log.add('draft'), drafting: true);

    expect(find.byTooltip('초안 쓰기'), findsNothing);
    await tester.tap(find.byTooltip('멈추기'));
    await tester.pump();

    expect(log, ['stop']);
  });

  testWidgets('재료가 없으면 ✨ 가 꺼지고 툴팁이 이유를 말한다', (tester) async {
    await pump(tester, onDraft: () => log.add('draft'), draftEnabled: false);

    expect(button(tester, '한 줄 적거나 사진 보여 주기를 켜세요').onPressed, isNull);
  });

  testWidgets('사진 보여 주기는 photosOn 이 있을 때만 보이고 누르면 바꾼다', (tester) async {
    await pump(tester, onDraft: () {});
    expect(find.text('사진 보여 주기'), findsNothing);

    await pump(tester, onDraft: () {}, photosOn: false);
    await tester.tap(find.text('사진 보여 주기'));
    await tester.pump();

    expect(log, ['photos:true']);
  });

  testWidgets('초안 모델이 사진을 못 보면 사진 보여 주기가 꺼지고 이유를 보인다', (tester) async {
    await pump(tester, onDraft: () {}, photosOn: false, photosSupported: false);

    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(chip.onSelected, isNull);
    expect(find.byTooltip('이 모델은 사진을 볼 수 없어요'), findsOneWidget);
  });
}
