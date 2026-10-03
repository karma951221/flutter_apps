import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/walk/entity/activity_period.dart';
import 'package:walk/domain/walk/entity/daily_activity.dart';
import 'package:walk/domain/walk/entity/period_kind.dart';
import 'package:walk/presentation/walk/widget/activity_bar_chart.dart';

final _period = ActivityPeriod(
  kind: PeriodKind.week,
  start: DateTime(2026, 9, 21),
  end: DateTime(2026, 9, 27),
  today: DateTime(2026, 9, 23),
  days: [
    DailyActivity(date: DateTime(2026, 9, 21), steps: 4000),
    DailyActivity(date: DateTime(2026, 9, 22), steps: 8000),
    DailyActivity(date: DateTime(2026, 9, 23), steps: 2000),
    for (var d = 24; d <= 27; d++) DailyActivity.empty(DateTime(2026, 9, d)),
  ],
);

Future<void> _pump(
  WidgetTester tester, [
  ActivityPeriod? period,
  int goal = 10000,
  bool animate = false,
]) => tester.pumpWidget(
  MediaQuery(
    data: MediaQueryData(disableAnimations: !animate),
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ActivityBarChart(period: period ?? _period, goal: goal),
      ),
    ),
  ),
);

BoxDecoration _decoration(WidgetTester tester, String date) =>
    tester.widget<Container>(find.byKey(Key('walk-bar-$date'))).decoration!
        as BoxDecoration;

void main() {
  testWidgets('요일 7개와 막대를 그리고, 가장 많은 날이 가장 높다', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    for (final label in ['월', '화', '수', '목', '금', '토', '일']) {
      expect(find.text(label), findsOneWidget);
    }
    final high = tester.getSize(find.byKey(const Key('walk-bar-2026-09-22')));
    final low = tester.getSize(find.byKey(const Key('walk-bar-2026-09-21')));
    expect(high.height, greaterThan(low.height));
  });

  testWidgets('오늘 이후 날은 막대가 없다', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('walk-bar-2026-09-24')), findsNothing);
  });

  testWidgets('막대를 누르면 그날 걸음을 보여준다', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('walk-bar-2026-09-22')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('walk-bar-selection')),
        matching: find.textContaining('8,000'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('같은 기간을 새로 읽으면 선택한 날의 새 걸음을 보여준다', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('walk-bar-2026-09-23')));
    await tester.pump();

    final refreshed = _period.copyWith(
      days: [
        for (final day in _period.days)
          day.date == DateTime(2026, 9, 23) ? day.copyWith(steps: 3500) : day,
      ],
    );
    await _pump(tester, refreshed);
    await tester.pump();

    final selection = find.byKey(const Key('walk-bar-selection'));
    expect(
      find.descendant(of: selection, matching: find.textContaining('3,500')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: selection, matching: find.textContaining('2,000')),
      findsNothing,
    );
  });

  testWidgets('목표선이 있고, 높이 기준은 max(최댓값, 목표)', (tester) async {
    final period = _period.copyWith(
      days: [
        for (final day in _period.days)
          day.date == DateTime(2026, 9, 22) ? day.copyWith(steps: 3000) : day,
      ],
    );
    await _pump(tester, period, 8000);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('walk-goal-line')), findsOneWidget);
    expect(find.text('목표'), findsOneWidget);
    final bar = tester.getSize(find.byKey(const Key('walk-bar-2026-09-21')));
    expect(bar.height, closeTo(ActivityBarChart.chartHeight * 0.5, 1));
  });

  testWidgets('최댓값이 목표보다 크면 최댓값이 꽉 찬다', (tester) async {
    await _pump(tester, _period, 4000);
    await tester.pumpAndSettle();

    final bar = tester.getSize(find.byKey(const Key('walk-bar-2026-09-22')));
    expect(bar.height, closeTo(ActivityBarChart.chartHeight, 1));
  });

  testWidgets('달성일은 primary, 미달일은 primaryContainer, 오늘은 테두리', (tester) async {
    await _pump(tester, _period, 4000);
    await tester.pumpAndSettle();
    final scheme = Theme.of(
      tester.element(find.byType(ActivityBarChart)),
    ).colorScheme;

    expect(_decoration(tester, '2026-09-21').color, scheme.primary);
    expect(_decoration(tester, '2026-09-22').color, scheme.primary);
    final today = _decoration(tester, '2026-09-23');
    expect(today.color, scheme.primaryContainer);
    expect((today.border! as Border).top.color, scheme.primary);
    expect((today.border! as Border).top.width, 2);
    expect(_decoration(tester, '2026-09-21').border, isNull);
  });

  testWidgets('선택 줄에 목표 % 가 붙는다', (tester) async {
    final period = _period.copyWith(
      days: [
        for (final day in _period.days)
          day.date == DateTime(2026, 9, 22) ? day.copyWith(steps: 8120) : day,
      ],
    );
    await _pump(tester, period, 10000);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('walk-bar-2026-09-22')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const Key('walk-bar-selection')),
        matching: find.textContaining('8,120 걸음 · 목표 81%'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('막대는 0 에서 자라 끝 높이에 멈춘다', (tester) async {
    await _pump(tester, _period, 8000, true);

    final bar = find.byKey(const Key('walk-bar-2026-09-22'));
    expect(tester.getSize(bar).height, lessThan(1));
    await tester.pump(const Duration(milliseconds: 200));
    final mid = tester.getSize(bar).height;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(ActivityBarChart.chartHeight));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(bar).height,
      closeTo(ActivityBarChart.chartHeight, 1),
    );
  });
}
