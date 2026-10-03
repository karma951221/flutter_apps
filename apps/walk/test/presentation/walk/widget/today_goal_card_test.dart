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

DailyActivity _activity({int steps = 7240, double? distance = 5068}) =>
    DailyActivity(
      date: DateTime(2026, 10, 3),
      steps: steps,
      distanceMeters: distance,
      activeKcal: 212,
    );

final _ring = find.byKey(const Key('walk-goal-ring'));

void main() {
  testWidgets('걸음 · 목표 문구와 링 접근성 비율', (tester) async {
    await _pump(tester, TodayGoalCard(activity: _activity(), goal: 10000));

    expect(find.byKey(const Key('walk-today-steps')), findsOneWidget);
    expect(find.text('7,240 걸음'), findsOneWidget);
    expect(find.text('목표 10,000 걸음'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('72%')), findsOneWidget);
    expect(find.text('달성'), findsNothing);
  });

  testWidgets('거리 · 칼로리 지표를 보여준다', (tester) async {
    await _pump(tester, TodayGoalCard(activity: _activity(), goal: 10000));

    expect(find.text('5.1 km'), findsOneWidget);
    expect(find.text('212 kcal'), findsOneWidget);
  });

  testWidgets('링을 누르면 남은 걸음 · 거리, 다시 누르면 지표로', (tester) async {
    // 7240보 / 5068m → 보폭 0.7m, 남은 2760보 ≈ 1.9km
    await _pump(tester, TodayGoalCard(activity: _activity(), goal: 10000));

    await tester.tap(_ring);
    await tester.pumpAndSettle();
    expect(find.textContaining('목표까지 2,760 걸음'), findsOneWidget);
    expect(find.textContaining('약 1.9'), findsOneWidget);
    expect(find.text('212 kcal'), findsNothing);

    await tester.tap(_ring);
    await tester.pumpAndSettle();
    expect(find.textContaining('목표까지'), findsNothing);
    expect(find.text('212 kcal'), findsOneWidget);
  });

  testWidgets('거리가 없으면 남은 걸음만', (tester) async {
    await _pump(
      tester,
      TodayGoalCard(activity: _activity(distance: null), goal: 10000),
    );

    await tester.tap(_ring);
    await tester.pumpAndSettle();
    expect(find.text('목표까지 2,760 걸음'), findsOneWidget);
    expect(find.textContaining('약'), findsNothing);
  });

  testWidgets('달성이면 배지와 초과 문구', (tester) async {
    await _pump(
      tester,
      TodayGoalCard(activity: _activity(steps: 12500), goal: 10000),
    );

    expect(find.text('달성'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('125%')), findsOneWidget);

    await tester.tap(_ring);
    await tester.pumpAndSettle();
    expect(find.text('목표보다 2,500 걸음 더 걸었어요'), findsOneWidget);
  });

  testWidgets('3초 뒤 지표로 돌아온다', (tester) async {
    await _pump(tester, TodayGoalCard(activity: _activity(), goal: 10000));

    await tester.tap(_ring);
    await tester.pumpAndSettle();
    expect(find.textContaining('목표까지'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.textContaining('목표까지'), findsNothing);
  });
}
