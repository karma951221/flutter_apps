import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_state.dart';
import 'package:walk/presentation/lock/page/lock_setup_page.dart';
import 'package:walk/presentation/lock/widget/pattern_lock.dart';
import 'package:walk/presentation/settings/cubit/diary_settings_cubit.dart';
import 'package:walk/presentation/settings/widget/lock_settings_section.dart';

import '../settings_harness.dart';

void main() {
  final h = SettingsHarness();

  setUpAll(SettingsHarness.registerFallbacks);
  setUp(h.setUp);
  tearDown(h.tearDown);

  Future<void> pump(WidgetTester tester) async {
    await h.pump(
      tester,
      Builder(
        builder: (context) {
          context.read<DiarySettingsCubit>().load();
          return const Scaffold(body: LockSettingsSection());
        },
      ),
    );
  }

  Finder inRow(String key, String text) =>
      find.descendant(of: find.byKey(Key(key)), matching: find.text(text));

  testWidgets('잠금 · 다시 잠기는 시간 행과 설명', (tester) async {
    await pump(tester);

    expect(inRow('settings-diary-lock', '잠금'), findsOneWidget);
    expect(inRow('settings-diary-lock', '꺼짐'), findsOneWidget);
    expect(find.text('다시 잠기는 시간'), findsOneWidget);
    expect(find.text('일기와 물어보기를 함께 잠급니다'), findsOneWidget);
  });

  testWidgets('잠긴 동안 다시 잠기는 시간은 열리지 않고, 잠금 행은 열린다', (tester) async {
    await h.lockWithPin();
    await pump(tester);
    expect(inRow('settings-diary-lock', 'PIN 4자리'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-diary-relock')));
    await tester.pumpAndSettle();
    expect(find.text('5분 뒤'), findsNothing);

    await tester.tap(find.byKey(const Key('settings-diary-lock')));
    await tester.pumpAndSettle();
    expect(find.byType(LockSetupPage), findsOneWidget);
  });

  testWidgets('풀린 동안 다시 잠기는 시간을 고르면 저장한다', (tester) async {
    await h.lockWithPin();
    await h.diaryLock.submit('1234');
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-diary-relock')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5분 뒤').last);
    await tester.pumpAndSettle();

    expect(inRow('settings-diary-relock', '5분 뒤'), findsOneWidget);
  });

  testWidgets('다시 잠기는 시간: 시트가 열린 사이 방식이 바뀌어도 최신 설정에 저장하고 풀린 채 둔다', (
    tester,
  ) async {
    await h.lockWithPin();
    await h.diaryLock.submit('1234');
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-diary-relock')));
    await tester.pumpAndSettle();
    for (final label in ['바로', '30초 뒤', '1분 뒤', '5분 뒤']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    // 시트가 열린 사이 잠금 방식이 패턴으로 바뀌었다 — 오래된 설정으로 덮어쓰면 안 된다.
    await h.lockRepo.setSecret(LockMethod.pattern, '0-1-2-5');
    await h.lockRepo.saveConfig(
      const LockConfig(enabled: true, method: LockMethod.pattern),
    );
    await tester.tap(find.text('5분 뒤').last);
    await tester.pumpAndSettle();

    expect(
      h.lockRepo.loadConfig(),
      const LockConfig(
        enabled: true,
        method: LockMethod.pattern,
        relockDelay: RelockDelay.minutes5,
      ),
    );
    // 풀린 채 그대로다(다음 백그라운드 복귀에서 새 시간으로 잠긴다).
    expect(h.diaryLock.state, isA<LockUnlocked>());
  });

  testWidgets('잠금이 꺼져 있으면 다시 잠기는 시간 행은 눌러도 열리지 않는다', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-diary-relock')));
    await tester.pumpAndSettle();

    expect(find.text('5분 뒤'), findsNothing);
  });

  testWidgets('잠금 행은 켜진 방식을 보인다(패턴)', (tester) async {
    await h.lockRepo.setSecret(LockMethod.pattern, '0-1-2-5');
    await h.lockRepo.saveConfig(
      const LockConfig(enabled: true, method: LockMethod.pattern),
    );
    await pump(tester);

    expect(inRow('settings-diary-lock', '패턴'), findsOneWidget);
  });

  testWidgets('잠금이 꺼져 있어도 잠금 행을 누르면 LockSetupPage', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-diary-lock')));
    await tester.pumpAndSettle();

    expect(find.byType(LockSetupPage), findsOneWidget);
  });

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final d in pin.split('')) {
      await tester.tap(find.widgetWithText(TextButton, d));
      await tester.pump();
    }
    await tester.pump();
    await tester.pump();
  }

  testWidgets('PIN → 패턴으로 바꾸면 일기 잠금 상태와 행이 새 방식을 따른다', (tester) async {
    await h.lockWithPin();
    await pump(tester);
    expect((h.diaryLock.state as LockLocked).method, LockMethod.pin);

    await tester.tap(find.byKey(const Key('settings-diary-lock')));
    await tester.pumpAndSettle();
    await typePin(tester, '1234');
    await tester.tap(find.text('패턴'));
    await tester.pump();
    tester.widget<PatternLock>(find.byType(PatternLock)).onCompleted([
      0, 1, 2, 5, //
    ]);
    await tester.pump();
    tester.widget<PatternLock>(find.byType(PatternLock)).onCompleted([
      0, 1, 2, 5, //
    ]);
    await tester.pumpAndSettle();

    expect(find.byType(LockSetupPage), findsNothing);
    expect(h.lockRepo.loadConfig().method, LockMethod.pattern);
    expect((h.diaryLock.state as LockLocked).method, LockMethod.pattern);
    expect(inRow('settings-diary-lock', '패턴'), findsOneWidget);
  });

  testWidgets('잠금을 끄면 일기가 풀리고 행은 꺼짐', (tester) async {
    await h.lockWithPin();
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-diary-lock')));
    await tester.pumpAndSettle();
    await typePin(tester, '1234');
    await tester.tap(find.text('잠금 끄기'));
    await tester.pumpAndSettle();

    expect(h.diaryLock.state, isA<LockUnlocked>());
    expect(inRow('settings-diary-lock', '꺼짐'), findsOneWidget);
  });

  testWidgets('잠금 설정 화면을 그냥 닫으면 잠금 상태를 건드리지 않는다', (tester) async {
    await h.lockWithPin();
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-diary-lock')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(LockSetupPage))).pop();
    await tester.pumpAndSettle();

    expect(h.diaryLock.state, isA<LockLocked>());
  });
}
