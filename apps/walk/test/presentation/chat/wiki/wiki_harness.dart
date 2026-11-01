import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/repository/wiki_repository.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_history.dart';
import '../../../support/fake_device_auth.dart';
import 'wiki_fakes.dart';

/// 위키 화면 테스트 묶음 — 가짜 저장소들을 getIt 에 올리고, 잠금을 내려 주는 첫 화면에서
/// [open] 으로 위키 화면을 띄운다. 닫힐 때 받은 결과는 [results].
class WikiHarness {
  late MemoryWikiRepository wiki;
  late FakeChatHistorySettings settings;
  late DiaryLockCubit lock;
  late PrefsLockRepository lockRepo;
  late MutableClock clock;
  late EntryOnlyDiary diary;
  final results = <Object?>[];

  Future<void> setUp({
    List<WikiNote> notes = const [],
    List<DiaryEntry> entries = const [],
    Set<String> conversations = const {},
    Map<String, List<ChatTurnRecord>> turns = const {},
    WikiIndexSize size = WikiIndexSize.fallback,
  }) async {
    SharedPreferences.setMockInitialValues({});
    lockRepo = PrefsLockRepository(await SharedPreferences.getInstance());
    clock = MutableClock(DateTime(2026, 11, 2, 9));
    lock = DiaryLockCubit(lockRepo, FakeDeviceAuth(), clock, MediaPickGuard())
      ..start();
    wiki = MemoryWikiRepository(notes);
    settings = FakeChatHistorySettings()..wikiIndexSize = size;
    diary = EntryOnlyDiary(entries);
    getIt
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth())
      ..registerSingleton<WikiRepository>(wiki)
      ..registerSingleton<ChatHistorySettings>(settings)
      ..registerSingleton<ChatSession>(TargetOnlySession(claudeTarget))
      ..registerSingleton<DiaryRepository>(diary)
      ..registerSingleton<ChatHistoryRepository>(
        ExistsOnlyHistory(conversations, turns),
      );
  }

  Future<void> tearDown() async {
    await wiki.close();
    await lock.close();
    await getIt.reset();
  }

  /// 잠금을 켜고 백그라운드에 오래 둔 것처럼 다시 잠근다.
  Future<void> relock(WidgetTester tester) async {
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
    lock.onPaused();
    clock.advance(const Duration(minutes: 5));
    lock.onResumed();
    await tester.pumpAndSettle();
  }

  Future<void> unlock(WidgetTester tester) async {
    await lock.submit('1234');
    await tester.pumpAndSettle();
  }

  /// 첫 화면의 'home' 을 누르면 [open] 이 불린다.
  Future<void> pump(
    WidgetTester tester,
    Future<Object?> Function(BuildContext context) open,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: lock,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => results.add(await open(context)),
                  child: const Text('home'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
  }
}
