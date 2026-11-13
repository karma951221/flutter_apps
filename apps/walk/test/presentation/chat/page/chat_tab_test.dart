import 'package:walk/domain/chat/attachment/attachment_rules.dart';
import 'package:walk/domain/chat/attachment/chat_attachment.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:walk/domain/chat/attachment/attachment_loader.dart';
import 'package:walk/domain/chat/workspace/workspace.dart';
import '../../../support/unused_chat_attachments.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_connection.dart';
import 'package:walk/domain/chat/chat_history_settings.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_model_catalog.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/repository/wiki_repository.dart';
import 'package:walk/domain/chat/secure_window.dart';
import 'package:walk/domain/chat/tool/tool_summary.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/usecase/open_conversation.dart';
import 'package:walk/domain/chat/usecase/wiki_distiller.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/presentation/chat/attachment/chat_file_picker.dart';
import 'package:walk/presentation/chat/page/chat_history_page.dart';
import 'package:walk/presentation/chat/page/chat_tab.dart';
import 'package:walk/presentation/chat/widget/chat_bubble_view.dart';
import 'package:walk/presentation/chat/widget/chat_input.dart';
import 'package:walk/presentation/chat/widget/chat_jump_to_latest.dart';
import 'package:walk/presentation/chat/widget/chat_progress_view.dart';
import 'package:walk/presentation/chat/wiki/page/wiki_note_edit_page.dart';
import 'package:walk/presentation/chat/wiki/page/wiki_page.dart';
import 'package:walk/presentation/chat/workspace/page/workspace_file_view_page.dart';
import 'package:walk/presentation/chat/workspace/page/workspace_page.dart';
import 'package:walk/presentation/diary/viewer/story_viewer_page.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_state.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_history.dart';
import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_secure_window.dart';
import '../../../support/fake_wiki_repository.dart';
import '../wiki/wiki_fakes.dart';
import '../workspace/workspace_fakes.dart';

class _MockSession extends Mock implements ChatSession {}

class _MockDiary extends Mock implements DiaryRepository {}

class _MockHistory extends Mock implements ChatHistoryRepository {}

class _MockLock extends MockCubit<DiaryLockState> implements DiaryLockCubit {}

class _MockDistiller extends Mock implements WikiDistiller {}

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
  late MemoryWikiRepository wiki;
  late _MockDistiller distiller;

  setUp(() {
    wiki = MemoryWikiRepository();
    distiller = _MockDistiller();
    session = _MockSession();
    when(() => session.attachmentRoom).thenReturn((
      images: 12,
      docs: 5,
      docBytes: AttachmentRules.maxDocBytesPerConversation,
    ));
    diary = _MockDiary();
    settings = FakeChatSettings('sk-ant-test')
      ..consentedVendor = ChatVendor.anthropic;
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
      ..registerSingleton<Workspace>(const UnusedWorkspace())
      ..registerSingleton<AttachmentLoader>(const UnusedAttachmentLoader())
      ..registerSingleton<ChatFilePicker>(const NoopChatFilePicker())
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
      ..registerSingleton<WikiRepository>(wiki)
      ..registerSingleton<WikiDistiller>(distiller)
      ..registerSingleton<ChatHistorySettings>(FakeChatHistorySettings())
      ..registerSingleton<Clock>(MutableClock(diaryT0));
  });

  tearDown(() async {
    await wiki.close();
    await lockStates.close();
    await getIt.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onOpenSettings,
    bool active = true,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appRouteObserver],
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
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

  testWidgets('[내 기록 참고] 칩이 모델 칩 옆에 켜진 채 보이고, 누르면 꺼지며 저장된다', (tester) async {
    await pump(tester);

    const key = Key('chat-use-records-chip');
    expect(find.byKey(key), findsOneWidget);
    expect(find.text('내 기록 참고'), findsOneWidget);
    expect(tester.widget<FilterChip>(find.byKey(key)).selected, isTrue);

    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();

    expect(tester.widget<FilterChip>(find.byKey(key)).selected, isFalse);
    expect(
      (getIt<ChatHistorySettings>() as FakeChatHistorySettings).useRecords,
      isFalse,
    );

    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(find.byKey(key)).selected, isTrue);
  });

  testWidgets('저장된 선택이 꺼짐이면 꺼진 칩으로 시작한다', (tester) async {
    (getIt<ChatHistorySettings>() as FakeChatHistorySettings).useRecords =
        false;
    await pump(tester);

    expect(
      tester
          .widget<FilterChip>(find.byKey(const Key('chat-use-records-chip')))
          .selected,
      isFalse,
    );
  });

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
    settings.consentedVendor = null;
    await pump(tester);

    expect(
      find.text(
        '질문과, 답에 필요한 일기 · 사진 · 걸음 · 기상 기록이 연결한 AI(Claude)로 전송돼요. '
        '키는 이 폰의 보안 저장소에만 있어요. '
        '정리해 둔 위키의 제목 · 요약도 질문마다 함께 보내져요.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('동의하고 시작'));
    await tester.pumpAndSettle();

    expect(settings.consentedVendor, ChatVendor.anthropic);
    expect(find.text('어제 뭐 했어?'), findsOneWidget);
  });

  testWidgets('벤더를 바꾸고 돌아오면 동의 화면, 동의하면 이전 말풍선이 그대로 보인다', (tester) async {
    answer('산책을 했어요');
    await pump(tester);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();
    expect(find.text('산책을 했어요'), findsOneWidget);
    final navigator = await pushCover(tester);

    // 설정에서 GPT 로 바꿨다.
    const gpt = ModelInfo(id: 'gpt-9', displayName: 'GPT-9');
    await settings.connect(
      ChatVendor.openai,
      'sk-proj-new',
      ChatKeyStatus.valid,
    );
    await catalog.replace(ChatVendor.openai, [gpt], DateTime.now());
    when(
      () => session.target,
    ).thenReturn((vendor: ChatVendor.openai, model: gpt.id));
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('동의하고 시작'), findsOneWidget);
    expect(find.textContaining('연결한 AI(GPT)로 전송돼요'), findsOneWidget);
    expect(find.textContaining('지금 대화의 이전 내용도 GPT 로 보내져요.'), findsOneWidget);
    expect(find.text('산책을 했어요'), findsNothing);

    await tester.tap(find.text('동의하고 시작'));
    await tester.pumpAndSettle();

    expect(settings.consentedVendor, ChatVendor.openai);
    expect(find.text('동의하고 시작'), findsNothing);
    expect(find.text('어제 뭐 했어?'), findsOneWidget);
    expect(find.text('산책을 했어요'), findsOneWidget);
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
    events.add(const ChatEvent.toolStarted(callId: 't1', name: 'search_diary'));
    await tester.pump();

    expect(find.byTooltip('답 멈추기'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsNothing);

    events.add(const ChatEvent.finished(citedEntryIds: []));
    await events.close();
    await tester.pumpAndSettle();
    expect(find.byTooltip('보내기'), findsOneWidget);
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
    testWidgets('⋮ 순서는 대화 목록 · 위키 · 작업 폴더 · 임시 대화로 시작 · 물어보기 설정 · 앱 설정', (
      tester,
    ) async {
      await pump(tester);
      await openMenu(tester);

      final keys = [
        'chat-menu-history',
        'chat-menu-wiki',
        'chat-menu-workspace',
        'chat-menu-temporary',
        'menu-settings-chat',
        'menu-settings-app',
      ];
      final tops = [
        for (final k in keys) tester.getTopLeft(find.byKey(Key(k))).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(tops.toSet(), hasLength(6));
      expect(find.text('작업 폴더'), findsOneWidget);
      expect(find.text('대화 목록'), findsOneWidget);
      expect(find.text('위키'), findsOneWidget);
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
      expect(find.byKey(const Key('chat-menu-wiki')), findsNothing);
      expect(find.byKey(const Key('menu-settings-chat')), findsNothing);
    });

    testWidgets('키가 없으면 대화 목록 · 임시 대화로 시작이 없다', (tester) async {
      settings.key = null;
      await pump(tester);
      await openMenu(tester);

      expect(find.byKey(const Key('chat-menu-history')), findsNothing);
      expect(find.byKey(const Key('chat-menu-temporary')), findsNothing);
      expect(find.byKey(const Key('chat-menu-wiki')), findsNothing);
      expect(find.byKey(const Key('menu-settings-chat')), findsOneWidget);
    });

    testWidgets('동의 전이면 대화 목록 · 임시 대화로 시작이 없다', (tester) async {
      settings.consentedVendor = null;
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

  group('위키', () {
    setUp(() {
      when(() => history.turns(any())).thenAnswer((_) async => const []);
    });

    testWidgets('[위키] → 위키 화면, [대화 보기]로 끝나면 그 대화가 열린다', (tester) async {
      wiki.stored = [
        wikiNote(5, title: '수면 패턴').copyWith(sourceConversationId: 'c9'),
      ];
      when(
        () => history.watchExists('c9'),
      ).thenAnswer((_) => Stream.value(true));
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

      await tapMenu(tester, 'chat-menu-wiki');
      expect(find.byType(WikiPage), findsOneWidget);
      await tester.tap(find.byKey(const Key('wiki-note-5')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('대화 보기'));
      await tester.pumpAndSettle();

      expect(find.byType(WikiPage), findsNothing);
      expect(find.text('지난 주말?'), findsOneWidget);
      expect(find.text('한강을 걸었어요'), findsOneWidget);
    });

    testWidgets('[위키]에서 그냥 돌아오면 대화는 그대로', (tester) async {
      answer('산책을 했어요');
      await pump(tester);
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pumpAndSettle();

      await tapMenu(tester, 'chat-menu-wiki');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('산책을 했어요'), findsOneWidget);
      verifyNever(() => history.turns(any()));
    });

    testWidgets('답 말풍선 길게 누르기 → [위키에 추가] → 답 글이 채워진 편집 화면', (tester) async {
      answer('평일엔 7시에 일어나요.\n주말엔 늦어요.');
      await pump(tester);
      await tester.tap(find.text('요즘 몇 시에 일어나?'));
      await tester.pumpAndSettle();

      await longPressBubble(tester, '평일엔 7시에 일어나요.\n주말엔 늦어요.');
      await tester.tap(find.text('위키에 추가'));
      await tester.pumpAndSettle();

      expect(find.byType(WikiNoteEditPage), findsOneWidget);
      String text(String key) =>
          tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
      expect(text('wiki-edit-title'), '요즘 몇 시에 일어나?');
      expect(text('wiki-edit-summary'), '평일엔 7시에 일어나요.');
      expect(text('wiki-edit-body'), '평일엔 7시에 일어나요.\n주말엔 늦어요.');
      // 요청은 없다 — 질문은 한 번만.
      verify(() => session.ask(any())).called(1);

      await tester.tap(find.byKey(const Key('wiki-edit-save')));
      await tester.pumpAndSettle();
      expect(find.byType(WikiNoteEditPage), findsNothing);
      expect(wiki.created.single.sourceConversationId, 'c1');
    });

    testWidgets('질문 말풍선이면 본문은 질문', (tester) async {
      answer('산책을 했어요');
      await pump(tester);
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pumpAndSettle();

      await longPressBubble(tester, '어제 뭐 했어?');
      await tester.tap(find.text('위키에 추가'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('wiki-edit-body')))
            .controller!
            .text,
        '어제 뭐 했어?',
      );
    });

    testWidgets('임시 대화에선 시트에 [위키에 추가]가 없다', (tester) async {
      answer('산책을 했어요');
      await pump(tester);
      await tapMenu(tester, 'chat-menu-temporary');
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pumpAndSettle();

      await longPressBubble(tester, '산책을 했어요');
      expect(find.text('이 질문과 답 지우기'), findsOneWidget);
      expect(find.text('위키에 추가'), findsNothing);
    });

    testWidgets('실패 말풍선엔 [위키에 추가]가 없다', (tester) async {
      when(() => session.ask(any())).thenAnswer(
        (_) => Stream.fromIterable(const [
          ChatEvent.text('반쯤'),
          ChatEvent.failed(ChatFailure.network),
        ]),
      );
      await pump(tester);
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pumpAndSettle();

      await longPressBubble(tester, '반쯤');
      expect(find.text('이 질문과 답 지우기'), findsOneWidget);
      expect(find.text('위키에 추가'), findsNothing);
    });
  });

  group('위키로 정리', () {
    const distill = Key('chat-menu-distill');
    const candidate = WikiCandidate.create(
      title: '기상 시간',
      summary: '평일 7시',
      body: '평일엔 7시에 일어난다',
    );

    setUp(() {
      when(() => history.turns(any())).thenAnswer((_) async => const []);
      when(
        () => distiller.distill(
          conversationId: any(named: 'conversationId'),
          target: any(named: 'target'),
        ),
      ).thenAnswer(
        (_) async => const WikiDistillResult.candidates([candidate]),
      );
    });

    /// 질문 하나를 보내 답을 받는다 — 대화가 저장돼 c1 이 열린다.
    Future<void> saved(WidgetTester tester) async {
      answer('산책을 했어요');
      await pump(tester);
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pumpAndSettle();
    }

    testWidgets('저장된 대화가 열려 있으면 ⋮ 에 [위키로 정리]가 [위키]와 [임시 대화로 시작] 사이에', (
      tester,
    ) async {
      await saved(tester);
      await openMenu(tester);

      final keys = [
        'chat-menu-history',
        'chat-menu-wiki',
        'chat-menu-distill',
        'chat-menu-temporary',
      ];
      final tops = [
        for (final k in keys) tester.getTopLeft(find.byKey(Key(k))).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(tops.toSet(), hasLength(4));
      expect(find.text('위키로 정리'), findsOneWidget);
      // 누르기 전에는 위키가 생기지 않는다 — 답이 끝나도 정리 요청 · 저장이 없다.
      verifyNever(
        () => distiller.distill(
          conversationId: any(named: 'conversationId'),
          target: any(named: 'target'),
        ),
      );
      expect(wiki.created, isEmpty);
      expect(wiki.updated, isEmpty);
    });

    testWidgets('빈 대화면 없다', (tester) async {
      await pump(tester);
      await openMenu(tester);
      expect(find.byKey(const Key('chat-menu-wiki')), findsOneWidget);
      expect(find.byKey(distill), findsNothing);
    });

    testWidgets('임시 대화면 없다', (tester) async {
      answer('산책을 했어요');
      await pump(tester);
      await tapMenu(tester, 'chat-menu-temporary');
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pumpAndSettle();

      await openMenu(tester);
      expect(find.byKey(distill), findsNothing);
    });

    testWidgets('답하는 중이면 없다', (tester) async {
      await saved(tester);
      final pending = StreamController<ChatEvent>();
      addTearDown(pending.close);
      when(() => session.ask(any())).thenAnswer((_) => pending.stream);
      await tester.enterText(find.byType(TextField), '또?');
      await tester.tap(find.byTooltip('보내기'));
      await tester.pump();
      expect(find.byTooltip('답 멈추기'), findsOneWidget);

      await tester.tap(menu());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('chat-menu-wiki')), findsOneWidget);
      expect(find.byKey(distill), findsNothing);
    });

    testWidgets('키가 없으면 없다', (tester) async {
      await saved(tester);
      settings.key = null;
      final navigator = await pushCover(tester);
      navigator.pop();
      await tester.pumpAndSettle();

      await openMenu(tester);
      expect(find.byKey(const Key('menu-settings-chat')), findsOneWidget);
      expect(find.byKey(distill), findsNothing);
    });

    testWidgets('누르면 후보 시트', (tester) async {
      await saved(tester);
      await tapMenu(tester, 'chat-menu-distill');

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byKey(const Key('wiki-candidate-0')), findsOneWidget);
      expect(find.text('기상 시간'), findsOneWidget);
      verify(
        () => distiller.distill(
          conversationId: 'c1',
          target: (vendor: ChatVendor.anthropic, model: 'claude-test'),
        ),
      ).called(1);
      expect(wiki.created, isEmpty);
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

  group('진행 줄 · 다시 그리기 · [↓ 새 답]', () {
    late StreamController<ChatEvent> events;
    MutableClock clock() => getIt<Clock>() as MutableClock;

    setUp(() {
      events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
    });

    tearDown(() async {
      ChatTabDebug.reset();
      unawaited(events.close());
    });

    /// 질문을 보내고 한 프레임. 진행 줄의 스피너가 돌아 pumpAndSettle 은 쓰지 않는다.
    Future<void> ask(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), '지난 주말?');
      await tester.tap(find.byTooltip('보내기'));
      await tester.pump();
    }

    /// 경과 초를 [seconds] 만큼 올린다(시계 + 1초 타이머).
    Future<void> elapse(WidgetTester tester, int seconds) async {
      for (var i = 0; i < seconds; i++) {
        clock().advance(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }
    }

    Future<void> finish(WidgetTester tester) async {
      events.add(const ChatEvent.finished(citedEntryIds: []));
      await tester.pumpAndSettle();
    }

    Finder inProgress(Finder f) =>
        find.descendant(of: find.byType(ChatProgressView), matching: f);

    testWidgets("입력칸 위 옛 '기록을 찾는 중…' 줄이 없다", (tester) async {
      await pump(tester);
      await ask(tester);
      events.add(
        const ChatEvent.toolStarted(callId: 't1', name: 'search_diary'),
      );
      await tester.pump();

      expect(find.text('기록을 찾는 중…'), findsNothing);
      await finish(tester);
    });

    testWidgets("보내면 답 말풍선 위에 '보내는 중'이 보인다", (tester) async {
      await pump(tester);
      await ask(tester);

      final line = inProgress(find.text('보내는 중'));
      expect(line, findsOneWidget);
      // 답 말풍선(아직 글 없는 '…') 안쪽 — 그 위에 있고, 입력칸에 붙은 줄이 아니다.
      expect(
        find.descendant(of: find.byType(ChatBubbleView), matching: line),
        findsOneWidget,
      );
      final answer = find.text('…');
      expect(
        tester.getTopLeft(line).dy,
        lessThan(tester.getTopLeft(answer).dy),
      );
      expect(
        tester.getBottomLeft(answer).dy,
        lessThan(tester.getTopLeft(find.byType(ChatInput)).dy),
      );
      await finish(tester);
    });

    testWidgets("도구 단계에서 '일기 찾는 중(…)', 결과에서 '일기 5개 찾음'", (tester) async {
      await pump(tester);
      await ask(tester);
      events.add(
        const ChatEvent.toolStarted(
          callId: 't1',
          name: 'search_diary',
          input: ToolInputSummary(kind: ChatToolKind.searchDiary, query: '산책'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(inProgress(find.text("일기 찾는 중('산책')")), findsOneWidget);

      events.add(
        const ChatEvent.toolFinished(
          callId: 't1',
          name: 'search_diary',
          summary: ToolSummary(kind: ChatToolKind.searchDiary, count: 5),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(inProgress(find.text('일기 5개 찾음')), findsOneWidget);
      await finish(tester);
    });

    testWidgets('3초 넘게 끝나면 접힌 요약 한 줄이 남고, 2초면 없다', (tester) async {
      await pump(tester);
      await ask(tester);
      await elapse(tester, 3);
      events.add(const ChatEvent.text('산책을 했어요'));
      await finish(tester);

      expect(inProgress(find.text('3초')), findsOneWidget);
      expect(inProgress(find.text('▸')), findsOneWidget);

      await tester.tap(find.byTooltip('새 대화'));
      await tester.pumpAndSettle();
      events = StreamController<ChatEvent>();
      await ask(tester);
      await elapse(tester, 2);
      events.add(const ChatEvent.text('걸었어요'));
      await finish(tester);

      expect(find.text('걸었어요'), findsOneWidget);
      expect(find.byType(ChatProgressView), findsNothing);
    });

    testWidgets("멈추면 진행 줄이 '멈춤'으로, 부분 답에 '멈춤' 표시", (tester) async {
      when(
        () => session.stop(),
      ).thenReturn(const ChatStopResult.kept(text: '산책을 ', citedEntryIds: []));
      await pump(tester);
      await ask(tester);
      events.add(const ChatEvent.text('산책을 '));
      await tester.pump();

      await tester.tap(find.byTooltip('답 멈추기'));
      await tester.pumpAndSettle();

      expect(
        inProgress(find.byIcon(Icons.stop_circle_outlined)),
        findsOneWidget,
      );
      expect(inProgress(find.textContaining('멈춤')), findsOneWidget);
      // 말풍선 안쪽 표시(진행 줄 바깥).
      expect(find.text('멈춤'), findsOneWidget);
    });

    /// 긴 답을 받아 목록을 스크롤할 수 있게 한다.
    Future<void> longAnswer(WidgetTester tester) async {
      events.add(ChatEvent.text(List.filled(60, '산책했어요').join('\n')));
      await tester.pump(const Duration(milliseconds: 100));
    }

    /// 말풍선 목록의 스크롤 위치(말풍선 글도 안에 Scrollable 이 있어 목록 컨트롤러로 찾는다).
    ScrollPosition list(WidgetTester tester) =>
        tester.widget<ListView>(find.byType(ListView)).controller!.position;

    testWidgets('위로 스크롤한 채 답이 자라면 [↓ 새 답]이 뜨고, 누르면 맨 아래로 가며 사라진다', (
      tester,
    ) async {
      await pump(tester);
      await ask(tester);
      await longAnswer(tester);
      expect(find.byType(ChatJumpToLatest), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pump(const Duration(milliseconds: 100));
      final position = list(tester);
      expect(position.pixels, greaterThan(position.viewportDimension / 4));
      // 자라기 전에는 뜨지 않는다.
      expect(find.byType(ChatJumpToLatest), findsNothing);

      events.add(const ChatEvent.text('\n더 걸었어요'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ChatJumpToLatest), findsOneWidget);
      expect(find.text('↓ 새 답'), findsOneWidget);

      await tester.tap(find.byType(ChatJumpToLatest));
      await tester.pump();
      // 애니메이션으로 내려간다 — 한 프레임에 바로 가지 않는다.
      expect(list(tester).pixels, greaterThan(0));
      await tester.pump(AppMotion.medium);
      await tester.pump();
      expect(list(tester).pixels, 0);
      expect(find.byType(ChatJumpToLatest), findsNothing);
      await finish(tester);
    });

    testWidgets('맨 아래에 있으면 뜨지 않는다', (tester) async {
      await pump(tester);
      await ask(tester);
      await longAnswer(tester);
      events.add(const ChatEvent.text('\n더 걸었어요'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(list(tester).pixels, 0);
      expect(find.byType(ChatJumpToLatest), findsNothing);
      await finish(tester);
    });

    testWidgets('답이 끝나면 [↓ 새 답]이 사라진다', (tester) async {
      await pump(tester);
      await ask(tester);
      await longAnswer(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pump(const Duration(milliseconds: 100));
      events.add(const ChatEvent.text('\n더 걸었어요'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ChatJumpToLatest), findsOneWidget);

      await finish(tester);
      expect(find.byType(ChatJumpToLatest), findsNothing);
    });

    testWidgets('줄이기 모드면 [↓ 새 답]이 바로 jumpTo', (tester) async {
      await pump(tester, reduceMotion: true);
      await ask(tester);
      await longAnswer(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pump(const Duration(milliseconds: 100));
      events.add(const ChatEvent.text('\n더 걸었어요'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(ChatJumpToLatest));
      await tester.pump();
      expect(list(tester).pixels, 0);
      expect(find.byType(ChatJumpToLatest), findsNothing);
      await finish(tester);
    });

    /// 한 프레임. 글은 0초 타이머로 모아 그리므로 시간을 조금 흘린다.
    Future<void> frame(WidgetTester tester) =>
        tester.pump(const Duration(milliseconds: 16));

    /// [text] 를 품은 말풍선 안의 진행 줄에서 [f] 를 찾는다.
    Finder progressIn(String text, Finder f) => find.descendant(
      of: find.ancestor(
        of: find.text(text),
        matching: find.byType(ChatBubbleView),
      ),
      matching: inProgress(f),
    );

    testWidgets('펼친 요약은 새 답이 붙어도 제 말풍선에 남고, 새 요약은 접혀 있다', (tester) async {
      await pump(tester);
      await ask(tester);
      await elapse(tester, 3);
      events.add(const ChatEvent.text('첫 답'));
      await finish(tester);
      await tester.tap(progressIn('첫 답', find.text('▸')));
      await tester.pumpAndSettle();
      expect(progressIn('첫 답', find.text('▾')), findsOneWidget);

      events = StreamController<ChatEvent>();
      await ask(tester);
      await elapse(tester, 3);
      events.add(const ChatEvent.text('둘째 답'));
      await finish(tester);

      expect(progressIn('둘째 답', find.text('▸')), findsOneWidget);
      expect(progressIn('둘째 답', find.text('▾')), findsNothing);
      expect(progressIn('첫 답', find.text('▾')), findsOneWidget);
    });

    testWidgets('글 뒤에 도구를 부르는 동안엔 커서가 없고, 다시 쓰면 돌아온다', (tester) async {
      final cursor = find.textContaining('▍', findRichText: true);
      await pump(tester);
      await ask(tester);
      events
        ..add(const ChatEvent.phase(ChatPhase.writing))
        ..add(const ChatEvent.text('먼저 '));
      await frame(tester);
      expect(cursor, findsOneWidget);

      events.add(
        const ChatEvent.toolStarted(callId: 't1', name: 'search_diary'),
      );
      await frame(tester);
      expect(cursor, findsNothing);

      events
        ..add(const ChatEvent.roundStarted(2))
        ..add(const ChatEvent.phase(ChatPhase.writing))
        ..add(const ChatEvent.text('이어서'));
      await frame(tester);
      expect(cursor, findsOneWidget);
      await finish(tester);
    });

    group('읽던 자리', () {
      /// 짧은 첫 턴을 끝내고, 둘째 질문의 답을 [lines] 줄 받는다(아직 답하는 중).
      Future<void> twoTurns(WidgetTester tester, {int lines = 20}) async {
        await pump(tester);
        await ask(tester);
        events.add(const ChatEvent.text('첫 답'));
        await finish(tester);
        events = StreamController<ChatEvent>();
        await ask(tester);
        events
          ..add(const ChatEvent.phase(ChatPhase.writing))
          ..add(ChatEvent.text(List.filled(lines, '산책했어요').join('\n')));
        await tester.pump(const Duration(milliseconds: 100));
      }

      /// 첫 답 말풍선이 보이도록 위로 올린다(¼ 화면 넘게). 끝까지 당기면 늘어나는 오버스크롤
      /// 효과가 말풍선을 움직이므로 맨 위 조금 아래까지만 끈다.
      Future<void> scrollUp(WidgetTester tester) async {
        final max = list(tester).maxScrollExtent;
        // 멈춘 뒤 떼서 튕기지 않는다(fling 없음).
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(ListView)),
        );
        await gesture.moveBy(const Offset(0, kTouchSlop + 1));
        await gesture.moveBy(Offset(0, max - 20));
        await tester.pump(const Duration(milliseconds: 300));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 500));
        final position = list(tester);
        expect(position.pixels, greaterThan(position.viewportDimension / 4));
        expect(position.pixels, lessThan(position.maxScrollExtent));
        expect(find.text('첫 답').hitTestable(), findsOneWidget);
      }

      double top(WidgetTester tester) => tester.getTopLeft(find.text('첫 답')).dy;

      testWidgets('위로 올려 둔 채 글 · 진행 줄이 자라고 요약으로 접혀도 앞 말풍선이 움직이지 않는다', (
        tester,
      ) async {
        await twoTurns(tester);
        await scrollUp(tester);
        final before = top(tester);
        final pixels = list(tester).pixels;

        events.add(const ChatEvent.text('\n더 걸었어요\n또 걸었어요'));
        await frame(tester);
        expect(top(tester), moreOrLessEquals(before, epsilon: 0.5));
        expect(list(tester).pixels, greaterThan(pixels));

        // 진행 줄이 바뀐다(노트 → 도구, 문구가 페이드로 바뀌는 동안).
        events.add(
          ChatEvent.progress(List.filled(30, '지난주 일기를 볼게요').join(' ')),
        );
        await frame(tester);
        expect(top(tester), moreOrLessEquals(before, epsilon: 0.5));
        events.add(
          const ChatEvent.toolStarted(callId: 't1', name: 'search_diary'),
        );
        await frame(tester);
        expect(top(tester), moreOrLessEquals(before, epsilon: 0.5));
        await elapse(tester, 3);
        expect(top(tester), moreOrLessEquals(before, epsilon: 0.5));

        // 3초 넘게 끝나 진행 줄이 접힌 요약으로 바뀐다(높이가 바뀌는 애니메이션 프레임마다).
        final running = list(tester).pixels;
        events.add(const ChatEvent.finished(citedEntryIds: []));
        await frame(tester);
        expect(top(tester), moreOrLessEquals(before, epsilon: 0.5));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          expect(
            top(tester),
            moreOrLessEquals(before, epsilon: 0.5),
            reason: 'frame $i',
          );
        }
        await tester.pumpAndSettle();
        expect(inProgress(find.text('▸')), findsOneWidget);
        expect(top(tester), moreOrLessEquals(before, epsilon: 0.5));
        // 요약 줄 높이만큼 위치를 옮겨 지켰다(옮길 게 없던 게 아니다).
        expect(list(tester).pixels, isNot(moreOrLessEquals(running)));
      });

      testWidgets('맨 아래(offset 0)에 있으면 목록이 따라 내려간다', (tester) async {
        await twoTurns(tester, lines: 5);
        expect(list(tester).pixels, 0);
        final before = top(tester);

        events.add(const ChatEvent.text('\n더 걸었어요\n또 걸었어요'));
        await frame(tester);

        expect(list(tester).pixels, 0);
        expect(top(tester), lessThan(before - 1));
        await finish(tester);
      });

      testWidgets('맨 아래로 다시 내리면 [↓ 새 답]이 사라지고, 그 뒤엔 목록이 따라 내려간다', (
        tester,
      ) async {
        await twoTurns(tester);
        await scrollUp(tester);
        events.add(const ChatEvent.text('\n더 걸었어요'));
        await frame(tester);
        expect(find.byType(ChatJumpToLatest), findsOneWidget);

        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pump(const Duration(seconds: 1));
        expect(list(tester).pixels, 0);
        expect(find.byType(ChatJumpToLatest), findsNothing);

        events.add(const ChatEvent.text('\n마지막'));
        await frame(tester);
        expect(list(tester).pixels, 0);
        await finish(tester);
      });
    });

    testWidgets('경과 초가 올라도 사용자 말풍선과 입력칸은 다시 그리지 않는다', (tester) async {
      await pump(tester);
      await ask(tester);
      events.add(const ChatEvent.text('산책을 '));
      await tester.pump();
      ChatTabDebug.reset();

      await elapse(tester, 4);

      expect(inProgress(find.text('4초')), findsOneWidget);
      // 질문(0번)은 그대로, 답(1번)만 다시 그린다.
      expect(ChatTabDebug.bubbleBuilds[0] ?? 0, 0);
      expect(ChatTabDebug.bubbleBuilds[1], greaterThan(0));
      expect(ChatTabDebug.inputBuilds, 0);
      await finish(tester);
    });
  });

  group('작업 폴더', () {
    late MemoryWorkspace ws;
    late _RecordingLoader loader;

    setUp(() {
      ws = MemoryWorkspace();
      loader = _RecordingLoader();
      getIt
        ..unregister<Workspace>()
        ..registerSingleton<Workspace>(ws)
        ..unregister<AttachmentLoader>()
        ..registerSingleton<AttachmentLoader>(loader);
    });

    testWidgets('⋮ [작업 폴더] → [물어보기에 첨부] 면 상대 경로를 단 채 입력칸에 담긴다', (tester) async {
      final file = workspaceFile('out/20261113-1405-a.md');
      ws.add(file, Uint8List.fromList(utf8.encode('답')));
      await pump(tester);

      await tapMenu(tester, 'chat-menu-workspace');
      expect(find.byType(WorkspacePage), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(Key('workspace-file-${file.path}')),
          matching: find.byIcon(Icons.more_vert),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('물어보기에 첨부'));
      await tester.pumpAndSettle();

      expect(find.byType(WorkspacePage), findsNothing);
      expect(loader.loaded, hasLength(1));
      expect(loader.loaded.single.path, '/ws/${file.path}');
      expect(loader.loaded.single.workspacePath, file.path);
      expect(loader.loaded.single.name, file.name);
      expect(find.text(file.name), findsOneWidget);
    });

    testWidgets('[물어보기에 첨부] 한 파일의 경로를 못 구하면 담지 않고 알린다', (tester) async {
      final file = workspaceFile('inbox/20261113-100000-b.md');
      ws
        ..add(file, Uint8List.fromList(utf8.encode('글')))
        ..failAbsolute = true;
      await pump(tester);

      await tapMenu(tester, 'chat-menu-workspace');
      await tester.tap(
        find.descendant(
          of: find.byKey(Key('workspace-file-${file.path}')),
          matching: find.byIcon(Icons.more_vert),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('물어보기에 첨부'));
      await tester.pumpAndSettle();

      expect(loader.loaded, isEmpty);
      expect(find.text('지운 파일이에요'), findsOneWidget);
    });

    testWidgets('답을 파일로 저장하면 스낵바 [보기] 가 그 파일을 연다', (tester) async {
      answer('산책을 했어요');
      await pump(tester);
      await tester.tap(find.text('어제 뭐 했어?'));
      await tester.pumpAndSettle();

      await longPressBubble(tester, '산책을 했어요');
      await tester.tap(find.text('파일로 저장'));
      await tester.pumpAndSettle();
      expect(find.text('작업 폴더에 저장했어요'), findsOneWidget);
      await tester.tap(find.text('보기'));
      await tester.pumpAndSettle();

      expect(find.byType(WorkspaceFileViewPage), findsOneWidget);
      final text = tester.widget<SelectableText>(
        find.descendant(
          of: find.byType(WorkspaceFileViewPage),
          matching: find.byType(SelectableText),
        ),
      );
      expect(text.data, contains('산책을 했어요'));
    });
  });
}

class _PendingSettings extends FakeChatSettings {
  _PendingSettings(this.pending) : super('sk-ant-test');

  final Future<String?> pending;

  @override
  Future<bool> hasApiKey() async => await pending != null;
}

/// 받은 PickedFile 을 적고 글 첨부로 받아 준다.
class _RecordingLoader implements AttachmentLoader {
  final loaded = <PickedFile>[];

  @override
  Future<AttachmentLoad> load(PickedFile file) async {
    loaded.add(file);
    return AttachmentLoad.ok(
      ChatAttachment.text(
        name: file.name,
        text: '답',
        workspacePath: file.workspacePath,
      ),
    );
  }

  @override
  Future<Uint8List> readOriginal(String path) async => Uint8List(0);
}
