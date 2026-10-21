import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/walk/entity/daily_activity.dart';
import 'package:walk/presentation/walk/widget/today_goal_card.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

DailyActivity _activity({int steps = 7240}) =>
    DailyActivity(date: DateTime(2026, 10, 3), steps: steps);

void main() {
  testWidgets('걸음 · 목표 문구와 링 접근성 비율', (tester) async {
    await _pump(tester, TodayGoalCard(activity: _activity(), goal: 10000));

    expect(find.byKey(const Key('walk-today-steps')), findsOneWidget);
    expect(find.text('7,240 걸음'), findsOneWidget);
    expect(find.text('목표 10,000 걸음'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('72%')), findsOneWidget);
    expect(find.text('달성'), findsNothing);
  });

  testWidgets('카드에 "오늘" 제목이 없다 — 위 탭 이름과 겹친다', (tester) async {
    await _pump(tester, TodayGoalCard(activity: _activity(), goal: 10000));

    expect(find.text('오늘'), findsNothing);
  });

  testWidgets('아래 줄은 늘 남은 걸음 — 거리 · 칼로리는 없다', (tester) async {
    await _pump(tester, TodayGoalCard(activity: _activity(), goal: 10000));

    expect(find.text('목표까지 2,760 걸음'), findsOneWidget);
    expect(find.textContaining('km'), findsNothing);
    expect(find.textContaining('kcal'), findsNothing);
  });

  testWidgets('달성이면 배지와 초과 문구', (tester) async {
    await _pump(
      tester,
      TodayGoalCard(activity: _activity(steps: 12500), goal: 10000),
    );

    expect(find.text('달성'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('125%')), findsOneWidget);
    expect(find.text('목표보다 2,500 걸음 더 걸었어요'), findsOneWidget);
  });
}
