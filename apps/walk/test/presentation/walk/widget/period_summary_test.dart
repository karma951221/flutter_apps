import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/walk/entity/activity_period.dart';
import 'package:walk/domain/walk/entity/daily_activity.dart';
import 'package:walk/domain/walk/entity/period_kind.dart';
import 'package:walk/presentation/walk/widget/period_summary.dart';

/// 2026-09-21(월) ~ 27(일) 주간. 월 12000 · 화 3000 · 수 10000 · 목~일 0.
ActivityPeriod _week(DateTime today) => ActivityPeriod(
  kind: PeriodKind.week,
  start: DateTime(2026, 9, 21),
  end: DateTime(2026, 9, 27),
  today: today,
  days: [
    DailyActivity(date: DateTime(2026, 9, 21), steps: 12000),
    DailyActivity(date: DateTime(2026, 9, 22), steps: 3000),
    DailyActivity(date: DateTime(2026, 9, 23), steps: 10000),
    for (var d = 24; d <= 27; d++) DailyActivity.empty(DateTime(2026, 9, d)),
  ],
);

Future<void> _pump(WidgetTester tester, ActivityPeriod period) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: PeriodSummary(period: period, goal: 10000)),
    ),
  );
  await tester.pumpAndSettle();
}

final _goalDays = find.byKey(const Key('walk-goal-days'));

void main() {
  testWidgets('달성 n/m일 — 오늘 이후는 세지 않는다', (tester) async {
    await _pump(tester, _week(DateTime(2026, 9, 23)));

    expect(tester.widget<Text>(_goalDays).data, '달성 2/3일');
  });

  testWidgets('지난 기간은 모든 날을 센다', (tester) async {
    await _pump(tester, _week(DateTime(2026, 10, 3)));

    expect(tester.widget<Text>(_goalDays).data, '달성 2/7일');
  });

  testWidgets('합계 · 일평균 두 타일만 — 거리 · 칼로리는 없다', (tester) async {
    await _pump(tester, _week(DateTime(2026, 9, 23)));

    for (final label in ['합계', '일평균']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('25,000 걸음'), findsOneWidget);
    expect(find.text('8,333 걸음'), findsOneWidget);
    for (final icon in [Icons.directions_walk, Icons.calendar_today]) {
      expect(find.byIcon(icon), findsOneWidget);
    }
    expect(find.text('거리'), findsNothing);
    expect(find.text('활동 칼로리'), findsNothing);
    expect(find.byIcon(Icons.straighten), findsNothing);
    expect(find.byIcon(Icons.local_fire_department), findsNothing);
  });
}
