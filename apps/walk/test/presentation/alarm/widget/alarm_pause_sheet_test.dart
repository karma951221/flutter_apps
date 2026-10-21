import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/alarm/entity/alarm_pause.dart';
import 'package:walk/presentation/alarm/widget/alarm_pause_sheet.dart';

void main() {
  // 2026-10-07 수요일.
  final now = DateTime(2026, 10, 7, 12);

  Future<List<AlarmPause?>> pump(WidgetTester tester, {DateTime? at}) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <AlarmPause?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await AlarmPauseSheet.show(context, now: at ?? now),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  List<String> rows(WidgetTester tester) => [
    for (final tile in tester.widgetList<AppListTile>(find.byType(AppListTile)))
      (tile.title as Text).data!,
  ];

  testWidgets('손잡이 · 제목 · 안내 · [오늘만 · 내일까지 · 이번 주말 · 날짜 고르기]와 각 기간', (
    tester,
  ) async {
    await pump(tester);

    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isTrue,
    );
    expect(find.text('알람 쉬기'), findsOneWidget);
    expect(find.text('고른 기간에는 모든 알람이 울리지 않아요. 스위치는 그대로예요.'), findsOneWidget);
    expect(rows(tester), ['오늘만', '내일까지', '이번 주말', '날짜 고르기']);
    expect(find.text('오늘 (수)'), findsOneWidget);
    expect(find.text('오늘 (수) ~ 내일 (목)'), findsOneWidget);
    expect(find.text('10월 10일 (토) ~ 10월 11일 (일)'), findsOneWidget);
  });

  testWidgets('빠른 기간을 고르면 그 기간을 돌려준다', (tester) async {
    final results = await pump(tester);
    await tester.tap(find.text('내일까지'));
    await tester.pumpAndSettle();
    expect(results, [AlarmPause.untilTomorrow(now)]);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이번 주말'));
    await tester.pumpAndSettle();
    expect(results.last, AlarmPause.weekend(now));
  });

  testWidgets('[날짜 고르기] 는 기간 달력을 열고 고른 기간을 돌려준다', (tester) async {
    final results = await pump(tester);
    await tester.tap(find.text('날짜 고르기'));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    await tester.tap(find.text('12').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('14').first);
    await tester.pumpAndSettle();
    expect(find.text('10월 12일'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(results, [
      AlarmPause(from: DateTime(2026, 10, 12), until: DateTime(2026, 10, 14)),
    ]);
  });

  testWidgets('달력을 취소하면 아무것도 돌려주지 않는다', (tester) async {
    final results = await pump(tester);
    await tester.tap(find.text('날짜 고르기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });

  testWidgets('그냥 닫으면 null', (tester) async {
    final results = await pump(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });
}
