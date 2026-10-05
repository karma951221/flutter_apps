import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';
import 'package:pawlog/presentation/tracking/widget/active_walk_banner.dart';

import '../../../support/fakes.dart';
import '../../../support/pump_app.dart';

double _dotOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(PulseDot),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

void main() {
  testWidgets('추적 중 배너는 남색 바탕에 연두 점과 경과 시간을 보인다', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: ActiveWalkBanner.tracking(
          session: walkSession(distanceMeters: 300),
          elapsed: const Duration(minutes: 12, seconds: 5),
          onTap: () {},
        ),
      ),
      disableAnimations: true,
    );

    final banner = tester.widget<Material>(
      find.byKey(const Key('walk-feed-banner')),
    );
    expect(banner.color, PawlogColors.light.primary);
    expect(banner.borderRadius, PawlogRadius.controlAll);
    expect(find.byType(PulseDot), findsOneWidget);
    expect(find.text('12:05'), findsOneWidget);
  });

  testWidgets('저장 전 배너에는 연두 점 · 시간이 없다', (tester) async {
    await pumpApp(
      tester,
      Scaffold(body: ActiveWalkBanner.unsaved(onTap: () {})),
    );

    expect(find.byType(PulseDot), findsNothing);
    expect(find.byKey(const Key('walk-feed-banner-elapsed')), findsNothing);
  });

  testWidgets('연두 점은 1.6초 주기로 점멸한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PawlogTheme.light(),
        home: Center(child: PulseDot(color: PawlogColors.light.accent)),
      ),
    );

    expect(_dotOpacity(tester), 1);
    await tester.pump(PawlogMotion.pulse ~/ 2);
    expect(_dotOpacity(tester), lessThan(0.5));
    await tester.pump(PawlogMotion.pulse ~/ 2);
    expect(_dotOpacity(tester), closeTo(1, 0.01));
  });

  testWidgets('애니메이션 줄이기면 점은 멈춘 채 꽉 차 있다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PawlogTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Center(child: PulseDot(color: PawlogColors.light.accent)),
        ),
      ),
    );

    await tester.pump(PawlogMotion.pulse ~/ 2);
    expect(_dotOpacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
