import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/entity/activity_period.dart';
import 'package:walk/domain/entity/daily_activity.dart';
import 'package:walk/domain/entity/period_kind.dart';
import 'package:walk/presentation/widget/activity_bar_chart.dart';

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

Future<void> _pump(WidgetTester tester, [ActivityPeriod? period]) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ActivityBarChart(period: period ?? _period)),
      ),
    );

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
}
