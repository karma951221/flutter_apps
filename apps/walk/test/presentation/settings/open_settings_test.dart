import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/presentation/lock/widget/lock_secret_input.dart';
import 'package:walk/presentation/settings/open_settings.dart';
import 'package:walk/presentation/settings/page/alarm_settings_page.dart';
import 'package:walk/presentation/settings/page/app_settings_page.dart';

import 'settings_harness.dart';

void main() {
  final h = SettingsHarness();

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(h.setUp);
  tearDown(h.tearDown);

  /// 셸 탭 자리(cubit 넷 아래)에서 [target] 설정을 연다.
  Future<void> open(WidgetTester tester, SettingsTarget target) async {
    await h.pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => openSettings(context, target),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('알람 설정 — 공휴일 · 알람 권한, 걷기 항목 없음', (tester) async {
    await open(tester, SettingsTarget.alarm);

    expect(find.text('알람 설정'), findsOneWidget);
    expect(find.byKey(const Key('settings-holiday-reminder')), findsOneWidget);
    expect(find.byKey(const Key('settings-holiday-source')), findsOneWidget);
    expect(find.text('알림'), findsOneWidget);
    expect(find.text('정확한 알람'), findsOneWidget);
    expect(find.text('전체 화면 알림'), findsOneWidget);
    expect(find.text('Health Connect'), findsNothing);
    expect(find.byKey(const Key('settings-step-goal')), findsNothing);
  });

  testWidgets('걷기 설정 — 걸음 목표 · Health Connect, 공휴일 없음', (tester) async {
    await open(tester, SettingsTarget.walk);

    expect(find.text('걷기 설정'), findsOneWidget);
    expect(find.byKey(const Key('settings-step-goal')), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(find.byKey(const Key('settings-holiday-reminder')), findsNothing);
    expect(find.text('알림'), findsNothing);
  });

  testWidgets('일기 설정 — 풀려 있으면 보관 기간 · 저장 공간', (tester) async {
    await open(tester, SettingsTarget.diary);

    expect(find.text('일기 설정'), findsOneWidget);
    expect(find.byKey(const Key('settings-diary-retention')), findsOneWidget);
    expect(find.byKey(const Key('settings-diary-storage')), findsOneWidget);
    expect(find.byKey(const Key('settings-diary-lock')), findsNothing);
  });

  testWidgets('일기 설정 — 잠겨 있으면 잠금 화면이 먼저', (tester) async {
    await h.lockWithPin();
    await open(tester, SettingsTarget.diary);

    expect(find.byType(LockSecretInput), findsOneWidget);
    expect(find.byKey(const Key('settings-diary-retention')), findsNothing);

    await h.diaryLock.submit('1234');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-diary-retention')), findsOneWidget);
  });

  testWidgets('물어보기 설정 — 풀려 있으면 키 행', (tester) async {
    await open(tester, SettingsTarget.chat);
    expect(find.text('물어보기 설정'), findsOneWidget);
    expect(find.byKey(const Key('settings-chat-key')), findsOneWidget);
  });

  testWidgets('물어보기 설정 — 잠겨 있으면 잠금 화면이 먼저', (tester) async {
    await h.lockWithPin();
    await open(tester, SettingsTarget.chat);

    expect(find.byType(LockSecretInput), findsOneWidget);
    expect(find.byKey(const Key('settings-chat-key')), findsNothing);
  });

  testWidgets('앱 설정 — 잠금 · 테마 · 기능별 설정 바로가기 넷', (tester) async {
    await open(tester, SettingsTarget.app);

    expect(find.text('앱 설정'), findsOneWidget);
    expect(find.byKey(const Key('settings-diary-lock')), findsOneWidget);
    expect(find.byKey(const Key('settings-diary-relock')), findsOneWidget);
    expect(find.text('일기와 물어보기를 함께 잠급니다'), findsOneWidget);
    expect(find.byType(RadioListTile<AppThemeMode>), findsNWidgets(3));
    expect(find.text('시스템 설정'), findsOneWidget);
    expect(find.text('라이트'), findsOneWidget);
    expect(find.text('다크'), findsOneWidget);
    for (final target in SettingsTarget.values.where(
      (t) => t != SettingsTarget.app,
    )) {
      expect(
        find.byKey(Key('app-settings-open-${target.name}')),
        findsOneWidget,
        reason: target.name,
      );
    }
  });

  testWidgets('앱 설정 › 알람 설정, 뒤로가면 앱 설정', (tester) async {
    await open(tester, SettingsTarget.app);

    await tester.tap(find.byKey(const Key('app-settings-open-alarm')));
    await tester.pumpAndSettle();
    expect(find.byType(AlarmSettingsPage), findsOneWidget);
    expect(find.byKey(const Key('settings-holiday-reminder')), findsOneWidget);

    // 한국어 로캘이라 pageBack(툴팁 "Back")을 쓰지 못한다.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(AlarmSettingsPage), findsNothing);
    expect(find.byType(AppSettingsPage), findsOneWidget);
  });

  testWidgets('앱 설정 › 일기 설정은 잠겨 있으면 잠금 화면을 거친다', (tester) async {
    await h.lockWithPin();
    await open(tester, SettingsTarget.app);

    await tester.tap(find.byKey(const Key('app-settings-open-diary')));
    await tester.pumpAndSettle();

    expect(find.byType(LockSecretInput), findsOneWidget);
    expect(find.byKey(const Key('settings-diary-retention')), findsNothing);
  });
}
