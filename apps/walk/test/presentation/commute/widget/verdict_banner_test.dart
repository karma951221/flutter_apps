import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/commute/entity/catch_verdict.dart';
import 'package:walk/presentation/commute/widget/verdict_banner.dart';

Future<void> _pump(WidgetTester tester, CatchVerdict verdict) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: VerdictBanner(verdict: verdict)),
    ),
  );
}

void main() {
  testWidgets('첫 열차를 탈 수 있으면 걸어가면 탈 수 있어요', (tester) async {
    await _pump(tester, const CatchVerdict.catchFirst());
    expect(find.text('걸어가면 탈 수 있어요'), findsOneWidget);
  });

  testWidgets('둘째 열차 기준이면 다음 열차 기준 문구', (tester) async {
    await _pump(tester, const CatchVerdict.catchSecond());
    expect(find.text('걸어서는 이번 열차를 놓쳐요 — 다음 열차 기준'), findsOneWidget);
  });

  testWidgets('둘 다 놓치면 두 열차 모두 어려워요', (tester) async {
    await _pump(tester, const CatchVerdict.missBoth());
    expect(find.text('걸어서는 두 열차 모두 어려워요'), findsOneWidget);
  });

  testWidgets('판단할 수 없으면 배너를 그리지 않는다', (tester) async {
    await _pump(tester, const CatchVerdict.unknown());
    expect(find.byType(Text), findsNothing);
  });
}
