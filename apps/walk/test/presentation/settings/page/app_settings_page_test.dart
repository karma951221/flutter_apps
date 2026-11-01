import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/presentation/settings/page/app_settings_page.dart';

import '../settings_harness.dart';

void main() {
  final h = SettingsHarness();

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(h.setUp);
  tearDown(h.tearDown);

  testWidgets('잠금 · 화면 · 기능별 설정 순서', (tester) async {
    await h.pump(tester, const AppSettingsPage());

    double top(Finder f) => tester.getTopLeft(f).dy;
    final lockRow = find.byKey(const Key('settings-diary-lock'));
    expect(top(lockRow), lessThan(top(find.text('화면'))));
    expect(top(find.text('화면')), lessThan(top(find.text('기능별 설정'))));
    expect(
      top(find.text('기능별 설정')),
      lessThan(top(find.byKey(const Key('app-settings-open-diary')))),
    );
    // 잠금 꺼짐 — 열릴 때 일기 설정 cubit 을 읽었다.
    expect(
      find.descendant(of: lockRow, matching: find.text('꺼짐')),
      findsOneWidget,
    );
  });

  testWidgets('바로가기 넷은 일기 · 물어보기 · 알람 · 걷기 순서', (tester) async {
    await h.pump(tester, const AppSettingsPage());

    double top(String name) =>
        tester.getTopLeft(find.byKey(Key('app-settings-open-$name'))).dy;
    expect(top('diary'), lessThan(top('chat')));
    expect(top('chat'), lessThan(top('alarm')));
    expect(top('alarm'), lessThan(top('walk')));
    expect(find.text('일기 설정'), findsOneWidget);
    expect(find.text('물어보기 설정'), findsOneWidget);
    expect(find.text('알람 설정'), findsOneWidget);
    expect(find.text('걷기 설정'), findsOneWidget);
  });

  testWidgets('테마를 고르면 저장한다', (tester) async {
    await h.pump(tester, const AppSettingsPage());

    await tester.tap(find.text('다크'));
    await tester.pumpAndSettle();

    expect(h.theme.state, AppThemeMode.dark);
    verify(
      () => h.settings.save(const AppSettings(themeMode: AppThemeMode.dark)),
    ).called(1);
  });
}
