import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/diary/page/story_form_sheet.dart';

import '../../../support/diary_fixtures.dart';

void main() {
  // 2026-10-10 09:00
  final now = diaryT0;

  Future<List<Object?>> pump(
    WidgetTester tester,
    Future<Object?> Function(BuildContext context) open,
  ) async {
    final results = <Object?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => results.add(await open(context)),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return results;
  }

  Future<void> pickDay(WidgetTester tester, String rowText, String day) async {
    await tester.tap(find.textContaining(rowText));
    await tester.pumpAndSettle();
    await tester.tap(find.text(day));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String label) =>
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, label))
          .onPressed !=
      null;

  group('만들기', () {
    testWidgets('시작일 기본은 오늘 0시, 종료일 없음 · 제목이 비면 만들 수 없다', (tester) async {
      final results = await pump(
        tester,
        (context) => StoryFormSheet.create(context, now: now),
      );

      expect(find.text('시작일 10월 10일'), findsOneWidget);
      expect(find.text('종료일 없음 (진행 중)'), findsOneWidget);
      expect(enabled(tester, '만들기'), isFalse);

      await tester.enterText(find.byType(TextField), '  ');
      await tester.pump();
      expect(enabled(tester, '만들기'), isFalse);

      await tester.enterText(find.byType(TextField), '제주 여행');
      await tester.pump();
      await tester.tap(find.widgetWithText(AppButton, '만들기'));
      await tester.pumpAndSettle();

      expect(results.single, (
        title: '제주 여행',
        startedAt: DateTime(2026, 10, 10),
        endedAt: null,
      ));
    });

    testWidgets('지난 시작일 · 종료일을 고르면 종료일은 그날 끝', (tester) async {
      final results = await pump(
        tester,
        (context) => StoryFormSheet.create(context, now: now),
      );
      await tester.enterText(find.byType(TextField), '추석');

      await pickDay(tester, '시작일', '3');
      await pickDay(tester, '종료일', '5');
      expect(find.text('시작일 10월 3일'), findsOneWidget);
      expect(find.text('종료일 10월 5일'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, '만들기'));
      await tester.pumpAndSettle();

      expect(results.single, (
        title: '추석',
        startedAt: DateTime(2026, 10, 3),
        endedAt: DateTime(2026, 10, 5, 23, 59, 59, 999),
      ));
    });

    testWidgets('종료일을 지우면 다시 진행 중', (tester) async {
      await pump(tester, (context) => StoryFormSheet.create(context, now: now));
      await pickDay(tester, '종료일', '10');
      expect(find.text('종료일 10월 10일'), findsOneWidget);

      await tester.tap(find.byTooltip('종료일 지우기'));
      await tester.pumpAndSettle();

      expect(find.text('종료일 없음 (진행 중)'), findsOneWidget);
    });

    testWidgets('시작일을 종료일 뒤로 옮기면 종료일을 비운다', (tester) async {
      await pump(tester, (context) => StoryFormSheet.create(context, now: now));
      await pickDay(tester, '시작일', '3');
      await pickDay(tester, '종료일', '5');

      await pickDay(tester, '시작일', '7');

      expect(find.text('종료일 없음 (진행 중)'), findsOneWidget);
    });
  });

  test('endOfDay: 그날 끝, 오늘이면 지금', () {
    expect(
      StoryFormSheet.endOfDay(DateTime(2026, 10, 5), now),
      DateTime(2026, 10, 5, 23, 59, 59, 999),
    );
    expect(StoryFormSheet.endOfDay(DateTime(2026, 10, 10), now), now);
  });

  group('이름 바꾸기', () {
    testWidgets('지금 이름으로 채워 열고, 바꾼 이름을 돌려준다', (tester) async {
      final results = await pump(
        tester,
        (context) => StoryFormSheet.rename(context, initialTitle: '제주'),
      );
      expect(find.text('제주'), findsOneWidget);
      expect(find.textContaining('시작일'), findsNothing);

      await tester.enterText(find.byType(TextField), '제주 한 달');
      await tester.tap(find.widgetWithText(AppButton, '저장'));
      await tester.pumpAndSettle();

      expect(results.single, '제주 한 달');
    });

    testWidgets('allowEmpty 면 비워서 저장할 수 있다(기본 스토리)', (tester) async {
      final results = await pump(
        tester,
        (context) => StoryFormSheet.rename(
          context,
          initialTitle: '하루',
          allowEmpty: true,
        ),
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(enabled(tester, '저장'), isTrue);

      await tester.tap(find.widgetWithText(AppButton, '저장'));
      await tester.pumpAndSettle();

      expect(results.single, '');
    });

    testWidgets('allowEmpty 가 아니면 빈 이름은 저장할 수 없다', (tester) async {
      await pump(
        tester,
        (context) => StoryFormSheet.rename(context, initialTitle: '제주'),
      );
      await tester.enterText(find.byType(TextField), ' ');
      await tester.pump();

      expect(enabled(tester, '저장'), isFalse);
    });
  });
}
