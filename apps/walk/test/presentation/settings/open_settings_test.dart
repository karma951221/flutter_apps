import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/presentation/lock/widget/lock_secret_input.dart';
import 'package:walk/presentation/settings/open_settings.dart';
import 'package:walk/presentation/settings/page/alarm_settings_page.dart';
import 'package:walk/presentation/settings/page/app_settings_page.dart';
import 'package:walk/presentation/settings/page/chat_settings_page.dart';
import 'package:walk/presentation/settings/page/diary_settings_page.dart';
import 'package:walk/presentation/settings/page/walk_settings_page.dart';
import 'package:walk/presentation/settings/widget/row_highlight.dart';

import 'settings_harness.dart';

void main() {
  final h = SettingsHarness();

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(h.setUp);
  tearDown(h.tearDown);

  /// 셸 탭 자리(cubit 넷 아래)에서 [target] 설정을 연다. [settle] 이 false 면 누르기만 한다.
  Future<void> open(
    WidgetTester tester,
    SettingsTarget target, {
    bool highlight = false,
    bool settle = true,
  }) async {
    await h.pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                openSettings(context, target, highlight: highlight),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    if (settle) await tester.pumpAndSettle();
  }

  const glowKey = Key('row-highlight-glow');

  /// [row] 를 감싼 RowHighlight 의 glow. [row] 가 null 이면 화면의 모든 glow.
  Finder glowOf([Key? row]) => row == null
      ? find.byKey(glowKey, skipOffstage: false)
      : find.descendant(
          of: find.ancestor(
            of: find.byKey(row, skipOffstage: false),
            matching: find.byType(RowHighlight, skipOffstage: false),
          ),
          matching: find.byKey(glowKey, skipOffstage: false),
        );

  /// 3초 동안 잘게 넘기며 본, [finder] 의 glow 각각의 불투명도 최댓값.
  Future<double> peakGlow(WidgetTester tester, Finder finder) async {
    var peak = 0.0;
    void sample() {
      for (final e in finder.evaluate()) {
        final value = (e.widget as FadeTransition).opacity.value;
        if (value > peak) peak = value;
      }
    }

    const step = Duration(milliseconds: 50);
    for (var t = Duration.zero; t < const Duration(seconds: 3); t += step) {
      await tester.pump(step);
      sample();
    }
    return peak;
  }

  const notificationRow = Key('settings-permission-notification');
  const exactAlarmRow = Key('settings-permission-exact-alarm');
  const fullScreenRow = Key('settings-permission-full-screen');

  group('highlight', () {
    testWidgets('chat 을 highlight 로 열면 연결 행이 glow 한다', (tester) async {
      await open(tester, SettingsTarget.chat, highlight: true, settle: false);

      expect(await peakGlow(tester, glowOf()), greaterThan(0));
      expect(
        tester
            .widget<ChatSettingsPage>(find.byType(ChatSettingsPage))
            .highlightConnection,
        isTrue,
      );
    });

    testWidgets('chat 을 highlight 없이 열면 glow 가 없다', (tester) async {
      await open(tester, SettingsTarget.chat, settle: false);

      expect(await peakGlow(tester, glowOf()), 0);
    });

    testWidgets('alarm 을 highlight 로 열면 거부된 첫 권한 행만 glow', (tester) async {
      // 하네스 기본: 알림 허용 · 정확한 알람 거부 · 전체 화면 허용.
      await open(tester, SettingsTarget.alarm, highlight: true, settle: false);

      // 행마다 따로 잰다 — 한 번의 시간 흐름에서 셋을 같이 본다.
      final peaks = <Key, double>{
        notificationRow: 0,
        exactAlarmRow: 0,
        fullScreenRow: 0,
      };
      const step = Duration(milliseconds: 50);
      for (var t = Duration.zero; t < const Duration(seconds: 3); t += step) {
        await tester.pump(step);
        for (final row in peaks.keys.toList()) {
          for (final e in glowOf(row).evaluate()) {
            final value = (e.widget as FadeTransition).opacity.value;
            if (value > peaks[row]!) peaks[row] = value;
          }
        }
      }
      expect(peaks[exactAlarmRow], greaterThan(0));
      expect(peaks[notificationRow], 0);
      expect(peaks[fullScreenRow], 0);
    });

    testWidgets('alarm 을 highlight 없이 열면 거부된 행도 glow 가 없다', (tester) async {
      await open(tester, SettingsTarget.alarm, settle: false);

      expect(await peakGlow(tester, glowOf()), 0);
    });

    testWidgets('alarm 권한이 모두 허용이면 highlight 여도 glow 없음', (tester) async {
      when(
        h.exactAlarm.check,
      ).thenAnswer((_) async => PermissionStatus.granted);
      await open(tester, SettingsTarget.alarm, highlight: true, settle: false);

      expect(await peakGlow(tester, glowOf()), 0);
    });

    for (final (target, page) in [
      (SettingsTarget.walk, WalkSettingsPage),
      (SettingsTarget.app, AppSettingsPage),
      (SettingsTarget.diary, DiarySettingsPage),
    ]) {
      testWidgets('${target.name} 는 highlight 를 무시한다(던지지 않음)', (tester) async {
        await open(tester, target, highlight: true);

        expect(tester.takeException(), isNull);
        expect(find.byType(page), findsOneWidget);
      });
    }
  });

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
