import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_pause.dart';
import 'package:walk/presentation/alarm/widget/alarm_menu_sheet.dart';

/// 월 · 금 오전 7:00 출근.
const _alarm = Alarm(id: 1, hour: 7, minute: 0, label: '출근', repeat: {Weekday.mon, Weekday.fri});

void main() {
  // 2026-10-06 화요일 → 다음 회차는 10월 9일 금요일 07:00.
  final now = DateTime(2026, 10, 6, 12);

  Future<List<AlarmMenuAction?>> pump(
    WidgetTester tester,
    Alarm alarm, {
    Locale locale = const Locale('ko'),
    Size size = const Size(800, 1600),
    AlarmPause? pause,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <AlarmMenuAction?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await AlarmMenuSheet.show(context, alarm: alarm, now: now, pause: pause),
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

  /// 시트의 행 제목 순서.
  List<String> rows(WidgetTester tester) => [
    for (final tile in tester.widgetList<AppListTile>(find.byType(AppListTile)))
      (tile.title as Text).data!,
  ];

  testWidgets('켜진 반복 알람은 손잡이 · 알람 · [복제 · 다음 알람 건너뛰기(다음 회차) · 삭제]', (tester) async {
    await pump(tester, _alarm);

    expect(tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle, isTrue);
    expect(find.text('오전 7:00 출근'), findsOneWidget);
    expect(rows(tester), ['복제', '다음 알람 건너뛰기', '삭제']);
    expect(find.text('10월 9일 (금) 오전 7:00'), findsOneWidget);
    expect(find.text('건너뛰기 취소'), findsNothing);
  });

  testWidgets('쉬는 중이면 다음 회차는 기간 뒤 실제로 울릴 첫 회차', (tester) async {
    // 금 10-9 를 쉬므로 다음 울림은 월 10-12 07:00.
    await pump(
      tester,
      _alarm,
      pause: AlarmPause(from: DateTime(2026, 10, 9), until: DateTime(2026, 10, 9)),
    );

    expect(find.text('10월 12일 (월) 오전 7:00'), findsOneWidget);
    expect(find.text('10월 9일 (금) 오전 7:00'), findsNothing);
  });

  testWidgets('한 번 알람 · 꺼진 반복 알람은 건너뛰기 없이 [복제 · 삭제]', (tester) async {
    await pump(tester, const Alarm(id: 2, hour: 8, minute: 0));
    expect(rows(tester), ['복제', '삭제']);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await pump(tester, _alarm.copyWith(enabled: false));
    expect(rows(tester), ['복제', '삭제']);
  });

  testWidgets('건너뛴 알람은 꺼져 있어도 [건너뛰기 취소 · 건너뛴 회차]', (tester) async {
    final results = await pump(
      tester,
      _alarm.copyWith(enabled: false, skippedAt: DateTime(2026, 10, 9, 7)),
    );

    expect(rows(tester), ['복제', '건너뛰기 취소', '삭제']);
    expect(find.text('10월 9일 (금) 오전 7:00'), findsOneWidget);

    await tester.tap(find.text('건너뛰기 취소'));
    await tester.pumpAndSettle();
    expect(results, [AlarmMenuAction.unskip]);
  });

  for (final (label, action) in const [
    ('복제', AlarmMenuAction.duplicate),
    ('다음 알람 건너뛰기', AlarmMenuAction.skip),
    ('삭제', AlarmMenuAction.delete),
  ]) {
    testWidgets('[$label] 을 누르면 $action 으로 닫힌다', (tester) async {
      final results = await pump(tester, _alarm);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(results, [action]);
    });
  }

  testWidgets('삭제 행은 오류 색', (tester) async {
    await pump(tester, _alarm);

    final context = tester.element(find.text('삭제'));
    expect(tester.widget<Text>(find.text('삭제')).style?.color, Theme.of(context).colorScheme.error);
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
