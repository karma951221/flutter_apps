import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/repository/chat_usage_repository.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/settings/page/chat_usage_page.dart';
import 'package:walk/presentation/settings/widget/chat_history_settings_section.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_history.dart';
import '../../../support/fake_device_auth.dart';

void main() {
  late FakeChatHistorySettings settings;
  late FakeChatHistoryCount history;
  late DiaryLockCubit lock;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final clock = MutableClock(DateTime(2026, 11, 15));
    settings = FakeChatHistorySettings();
    history = FakeChatHistoryCount(3);
    getIt
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<ChatHistorySettings>(settings)
      ..registerSingleton<ChatHistoryRepository>(history)
      ..registerSingleton<ChatUsageRepository>(FakeChatUsageRepository());
    lock = DiaryLockCubit(
      PrefsLockRepository(prefs),
      FakeDeviceAuth(),
      clock,
      MediaPickGuard(),
    )..start();
  });
  tearDown(() async {
    await lock.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: lock,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(children: const [ChatHistorySettingsSection()]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const retentionRow = Key('chat-history-retention');
  const deleteAllRow = Key('chat-history-delete-all');

  testWidgets('보관 기간 행에 지금 값, 눌러 30일을 고르면 저장된다', (tester) async {
    await pump(tester);

    expect(find.text('대화 기록'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(retentionRow),
        matching: find.text('지우지 않음'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('사용량 기록은 13개월'), findsOneWidget);

    await tester.tap(find.byKey(retentionRow));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30일'));
    await tester.pumpAndSettle();

    expect(settings.retention, ChatRetention.day30);
    expect(
      find.descendant(of: find.byKey(retentionRow), matching: find.text('30일')),
      findsOneWidget,
    );
  });

  testWidgets("대화 모두 지우기는 '대화 n개' 확인 뒤에만, 취소면 그대로", (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(deleteAllRow));
    await tester.pumpAndSettle();
    expect(find.textContaining('대화 3개'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(history.deleteAllCalls, 0);
    expect(history.stored, 3);

    await tester.tap(find.byKey(deleteAllRow));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('모두 지우기'),
      ),
    );
    await tester.pumpAndSettle();

    expect(history.deleteAllCalls, 1);
    expect(history.stored, 0);
    expect(
      tester.widget<AppListTile>(find.byKey(deleteAllRow)).enabled,
      isFalse,
    );
  });

  testWidgets('모두 지우기가 실패하면 오류 스낵바', (tester) async {
    history.failDeleteAll = true;
    await pump(tester);

    await tester.tap(find.byKey(deleteAllRow));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('모두 지우기'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('대화를 지우지 못했어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('대화가 없으면 모두 지우기 행이 꺼진다', (tester) async {
    history.stored = 0;
    await pump(tester);

    expect(
      tester.widget<AppListTile>(find.byKey(deleteAllRow)).enabled,
      isFalse,
    );
    await tester.tap(find.byKey(deleteAllRow));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('사용량 행을 누르면 사용량 화면', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('chat-history-usage')));
    await tester.pumpAndSettle();

    expect(find.byType(ChatUsagePage), findsOneWidget);
  });
}
