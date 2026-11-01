import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/entity/diary_usage.dart';
import 'package:walk/domain/diary/entity/trash_retention.dart';
import 'package:walk/presentation/settings/page/diary_settings_page.dart';

import '../settings_harness.dart';

void main() {
  final h = SettingsHarness();

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(h.setUp);
  tearDown(h.tearDown);

  Finder inRow(String key, String text) =>
      find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

  void usage(DiaryUsage value) =>
      when(h.diaryRepo.usage).thenAnswer((_) async => value);

  testWidgets('보관 기간 · 용량(크기 · 사진 · 영상 수 · 휴지통 몫) · 이 폰에만 저장 안내', (
    tester,
  ) async {
    usage(
      const DiaryUsage(
        photos: 340,
        videos: 52,
        bytes: 1288490189,
        trashBytes: 83886080,
      ),
    );
    await h.pump(tester, const DiarySettingsPage());

    expect(inRow('settings-diary-retention', '7일'), findsOneWidget);
    expect(find.text('사용 중 1.2GB'), findsOneWidget);
    expect(find.text('사진 340장 · 영상 52개, 휴지통 80.0MB 포함'), findsOneWidget);
    expect(find.text('기록은 이 폰에만 저장돼요. 앱을 지우면 함께 사라져요.'), findsOneWidget);
  });

  testWidgets('용량은 B · KB 도 줄여 쓴다', (tester) async {
    usage(const DiaryUsage(photos: 0, videos: 0, bytes: 2048, trashBytes: 512));
    await h.pump(tester, const DiarySettingsPage());

    expect(find.text('사용 중 2KB'), findsOneWidget);
    expect(find.text('사진 0장 · 영상 0개, 휴지통 512B 포함'), findsOneWidget);
  });

  testWidgets('열 때마다 용량을 다시 읽는다', (tester) async {
    await h.pump(tester, const DiarySettingsPage());
    usage(
      const DiaryUsage(
        photos: 1,
        videos: 0,
        bytes: 5 * 1024 * 1024,
        trashBytes: 0,
      ),
    );

    await h.pump(tester, const SizedBox());
    await h.pump(tester, const DiarySettingsPage());

    expect(find.text('사용 중 5.0MB'), findsOneWidget);
  });

  testWidgets('휴지통 보관 기간: 4개 중 고르면 저장한다(기본 7일)', (tester) async {
    await h.pump(tester, const DiarySettingsPage());

    await tester.tap(find.byKey(const Key('settings-diary-retention')));
    await tester.pumpAndSettle();
    for (final label in ['1일', '7일', '30일', '지우지 않음']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    await tester.tap(find.text('30일').last);
    await tester.pumpAndSettle();

    expect(h.diaryPrefs.trashRetention, TrashRetention.day30);
    expect(inRow('settings-diary-retention', '30일'), findsOneWidget);
  });

  testWidgets('일기가 잠긴 동안 보관 기간 행은 열리지 않는다', (tester) async {
    await h.lockWithPin();
    await h.pump(tester, const DiarySettingsPage());

    await tester.tap(find.byKey(const Key('settings-diary-retention')));
    await tester.pumpAndSettle();

    expect(find.text('지우지 않음'), findsNothing);
  });

  testWidgets('보관 기간 시트가 열린 사이 잠기면 고른 값을 저장하지 않는다', (tester) async {
    await h.lockWithPin();
    await h.diaryLock.submit('1234');
    await h.pump(tester, const DiarySettingsPage());

    await tester.tap(find.byKey(const Key('settings-diary-retention')));
    await tester.pumpAndSettle();
    h.diaryLock.start();
    await tester.pump();
    await tester.tap(find.text('지우지 않음').last);
    await tester.pumpAndSettle();

    expect(h.diaryPrefs.trashRetention, TrashRetention.day7);
  });
}
