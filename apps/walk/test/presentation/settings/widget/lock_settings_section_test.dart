import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/lock/page/lock_setup_page.dart';
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
}
