import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/alarm/entity/alarm_pause.dart';
import 'package:walk/presentation/alarm/widget/alarm_pause_banner.dart';

void main() {
  // 2026-10-07 수요일.
  final now = DateTime(2026, 10, 7, 12);

  Future<void> pump(WidgetTester tester, AlarmPause pause, {VoidCallback? onStop}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AlarmPauseBanner(pause: pause, now: now, onStop: onStop ?? () {}),
          ),
        ),
      );

  testWidgets('이미 쉬는 중이면 끝 날만', (tester) async {
    await pump(tester, AlarmPause(from: DateTime(2026, 10, 6), until: DateTime(2026, 10, 12)));
    expect(find.text('10월 12일 (월)까지 알람을 쉬어요'), findsOneWidget);
  });

  testWidgets('시작 날이 오늘이면 쉬는 중이다', (tester) async {
    await pump(tester, AlarmPause.untilTomorrow(now));
    expect(find.text('내일 (목)까지 알람을 쉬어요'), findsOneWidget);
  });

  testWidgets('시작 날이 아직이면 시작 · 끝', (tester) async {
    await pump(tester, AlarmPause.weekend(now));
    expect(find.text('10월 10일 (토)부터 10월 11일 (일)까지 알람을 쉬어요'), findsOneWidget);
  });

  testWidgets('[그만 쉬기] 를 누르면 onStop', (tester) async {
    var stopped = 0;
    await pump(tester, AlarmPause.today(now), onStop: () => stopped++);
    await tester.tap(find.text('그만 쉬기'));
    expect(stopped, 1);
  });
}
