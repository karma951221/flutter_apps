import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/presentation/lock/widget/lock_secret_input.dart';
import 'package:walk/presentation/settings/open_settings.dart';
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

  testWidgets('물어보기 설정에 키 섹션 아래 대화 기록 섹션이 있다', (tester) async {
    await open(tester, SettingsTarget.chat);

    final key = find.byKey(const Key('settings-chat-key'));
    final retention = find.byKey(const Key('chat-history-retention'));
    expect(retention, findsOneWidget);
    expect(find.text('대화 기록'), findsOneWidget);
    expect(
      tester.getTopLeft(retention).dy,
      greaterThan(tester.getTopLeft(key).dy),
    );
  });

  testWidgets('물어보기 설정 — 잠겨 있으면 잠금 화면이 먼저', (tester) async {
    await h.lockWithPin();
    await open(tester, SettingsTarget.chat);

    expect(find.byType(LockSecretInput), findsOneWidget);
    expect(find.byKey(const Key('settings-chat-key')), findsNothing);
    expect(find.byKey(const Key('chat-history-retention')), findsNothing);
  });

  group('settingsOpener', () {
    testWidgets('셸 cubit 아래면 그 설정을 여는 콜백을 준다', (tester) async {
      VoidCallback? opener;
      await h.pump(
        tester,
        Builder(
          builder: (context) {
            opener = settingsOpener(context, SettingsTarget.chat);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(opener, isNotNull);
      opener!();
      await tester.pumpAndSettle();
      expect(find.byType(ChatSettingsPage), findsOneWidget);
    });

    testWidgets('셸 cubit 이 없는 자리면 null', (tester) async {
      VoidCallback? opener = () {};
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              opener = settingsOpener(context, SettingsTarget.chat);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(opener, isNull);
    });
  });
}
