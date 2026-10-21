import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    final bar = tester.getRect(find.byKey(const Key('walk-bar-2026-09-21')));
    expect(bar.height, closeTo(ActivityBarChart.chartHeight * 0.5, 1));
    // 목표 == 기준 → 목표선은 차트 맨 위(바닥에서 chartHeight).
    final line = tester.getRect(find.byKey(const Key('walk-goal-line')));
    expect(
      line.center.dy,
      closeTo(bar.bottom - ActivityBarChart.chartHeight, 1),
    );
  });

  testWidgets('최댓값이 목표보다 크되 1.5배 이하면 최댓값이 꽉 찬다', (tester) async {
    await _pump(tester, _period, 6000);
    await tester.pumpAndSettle();

    final bar = tester.getSize(find.byKey(const Key('walk-bar-2026-09-22')));
    expect(bar.height, closeTo(ActivityBarChart.chartHeight, 1));
    // 목표 6000 / 기준 8000 → 바닥에서 chartHeight × 0.75.
    final line = tester.getRect(find.byKey(const Key('walk-goal-line')));
    expect(
      tester.getRect(find.byKey(const Key('walk-bar-2026-09-22'))).bottom -
          line.center.dy,
      closeTo(ActivityBarChart.chartHeight * 0.75, 1),
    );
    expect(find.byKey(const Key('walk-bar-break-2026-09-22')), findsNothing);
  });

  testWidgets('목표의 1.5배를 넘는 날은 그 높이에서 잘리고 물결선이 붙는다', (tester) async {
    // 8000 = 목표 4000 의 2배 → 기준은 6000(1.5배), 8000 막대는 꽉 차고 물결선.
    await _pump(tester, _period, 4000);
    await tester.pumpAndSettle();

    final tall = tester.getRect(find.byKey(const Key('walk-bar-2026-09-22')));
    expect(tall.height, closeTo(ActivityBarChart.chartHeight, 1));
    expect(find.byKey(const Key('walk-bar-break-2026-09-22')), findsOneWidget);
    expect(find.byKey(const Key('walk-bar-break-2026-09-21')), findsNothing);
    // 목표선은 바닥에서 chartHeight × 4000/6000, 4000 막대 꼭대기와 같다.
    final line = tester.getRect(find.byKey(const Key('walk-goal-line')));
    final atGoal = tester.getRect(find.byKey(const Key('walk-bar-2026-09-21')));
    expect(atGoal.top, closeTo(line.center.dy, 1));
    expect(
      tall.bottom - line.center.dy,
      closeTo(ActivityBarChart.chartHeight * 2 / 3, 1),
    );
  });

  testWidgets('잘린 막대를 눌러도 실제 걸음 수를 보여준다', (tester) async {
    await _pump(tester, _period, 4000);
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

  testWidgets('오늘이 목표를 채우면 테두리는 onPrimaryContainer', (tester) async {
    await _pump(tester, _period, 2000);
    await tester.pumpAndSettle();
    final scheme = Theme.of(
      tester.element(find.byType(ActivityBarChart)),
    ).colorScheme;

    final today = _decoration(tester, '2026-09-23');
    expect(today.color, scheme.primary);
    expect((today.border! as Border).top.color, scheme.onPrimaryContainer);
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

  group('목표 라벨은 막대를 가리지 않는다', () {
    // 일요일까지 모두 지난 주 — 마지막 막대가 목표선을 지난다.
    final full = ActivityPeriod(
      kind: PeriodKind.week,
      start: DateTime(2026, 9, 21),
      end: DateTime(2026, 9, 27),
      today: DateTime(2026, 9, 27),
      days: [
        for (var d = 21; d <= 27; d++)
          DailyActivity(date: DateTime(2026, 9, d), steps: 12000),
      ],
    );
    final month = ActivityPeriod(
      kind: PeriodKind.month,
      start: DateTime(2026, 9),
      end: DateTime(2026, 9, 30),
      today: DateTime(2026, 9, 30),
      days: [
        for (var d = 1; d <= 30; d++)
          DailyActivity(date: DateTime(2026, 9, d), steps: 12000),
      ],
    );
    final label = find.byKey(const Key('walk-goal-label'));

    Future<void> narrow(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    testWidgets('주간 마지막 막대와 라벨이 겹치지 않는다', (tester) async {
      await narrow(tester);
      await _pump(tester, full, 10000);
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byKey(const Key('walk-bar-2026-09-27')));
      // 라벨은 막대 오른쪽 칸에만 — 맞닿는 것까지는 괜찮다(부동소수 오차 허용).
      expect(bar.right, lessThanOrEqualTo(tester.getRect(label).left + 0.01));
    });

    testWidgets('월간 마지막 막대와 라벨이 겹치지 않는다', (tester) async {
      await narrow(tester);
      await _pump(tester, month, 10000);
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byKey(const Key('walk-bar-2026-09-30')));
      // 라벨은 막대 오른쪽 칸에만 — 맞닿는 것까지는 괜찮다(부동소수 오차 허용).
      expect(bar.right, lessThanOrEqualTo(tester.getRect(label).left + 0.01));
    });

    testWidgets('좁은 폭 월간에서 두 자리 날짜도 한 줄이다', (tester) async {
      await narrow(tester);
      await _pump(tester, month, 10000);
      await tester.pumpAndSettle();

      final one = tester.getSize(find.text('5')).height;
      for (final day in ['10', '15', '20', '25', '30']) {
        expect(tester.getSize(find.text(day)).height, one, reason: day);
      }
    });

    testWidgets('날짜 라벨은 막대 가운데 아래에 있다', (tester) async {
      await narrow(tester);
      await _pump(tester, full, 10000);
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byKey(const Key('walk-bar-2026-09-21')));
      // 글자 자체의 가로 가운데 — Text 상자가 칸을 꽉 채우고 왼쪽 정렬이면 여기서 드러난다.
      final paragraph = tester.renderObject<RenderParagraph>(find.text('월'));
      final glyphs = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 1),
      );
      final left = paragraph.localToGlobal(Offset(glyphs.first.left, 0)).dx;
      final right = paragraph.localToGlobal(Offset(glyphs.first.right, 0)).dx;
      expect((left + right) / 2, closeTo(bar.center.dx, 1));
    });

    testWidgets('목표 높이에서 마지막 막대를 눌러도 선택된다', (tester) async {
      await narrow(tester);
      await _pump(tester, full, 10000);
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byKey(const Key('walk-bar-2026-09-27')));
      final line = tester.getRect(find.byKey(const Key('walk-goal-line')));
      await tester.tapAt(Offset(bar.center.dx, line.center.dy));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('walk-bar-selection')),
          matching: find.textContaining('27일'),
        ),
        findsOneWidget,
      );
    });
  });
}
