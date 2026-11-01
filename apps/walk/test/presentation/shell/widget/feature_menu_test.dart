import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/settings/open_settings.dart';
import 'package:walk/presentation/settings/page/alarm_settings_page.dart';
import 'package:walk/presentation/shell/widget/feature_menu.dart';

import '../../settings/settings_harness.dart';

void main() {
  final h = SettingsHarness();

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> open(WidgetTester tester, FeatureMenu menu) async {
    await h.pump(tester, Scaffold(appBar: AppBar(actions: [menu])));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
  }

  /// 열린 메뉴 행의 key 를 위에서부터.
  List<Key?> menuKeys(WidgetTester tester) => [
    for (final item in tester.widgetList<PopupMenuItem<Object?>>(
      find.byWidgetPredicate((w) => w is PopupMenuItem),
    ))
      item.key,
  ];

  testWidgets('항목 순서는 화면별 항목 → 기능 설정 → 앱 설정', (tester) async {
    await open(
      tester,
      FeatureMenu(
        settings: SettingsTarget.diary,
        entries: [
          FeatureMenuEntry(key: const Key('menu-a'), label: 'A', onTap: () {}),
          FeatureMenuEntry(key: const Key('menu-b'), label: 'B', onTap: () {}),
        ],
      ),
    );

    expect(menuKeys(tester), const [
      Key('menu-a'),
      Key('menu-b'),
      Key('menu-settings-diary'),
      Key('menu-settings-app'),
    ]);
    expect(find.text('일기 설정'), findsOneWidget);
    expect(find.text('앱 설정'), findsOneWidget);
  });

  testWidgets('showFeatureSettings 가 false 면 앱 설정 하나만', (tester) async {
    await open(
      tester,
      FeatureMenu(
        settings: SettingsTarget.diary,
        showFeatureSettings: false,
        entries: [FeatureMenuEntry(label: 'A', onTap: () {})],
      ),
    );

    expect(menuKeys(tester), const [Key('menu-settings-app')]);
  });

  testWidgets('화면별 항목을 누르면 그 onTap', (tester) async {
    var tapped = 0;
    await open(
      tester,
      FeatureMenu(
        settings: SettingsTarget.walk,
        entries: [FeatureMenuEntry(label: 'A', onTap: () => tapped++)],
      ),
    );

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
  });

  testWidgets('알람 설정을 누르면 알람 설정 화면을 연다', (tester) async {
    await open(tester, const FeatureMenu(settings: SettingsTarget.alarm));

    await tester.tap(find.byKey(const Key('menu-settings-alarm')));
    await tester.pumpAndSettle();

    expect(find.byType(AlarmSettingsPage), findsOneWidget);
  });
}
