import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/presentation/alarm/widget/alarm_skip_sheet.dart';

/// 월 · 금 오전 7:00 출근.
const _alarm = Alarm(id: 1, hour: 7, minute: 0, label: '출근', repeat: {Weekday.mon, Weekday.fri});

void main() {
  // 2026-10-06 화요일 → 다음 회차는 10월 9일 금요일 07:00.
  final now = DateTime(2026, 10, 6, 12);

  Future<List<AlarmSkipAction?>> pump(
    WidgetTester tester,
    Alarm alarm, {
    Locale locale = const Locale('ko'),
    Size size = const Size(800, 1600),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <AlarmSkipAction?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                results.add(await AlarmSkipSheet.show(context, alarm: alarm, now: now)),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('건너뛰지 않았으면 손잡이 · 알람 · [다음 알람 건너뛰기 · 다음 회차]', (tester) async {
    await pump(tester, _alarm);

    expect(tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle, isTrue);
    expect(find.text('오전 7:00 출근'), findsOneWidget);
    expect(find.text('다음 알람 건너뛰기'), findsOneWidget);
    expect(find.text('10월 9일 (금) 오전 7:00'), findsOneWidget);
    expect(find.text('건너뛰기 취소'), findsNothing);
  });

  testWidgets('누르면 skip 으로 닫힌다', (tester) async {
    final results = await pump(tester, _alarm);

    await tester.tap(find.text('다음 알람 건너뛰기'));
    await tester.pumpAndSettle();

    expect(results, [AlarmSkipAction.skip]);
  });

  testWidgets('건너뛴 알람은 [건너뛰기 취소 · 건너뛴 회차], 누르면 unskip', (tester) async {
    final results = await pump(tester, _alarm.copyWith(skippedAt: DateTime(2026, 10, 9, 7)));

    expect(find.text('다음 알람 건너뛰기'), findsNothing);
    expect(find.text('건너뛰기 취소'), findsOneWidget);
    expect(find.text('10월 9일 (금) 오전 7:00'), findsOneWidget);

    await tester.tap(find.text('건너뛰기 취소'));
    await tester.pumpAndSettle();
    expect(results, [AlarmSkipAction.unskip]);
  });

  testWidgets('라벨이 없으면 시각만', (tester) async {
    await pump(tester, _alarm.copyWith(label: ''));

    expect(find.text('오전 7:00'), findsOneWidget);
  });

  testWidgets('그냥 닫으면 null', (tester) async {
    final results = await pump(tester, _alarm);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });

  for (final locale in const [Locale('ko'), Locale('en'), Locale('ja')]) {
    testWidgets('320dp 에서 넘치지 않는다 ($locale)', (tester) async {
      await pump(
        tester,
        _alarm.copyWith(label: '아주 긴 제목이 들어간 출근 알람입니다 정말로 길어요'),
        locale: locale,
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
