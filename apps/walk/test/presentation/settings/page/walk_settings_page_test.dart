import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/presentation/settings/page/walk_settings_page.dart';

import '../settings_harness.dart';

void main() {
  final h = SettingsHarness();

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(h.setUp);
  tearDown(h.tearDown);

  testWidgets('걸음 목표와 Health Connect 상태를 보인다', (tester) async {
    await h.pump(tester, const WalkSettingsPage());

    expect(find.text('하루 목표'), findsOneWidget);
    expect(find.text('10,000 걸음'), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.text('설치 필요 ›'), findsOneWidget);
  });

  testWidgets('걸음 목표를 바꾸면 행이 바뀐다', (tester) async {
    await h.pump(tester, const WalkSettingsPage());

    await tester.tap(find.byKey(const Key('settings-step-goal')));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byKey(const Key('step-goal-slider'))).onChanged!(
      8000,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('step-goal-save')));
    await tester.pumpAndSettle();

    expect(h.goal.state, 8000);
    expect(find.text('8,000 걸음'), findsOneWidget);
  });

  testWidgets('Health Connect 행: 설치가 필요하면 설치 화면을 연다', (tester) async {
    when(h.walk.openInstall).thenAnswer((_) async {});
    await h.pump(tester, const WalkSettingsPage());

    await tester.tap(find.text('Health Connect'));
    await tester.pumpAndSettle();

    verify(h.walk.openInstall).called(1);
  });
}
