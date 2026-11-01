import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_model_catalog.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/secure_window.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/usecase/open_conversation.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/presentation/chat/page/chat_history_page.dart';
import 'package:walk/presentation/chat/page/chat_tab.dart';
import 'package:walk/presentation/diary/viewer/story_viewer_page.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_state.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_secure_window.dart';

class _MockSession extends Mock implements ChatSession {}

class _MockDiary extends Mock implements DiaryRepository {}

class _MockHistory extends Mock implements ChatHistoryRepository {}

class _MockLock extends MockCubit<DiaryLockState> implements DiaryLockCubit {}

const _sonnet = ModelInfo(
  id: 'claude-sonnet-9-5',
  displayName: 'Claude Sonnet 9.5',
);

const _opus = ModelInfo(id: 'claude-opus-9-9', displayName: 'Claude Opus 9.9');

const _storedOk = (ChatVendor.anthropic, ModelListResult.ok([_sonnet]));

void main() {
  setUpAll(() {
    registerFallbackValue(const EntryFilter.all());
    registerFallbackValue(
      const ChatTurnDraft(
        question: '',
        answer: '',
        citedEntryIds: [],
        vendor: ChatVendor.anthropic,
        model: '',
      ),
    );
  });

  late _MockSession session;
  late _MockDiary diary;
  late FakeChatSettings settings;
  late _MockLock lock;
  late StreamController<DiaryLockState> lockStates;
  late FakeChatKeyVerifier verifier;
  late _MockHistory history;
  late FakeSecureWindow secure;
  late FakeChatModelCatalog catalog;

  setUp(() {
    session = _MockSession();
    diary = _MockDiary();
    settings = FakeChatSettings('sk-ant-test')..consented = true;
    lock = _MockLock();
    // 목록이 비어 있으면 탭이 보일 때 받아 온다 — 받을 목록 하나를 둔다.
    verifier = FakeChatKeyVerifier()..stored = _storedOk;
    catalog = FakeChatModelCatalog();
    lockStates = StreamController<DiaryLockState>.broadcast();
    history = _MockHistory();
    secure = FakeSecureWindow();
    when(
      () => history.watchExists(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => history.appendTurn(
        conversationId: any(named: 'conversationId'),
        turn: any(named: 'turn'),
      ),
    ).thenAnswer((_) async => (conversationId: 'c1', seq: 1));
    when(
      () => session.target,
    ).thenReturn((vendor: ChatVendor.anthropic, model: 'claude-test'));
    whenListen(
      lock,
      lockStates.stream,
      initialState: const DiaryLockState.unlocked(),
    );
    getIt
      ..registerSingleton<ChatSession>(session)
      ..registerSingleton<ChatTrace>(const NoopChatTrace())
      ..registerSingleton<ChatSettings>(settings)
      ..registerSingleton<ChatModelCatalog>(catalog)
      ..registerSingleton<ChatModelChoice>(
        ChatModelChoice(settings, catalog, verifier, const Clock()),
      )
      ..registerSingleton<DiaryRepository>(diary)
      ..registerSingleton<ChatHistoryRepository>(history)
      ..registerSingleton<OpenConversation>(OpenConversation())
      ..registerSingleton<SecureWindow>(secure)
      ..registerSingleton<Clock>(MutableClock(diaryT0));
  });

  tearDown(() async {
    await lockStates.close();
    await getIt.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onOpenSettings,
    bool active = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appRouteObserver],
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DiaryLockCubit>.value(
          value: lock,
          child: ChatTab(
            active: active,
            onOpenSettings: onOpenSettings ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 탭 위에 빈 화면을 얹는다(물어보기 설정 자리).
  Future<NavigatorState> pushCover(WidgetTester tester) async {
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const Text('chat settings')),
      ),
    );
    await tester.pumpAndSettle();
    return navigator;
  }

  void answer(String text) {
    when(() => session.ask(any())).thenAnswer(
      (_) => Stream.fromIterable([
        ChatEvent.text(text),
        const ChatEvent.finished(citedEntryIds: []),
      ]),
    );
  }

  testWidgets('예시 질문 칩을 누르면 질문을 보낸다', (tester) async {
    answer('산책을 했어요');
    await pump(tester);

    expect(find.text('지난주에 뭐 먹었지?'), findsOneWidget);
    expect(find.text('요즘 몇 시에 일어나?'), findsOneWidget);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();

    verify(() => session.ask('어제 뭐 했어?')).called(1);
    expect(find.text('산책을 했어요'), findsOneWidget);
  });

  testWidgets('키를 확인하는 동안 가운데에 로딩 표시를 보인다', (tester) async {
    final pending = Completer<String?>();
    getIt
      ..unregister<ChatSettings>()
      ..registerSingleton<ChatSettings>(_PendingSettings(pending.future));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DiaryLockCubit>.value(
          value: lock,
          child: ChatTab(active: true, onOpenSettings: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(Center),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    pending.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('키가 없으면 설정으로 가는 버튼을 보인다', (tester) async {
    settings.key = null;
    var opened = 0;
    await pump(tester, onOpenSettings: () => opened++);

    expect(find.text('설정에서 키를 넣어 주세요'), findsOneWidget);
    await tester.tap(find.text('설정 열기'));
    expect(opened, 1);
  });

  testWidgets('위에 얹힌 화면(물어보기 설정)에서 키를 넣고 돌아오면 키를 다시 읽는다(noKey → ready)', (
    tester,
  ) async {
    settings.key = null;
    await pump(tester);
    expect(find.text('설정에서 키를 넣어 주세요'), findsOneWidget);
    expect(find.text('설정 열기'), findsOneWidget);
    final navigator = await pushCover(tester);

    settings.key = 'sk-ant-new';
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('설정에서 키를 넣어 주세요'), findsNothing);
    expect(find.text('설정 열기'), findsNothing);
    expect(find.text('어제 뭐 했어?'), findsOneWidget);
    // 돌아와서 ready 가 되면 키를 다시 확인한다.
    expect(verifier.fetchStoredCalls, 1);
  });

  testWidgets('탭이 보이지 않을 때 돌아오면 다시 읽지 않고, 보이게 되면 읽는다', (tester) async {
    await pump(tester, active: false);
    final navigator = await pushCover(tester);
    final before = settings.hasApiKeyCalls;

    navigator.pop();
    await tester.pumpAndSettle();

    expect(settings.hasApiKeyCalls, before);

    await pump(tester, active: true);

    expect(settings.hasApiKeyCalls, before + 1);
    expect(verifier.fetchStoredCalls, 1);
  });

  testWidgets('앱 시작에 탭이 보이지 않으면 상태만 읽고 키 확인은 보이게 될 때 한다', (tester) async {
    await pump(tester, active: false);

    expect(settings.hasApiKeyCalls, 1);
    expect(verifier.fetchStoredCalls, 0);

    await pump(tester, active: true);

    expect(verifier.fetchStoredCalls, 1);
  });

  testWidgets('앱 시작에 탭이 보이면 곧바로 키를 확인한다', (tester) async {
    await pump(tester);

    expect(verifier.fetchStoredCalls, 1);
  });

  testWidgets('잘못된 키로 실패하면 말풍선의 [설정 열기]가 onOpenSettings 를 부른다', (tester) async {
    when(() => session.ask(any())).thenAnswer(
      (_) =>
          Stream.fromIterable(const [ChatEvent.failed(ChatFailure.invalidKey)]),
    );
    var opened = 0;
    await pump(tester, onOpenSettings: () => opened++);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();

    expect(find.text('키를 확인해 주세요'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-bubble-open-settings')));
    expect(opened, 1);
  });

  testWidgets('⋮ 는 잠긴 동안 앱 설정만, 풀리면 물어보기 설정 · 앱 설정', (tester) async {
    whenListen(
      lock,
      lockStates.stream,
      initialState: const DiaryLockState.locked(method: LockMethod.pin),
    );
    await pump(tester);
    Finder menu() => find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.more_vert),
    );

    await tester.tap(menu());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
    expect(find.byKey(const Key('menu-settings-chat')), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    lockStates.add(const DiaryLockState.unlocked());
    await tester.pumpAndSettle();
    await tester.tap(menu());
    await tester.pumpAndSettle();

    double top(Finder f) => tester.getTopLeft(f).dy;
    final chat = find.byKey(const Key('menu-settings-chat'));
    expect(chat, findsOneWidget);
    expect(
      top(chat),
      lessThan(top(find.byKey(const Key('menu-settings-app')))),
    );
  });

  testWidgets('동의 전이면 전송 안내와 동의 버튼을 보이고, 동의하면 시작한다', (tester) async {
    settings.consented = false;
    await pump(tester);

    expect(
      find.text(
        '질문에 필요한 일기 · 사진 · 걸음 · 기상 기록이 Anthropic 으로 전송돼요. '
        '키는 이 폰의 보안 저장소에만 있어요.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('동의하고 시작'));
    await tester.pumpAndSettle();

    expect(settings.consented, isTrue);
    expect(find.text('어제 뭐 했어?'), findsOneWidget);
  });

  testWidgets('잠겨 있으면 대화 내용이 트리에 없고, 풀면 그대로 있다', (tester) async {
    answer('산책을 했어요');
    await pump(tester);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();
    expect(find.text('산책을 했어요'), findsOneWidget);

    lockStates.add(const DiaryLockState.locked(method: LockMethod.pin));
    await tester.pumpAndSettle();
    expect(find.text('산책을 했어요', skipOffstage: false), findsNothing);
    expect(find.text('어제 뭐 했어?', skipOffstage: false), findsNothing);

    lockStates.add(const DiaryLockState.unlocked());
    await tester.pumpAndSettle();
    expect(find.text('산책을 했어요'), findsOneWidget);
  });

  testWidgets('실패하면 받은 글 아래에 실패 문구를 보인다', (tester) async {
    when(() => session.ask(any())).thenAnswer(
      (_) => Stream.fromIterable(const [
        ChatEvent.text('반쯤'),
        ChatEvent.failed(ChatFailure.invalidKey),
      ]),
    );
    await pump(tester);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();

    expect(find.text('반쯤'), findsOneWidget);
    expect(find.text('키를 확인해 주세요'), findsOneWidget);
  });

  testWidgets('답하는 중이면 멈춤 버튼이 보이고 전송 버튼이 없다', (tester) async {
    final events = StreamController<ChatEvent>();
    when(() => session.ask(any())).thenAnswer((_) => events.stream);
    await pump(tester);

    await tester.enterText(find.byType(TextField), '지난 주말?');
    await tester.tap(find.byTooltip('보내기'));
    await tester.pump();
    events.add(const ChatEvent.toolStarted('search_diary'));
    await tester.pump();

    expect(find.text('기록을 찾는 중…'), findsOneWidget);
    expect(find.byTooltip('답 멈추기'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsNothing);

    events.add(const ChatEvent.finished(citedEntryIds: []));
    await events.close();
    await tester.pumpAndSettle();
    expect(find.text('기록을 찾는 중…'), findsNothing);
  });

  testWidgets("멈춤을 누르면 부분 답에 '멈춤' 표시가 남고 전송 버튼이 돌아온다", (tester) async {
    final events = StreamController<ChatEvent>();
    when(() => session.ask(any())).thenAnswer((_) => events.stream);
    when(
      () => session.stop(),
    ).thenReturn(const ChatStopResult.kept(text: '산책을 ', citedEntryIds: []));
    await pump(tester);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pump();
    events.add(const ChatEvent.text('산책을 '));
    await tester.pump();

    await tester.tap(find.byTooltip('답 멈추기'));
    await tester.pumpAndSettle();

    verify(() => session.stop()).called(1);
    expect(find.text('산책을 '), findsOneWidget);
    expect(find.text('멈춤'), findsOneWidget);
    expect(find.byTooltip('보내기'), findsOneWidget);
    expect(find.byTooltip('답 멈추기'), findsNothing);
    expect(find.text('멈췄어요'), findsNothing);
    // 멈춤이 구독을 끊었다 — 닫힘은 기다리지 않는다.
    unawaited(events.close());
  });

  testWidgets("글 없이 멈추면 입력칸에 질문이 돌아오고 '멈췄어요' 스낵바가 한 번 뜬다", (tester) async {
    final events = StreamController<ChatEvent>();
    when(() => session.ask(any())).thenAnswer((_) => events.stream);
    when(() => session.stop()).thenReturn(const ChatStopResult.dropped());
    await pump(tester);
    await tester.enterText(find.byType(TextField), '지난 주말?');
    await tester.tap(find.byTooltip('보내기'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );

    await tester.tap(find.byTooltip('답 멈추기'));
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '지난 주말?',
    );
    expect(find.text('멈췄어요'), findsOneWidget);
    // 말풍선 둘이 사라지고 예시 질문으로 돌아간다.
    expect(find.text('어제 뭐 했어?'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('멈췄어요'), findsOneWidget);
    // 멈춤이 구독을 끊었다 — 닫힘은 기다리지 않는다.
    unawaited(events.close());
  });

  testWidgets('새 대화는 대화를 비우고 예시 질문으로 돌아간다', (tester) async {
    answer('산책을 했어요');
    await pump(tester);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('새 대화'));
    await tester.pumpAndSettle();

    verify(() => session.reset()).called(1);
    expect(find.text('산책을 했어요'), findsNothing);
    expect(find.text('지난주에 뭐 먹었지?'), findsOneWidget);
  });

  testWidgets('인용 칩은 날짜와 본문 앞부분을 보이고, 누르면 그 기록부터 뷰어를 연다', (tester) async {
    final entry = DiaryEntry(
      id: 'e1',
      storyId: 's1',
      body: '한강을 따라 오래 걸었다. 바람이 차가웠지만 좋았다.',
      occurredAt: diaryT0,
      createdAt: diaryT0,
      updatedAt: diaryT0,
      media: const [],
      tags: const [],
    );
    when(() => diary.entry('e1')).thenAnswer((_) async => Ok(entry));
    when(
      () => diary.watchEntries(any()),
    ).thenAnswer((_) => Stream.value([entry]));
    when(() => session.ask(any())).thenAnswer(
      (_) => Stream.fromIterable(const [
        ChatEvent.text('한강을 걸었어요'),
        ChatEvent.finished(citedEntryIds: ['e1']),
      ]),
    );
    await pump(tester);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();

    final chip = find.text('10월 10일 · 한강을 따라 오래 걸었다. 바람이 차…');
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    // 조각 타이머가 끝까지 돌면 뷰어가 닫힌다 — 열리는 데까지만 흘린다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final viewer = tester.widget<StoryViewerPage>(find.byType(StoryViewerPage));
    expect(viewer.entryId, 'e1');
    expect(viewer.source, isA<EntriesSource>());
    expect((viewer.source as EntriesSource).entryIds, ['e1']);
    // 뷰어의 조각 타이머가 남지 않게 닫는다.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  Finder menu() => find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.more_vert),
  );

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(menu());
    await tester.pumpAndSettle();
  }

  Future<void> tapMenu(WidgetTester tester, String key) async {
    await openMenu(tester);
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  const banner = Key('chat-temporary-banner');

  /// 말풍선 안쪽 여백을 길게 누른다(글 위는 글 고르기가 받는다).
  Future<void> longPressBubble(WidgetTester tester, String text) async {
    final rect = tester.getRect(find.text(text));
    await tester.longPressAt(rect.topLeft + const Offset(-4, -4));
    await tester.pumpAndSettle();
  }

  group('⋮ 항목', () {
    testWidgets('⋮ 순서는 대화 목록 · 임시 대화로 시작 · 물어보기 설정 · 앱 설정', (tester) async {
      await pump(tester);
      await openMenu(tester);

      final keys = [
        'chat-menu-history',
        'chat-menu-temporary',
        'menu-settings-chat',
        'menu-settings-app',
      ];
      final tops = [
        for (final k in keys) tester.getTopLeft(find.byKey(Key(k))).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(tops.toSet(), hasLength(4));
      expect(find.text('대화 목록'), findsOneWidget);
      expect(find.text('임시 대화로 시작'), findsOneWidget);
    });

    testWidgets('잠긴 동안 ⋮ 에는 앱 설정만', (tester) async {
      whenListen(
        lock,
        lockStates.stream,
        initialState: const DiaryLockState.locked(method: LockMethod.pin),
      );
      await pump(tester);
      await openMenu(tester);

      expect(find.byKey(const Key('menu-settings-app')), findsOneWidget);
      expect(find.byKey(const Key('chat-menu-history')), findsNothing);
      expect(find.byKey(const Key('chat-menu-temporary')), findsNothing);
      expect(find.byKey(const Key('menu-settings-chat')), findsNothing);
    });

    testWidgets('키가 없으면 대화 목록 · 임시 대화로 시작이 없다', (tester) async {
      settings.key = null;
      await pump(tester);
      await openMenu(tester);

      expect(find.byKey(const Key('chat-menu-history')), findsNothing);
      expect(find.byKey(const Key('chat-menu-temporary')), findsNothing);
      expect(find.byKey(const Key('menu-settings-chat')), findsOneWidget);
    });

    testWidgets('동의 전이면 대화 목록 · 임시 대화로 시작이 없다', (tester) async {
      settings.consented = false;
      await pump(tester);
      await openMenu(tester);

      expect(find.byKey(const Key('chat-menu-history')), findsNothing);
      expect(find.byKey(const Key('chat-menu-temporary')), findsNothing);
    });
  });

  group('대화 목록', () {
    final conversation = Conversation(
      id: 'c9',
      title: '지난 주말?',
      titleEdited: false,
      createdAt: diaryT0,
      updatedAt: diaryT0,
      turnCount: 1,
    );

    setUp(() {
      when(
        () => history.conversations(),
      ).thenAnswer((_) => Stream.value([conversation]));
      when(() => history.turns('c9')).thenAnswer(
        (_) async => [
          ChatTurnRecord(
            conversationId: 'c9',
            seq: 1,
            question: '지난 주말?',
            answer: '한강을 걸었어요',
            citedEntryIds: const [],
            stopped: false,
            vendor: ChatVendor.anthropic,
            model: 'claude-test',
            askedAt: diaryT0,
          ),
        ],
      );
    });

    testWidgets('대화 목록에서 행을 고르면 그 대화가 열린다', (tester) async {
      await pump(tester);
      await tapMenu(tester, 'chat-menu-history');
      expect(find.byType(ChatHistoryPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('chat-history-c9')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatHistoryPage), findsNothing);
      expect(find.text('지난 주말?'), findsOneWidget);
      expect(find.text('한강을 걸었어요'), findsOneWidget);
    });

    testWidgets('목록 화면이 떠 있는 중 잠기면 목록이 트리에서 빠진다', (tester) async {
      await pump(tester);
      await tapMenu(tester, 'chat-menu-history');
      expect(find.byType(ChatHistoryPage), findsOneWidget);

      lockStates.add(const DiaryLockState.locked(method: LockMethod.pin));
      await tester.pumpAndSettle();

      expect(find.byType(ChatHistoryPage, skipOffstage: false), findsNothing);
      expect(find.text('지난 주말?', skipOffstage: false), findsNothing);
    });
  });

  testWidgets('임시 대화로 시작하면 배너가 보이고 [새 대화]를 누르면 배너가 사라진다', (tester) async {
    await pump(tester);
    expect(find.byKey(banner), findsNothing);
    expect(find.byTooltip('새 대화'), findsNothing);

    await tapMenu(tester, 'chat-menu-temporary');

    expect(find.byKey(banner), findsOneWidget);
    expect(find.textContaining('Anthropic에 전송되고'), findsOneWidget);
    // 말풍선이 없어도 임시 대화면 [새 대화]로 나갈 수 있다.
    await tester.tap(find.byTooltip('새 대화'));
    await tester.pumpAndSettle();

    expect(find.byKey(banner), findsNothing);
    expect(find.byTooltip('새 대화'), findsNothing);
  });

  testWidgets('저장된 대화를 읽는 동안 입력칸이 꺼진다', (tester) async {
    final turns = Completer<List<ChatTurnRecord>>();
    when(() => history.conversations()).thenAnswer(
      (_) => Stream.value([
        Conversation(
          id: 'c9',
          title: '지난 주말?',
          titleEdited: false,
          createdAt: diaryT0,
          updatedAt: diaryT0,
          turnCount: 1,
        ),
      ]),
    );
    when(() => history.turns('c9')).thenAnswer((_) => turns.future);
    await pump(tester);
    await tapMenu(tester, 'chat-menu-history');
    await tester.tap(find.byKey(const Key('chat-history-c9')));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    turns.complete(const []);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  group('화면 캡처 차단', () {
    testWidgets('임시 대화 + 탭이 보이면 켜고, 안 보이면 · [새 대화] · dispose 면 끈다', (
      tester,
    ) async {
      await pump(tester);
      await tapMenu(tester, 'chat-menu-temporary');
      expect(secure.calls, [true]);

      await pump(tester, active: false);
      expect(secure.calls, [true, false]);

      await pump(tester);
      expect(secure.calls, [true, false, true]);

      await tester.tap(find.byTooltip('새 대화'));
      await tester.pumpAndSettle();
      expect(secure.calls, [true, false, true, false]);

      await tapMenu(tester, 'chat-menu-temporary');
      expect(secure.calls, [true, false, true, false, true]);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(secure.calls, [true, false, true, false, true, false]);
    });

    testWidgets('잠겨 있어도 · 위에 화면이 얹혀도 켠 채 둔다', (tester) async {
      await pump(tester);
      await tapMenu(tester, 'chat-menu-temporary');

      lockStates.add(const DiaryLockState.locked(method: LockMethod.pin));
      await tester.pumpAndSettle();
      final navigator = await pushCover(tester);
      navigator.pop();
      await tester.pumpAndSettle();

      expect(secure.calls, [true]);
    });

    testWidgets('일반 대화에서는 setSecure 를 부르지 않는다', (tester) async {
      answer('산책을 했어요');
      await pump(tester);
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pumpAndSettle();
      await pump(tester, active: false);
      await pump(tester);
      await tester.pumpWidget(const SizedBox.shrink());

      expect(secure.calls, isEmpty);
    });

    testWidgets('임시 대화에서 지난 대화를 열면 끈다', (tester) async {
      when(() => history.conversations()).thenAnswer(
        (_) => Stream.value([
          Conversation(
            id: 'c9',
            title: '지난 주말?',
            titleEdited: false,
            createdAt: diaryT0,
            updatedAt: diaryT0,
            turnCount: 1,
          ),
        ]),
      );
      when(() => history.turns('c9')).thenAnswer(
        (_) async => [
          ChatTurnRecord(
            conversationId: 'c9',
            seq: 1,
            question: '지난 주말?',
            answer: '한강을 걸었어요',
            citedEntryIds: const [],
            stopped: false,
            vendor: ChatVendor.anthropic,
            model: 'claude-test',
            askedAt: diaryT0,
          ),
        ],
      );
      await pump(tester);
      await tapMenu(tester, 'chat-menu-temporary');
      expect(secure.calls, [true]);

      await tapMenu(tester, 'chat-menu-history');
      await tester.tap(find.byKey(const Key('chat-history-c9')));
      await tester.pumpAndSettle();

      expect(find.byKey(banner), findsNothing);
      expect(find.text('한강을 걸었어요'), findsOneWidget);
      expect(secure.calls, [true, false]);
    });

    testWidgets('같은 값을 두 번 보내지 않는다', (tester) async {
      await pump(tester);
      await tapMenu(tester, 'chat-menu-temporary');
      await tapMenu(tester, 'chat-menu-temporary');
      await pump(tester);

      expect(secure.calls, [true]);
    });
  });

  group('턴 지우기', () {
    setUp(() {
      when(() => history.deleteTurn(any(), any())).thenAnswer((_) async {});
      when(() => history.turns(any())).thenAnswer((_) async => const []);
    });

    testWidgets('말풍선을 길게 누르면 시트 → 지우기 → 확인 뒤에만 턴이 사라진다', (tester) async {
      answer('산책을 했어요');
      await pump(tester);
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pumpAndSettle();

      // 취소면 그대로.
      await longPressBubble(tester, '산책을 했어요');
      await tester.tap(find.text('이 질문과 답 지우기'));
      await tester.pumpAndSettle();
      expect(find.text('이 질문과 답을 지울까요?'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.text('산책을 했어요'), findsOneWidget);
      verifyNever(() => history.deleteTurn(any(), any()));

      // 답 말풍선에서 열어도 그 질문의 턴을 지운다.
      await longPressBubble(tester, '산책을 했어요');
      await tester.tap(find.text('이 질문과 답 지우기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      verify(() => history.deleteTurn('c1', 1)).called(1);
      expect(find.text('산책을 했어요'), findsNothing);
      expect(find.text('지난주에 뭐 먹었지?'), findsOneWidget);
    });

    testWidgets('시트를 닫으면 아무것도 지우지 않는다', (tester) async {
      answer('산책을 했어요');
      await pump(tester);
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pumpAndSettle();

      await longPressBubble(tester, '어제 뭐 했어?');
      expect(find.text('이 질문과 답 지우기'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('이 질문과 답 지우기'), findsNothing);
      expect(find.text('이 질문과 답을 지울까요?'), findsNothing);
      expect(find.text('산책을 했어요'), findsOneWidget);
    });

    testWidgets('답하는 중엔 시트가 뜨지 않는다', (tester) async {
      final events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      await pump(tester);
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pump();
      events.add(const ChatEvent.text('산책을 '));
      await tester.pump();

      final rect = tester.getRect(find.text('어제 뭐 했어?'));
      await tester.longPressAt(rect.topLeft + const Offset(-4, -4));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('이 질문과 답 지우기'), findsNothing);

      events.add(const ChatEvent.finished(citedEntryIds: []));
      await events.close();
      await tester.pumpAndSettle();
    });
  });

  group('모델', () {
    const chip = Key('chat-model-chip');

    testWidgets('ready 면 앱바 아래 모델 칩', (tester) async {
      await pump(tester);

      expect(find.byKey(chip), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(chip),
          matching: find.text('Claude Sonnet 9.5'),
        ),
        findsOneWidget,
      );
      // 칩은 앱바 아래, 예시 질문(대화) 위.
      final appBar = tester.getRect(find.byType(AppBar));
      final chipRect = tester.getRect(find.byKey(chip));
      expect(chipRect.top, greaterThanOrEqualTo(appBar.bottom));
      expect(
        chipRect.bottom,
        lessThanOrEqualTo(tester.getRect(find.text('어제 뭐 했어?')).top),
      );
    });

    testWidgets('칩 → 시트 → 다른 모델을 고르면 칩 이름이 바뀐다', (tester) async {
      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.ok([_sonnet, _opus]),
      );
      await pump(tester);

      await tester.tap(find.byKey(chip));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('model-row-${_opus.id}')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(chip),
          matching: find.text('Claude Opus 9.9'),
        ),
        findsOneWidget,
      );
      expect(settings.selectedModel, _opus.id);
    });

    testWidgets('답하는 중엔 칩이 비활성', (tester) async {
      final events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      await pump(tester);

      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pump();

      expect(tester.widget<ActionChip>(find.byKey(chip)).onPressed, isNull);

      events.add(const ChatEvent.finished(citedEntryIds: []));
      await events.close();
      await tester.pumpAndSettle();
      expect(tester.widget<ActionChip>(find.byKey(chip)).onPressed, isNotNull);
    });

    testWidgets("noModels 면 '모델 목록을 받지 못했어요' + [다시 시도]", (tester) async {
      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.unreachable(),
      );
      await pump(tester);

      expect(find.text('모델 목록을 받지 못했어요'), findsOneWidget);
      expect(find.byKey(chip), findsNothing);

      verifier.stored = _storedOk;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(find.text('모델 목록을 받지 못했어요'), findsNothing);
      expect(find.byKey(chip), findsOneWidget);
    });

    testWidgets('잘못된 키면 [설정 열기]', (tester) async {
      verifier.stored = (
        ChatVendor.anthropic,
        const ModelListResult.invalidKey(),
      );
      var opened = 0;
      await pump(tester, onOpenSettings: () => opened++);

      expect(find.text('모델 목록을 받지 못했어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
      await tester.tap(find.text('설정 열기'));
      expect(opened, 1);
    });

    testWidgets('고른 모델이 사라졌으면 탭이 보일 때 스낵바 한 번(보이지 않는 동안은 없음)', (tester) async {
      const notice = '고른 모델이 없어져 추천 모델로 바꿨어요';
      await catalog.replace(ChatVendor.anthropic, [
        _sonnet,
        _opus,
      ], DateTime(2000));
      await settings.selectModel(_opus.id);
      // 보이지 않는 동안 다른 곳(설정 화면 등)이 갱신해 고른 모델이 사라졌다.
      await pump(tester, active: false);
      await getIt<ChatModelChoice>().refresh();
      await tester.pumpAndSettle();
      expect(find.text(notice), findsNothing);

      await pump(tester, active: true);
      expect(find.text(notice), findsOneWidget);

      // 한 번만 — 스낵바가 사라진 뒤 다시 보이게 돼도 없다.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      await pump(tester, active: false);
      await pump(tester, active: true);
      expect(find.text(notice), findsNothing);
    });

    testWidgets('보이는 동안 갱신이 고른 모델을 지우면 곧바로 스낵바 한 번', (tester) async {
      const notice = '고른 모델이 없어져 추천 모델로 바꿨어요';
      await catalog.replace(ChatVendor.anthropic, [
        _sonnet,
        _opus,
      ], DateTime(2000));
      await settings.selectModel(_opus.id);

      await pump(tester);

      expect(find.text(notice), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(chip),
          matching: find.text('Claude Sonnet 9.5'),
        ),
        findsOneWidget,
      );
    });
  });
}

class _PendingSettings extends FakeChatSettings {
  _PendingSettings(this.pending) : super('sk-ant-test');

  final Future<String?> pending;

  @override
  Future<bool> hasApiKey() async => await pending != null;
}
