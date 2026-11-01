import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/usecase/open_conversation.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/chat/cubit/chat_cubit.dart';
import 'package:walk/presentation/chat/cubit/chat_state.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/recording_chat_trace.dart';

class _MockSession extends Mock implements ChatSession {}

class _MockDiary extends Mock implements DiaryRepository {}

class _MockHistory extends Mock implements ChatHistoryRepository {}

const _target = (vendor: ChatVendor.openai, model: 'gpt-test');

ChatTurnRecord _record(
  int seq, {
  String conversationId = 'c1',
  List<String> cited = const [],
  bool stopped = false,
}) => ChatTurnRecord(
  conversationId: conversationId,
  seq: seq,
  question: '질문$seq',
  answer: '답$seq',
  citedEntryIds: cited,
  stopped: stopped,
  vendor: ChatVendor.anthropic,
  model: 'm',
  askedAt: diaryT0,
);

DiaryEntry _entry(String id, {bool trashed = false}) => DiaryEntry(
  id: id,
  storyId: 's1',
  body: '본문 $id',
  occurredAt: diaryT0,
  createdAt: diaryT0,
  updatedAt: diaryT0,
  deletedAt: trashed ? diaryT0 : null,
  media: const [],
  tags: const [],
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const ChatTurnDraft(
        question: '',
        answer: '',
        citedEntryIds: [],
        vendor: ChatVendor.anthropic,
        model: '',
      ),
    );
    registerFallbackValue(<ChatTurnText>[]);
  });

  late _MockSession session;
  late _MockDiary diary;
  late _MockHistory history;
  late OpenConversation open;
  late FakeChatSettings settings;
  late FakeChatKeyVerifier verifier;
  late ChatCubit cubit;

  /// appendTurn 이 받은 (conversationId, draft).
  late List<(String?, ChatTurnDraft)> appended;

  setUp(() {
    session = _MockSession();
    diary = _MockDiary();
    history = _MockHistory();
    open = OpenConversation();
    settings = FakeChatSettings('sk-ant-test')..consented = true;
    verifier = FakeChatKeyVerifier();
    appended = [];
    when(() => session.target).thenReturn(_target);
    when(
      () => history.watchExists(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => history.appendTurn(
        conversationId: any(named: 'conversationId'),
        turn: any(named: 'turn'),
      ),
    ).thenAnswer((invocation) async {
      final id = invocation.namedArguments[#conversationId] as String?;
      final turn = invocation.namedArguments[#turn] as ChatTurnDraft;
      appended.add((id, turn));
      return (conversationId: id ?? 'c1', seq: appended.length);
    });
    cubit = ChatCubit(
      session,
      settings,
      diary,
      const NoopChatTrace(),
      verifier,
      history,
      open,
    );
  });

  tearDown(() => cubit.close());

  group('확인 전 키 재확인', () {
    test('refresh 가 ready 면 확인 전 키 재확인을 부른다', () async {
      await cubit.refresh();
      await pumpEventQueue();

      expect(cubit.state.access, ChatAccess.ready);
      expect(verifier.recheckCalls, 1);
    });

    test('recheck: false 면 상태만 읽고 부르지 않는다', () async {
      await cubit.refresh(recheck: false);
      await pumpEventQueue();

      expect(cubit.state.access, ChatAccess.ready);
      expect(verifier.recheckCalls, 0);
    });

    test('noKey 면 부르지 않는다', () async {
      settings.key = null;
      await cubit.refresh();
      await pumpEventQueue();

      expect(cubit.state.access, ChatAccess.noKey);
      expect(verifier.recheckCalls, 0);
    });

    test('동의 전(needsConsent)이면 부르지 않는다', () async {
      settings.consented = false;
      await cubit.refresh();
      await pumpEventQueue();

      expect(cubit.state.access, ChatAccess.needsConsent);
      expect(verifier.recheckCalls, 0);
    });

    test('재확인이 던져도 refresh 는 끝난다', () async {
      verifier.recheckError = StateError('boom');
      await cubit.refresh();
      await pumpEventQueue();

      expect(cubit.state.access, ChatAccess.ready);
      expect(verifier.recheckCalls, 1);
    });
  });

  test('키가 없으면 noKey, 동의 전이면 needsConsent, 둘 다면 ready', () async {
    expect(cubit.state.access, ChatAccess.checking);

    settings
      ..key = null
      ..consented = false;
    await cubit.refresh();
    expect(cubit.state.access, ChatAccess.noKey);

    settings.key = 'sk-ant-test';
    await cubit.refresh();
    expect(cubit.state.access, ChatAccess.needsConsent);

    await cubit.consent();
    expect(settings.consented, isTrue);
    expect(cubit.state.access, ChatAccess.ready);
  });

  test('send 는 user 말풍선과 흘러나오는 assistant 말풍선을 만들고 끝나면 busy false', () async {
    final events = StreamController<ChatEvent>();
    when(() => session.ask('어제 뭐 했어?')).thenAnswer((_) => events.stream);
    await cubit.refresh();

    final sent = cubit.send('어제 뭐 했어?');
    await pumpEventQueue();
    expect(cubit.state.busy, isTrue);
    expect(
      cubit.state.bubbles.first,
      const ChatBubble(role: ChatRole.user, text: '어제 뭐 했어?'),
    );

    events.add(const ChatEvent.toolStarted('search_diary'));
    await pumpEventQueue();
    expect(cubit.state.activeTool, 'search_diary');

    events
      ..add(const ChatEvent.text('산책을 '))
      ..add(const ChatEvent.text('했어요'));
    await pumpEventQueue();
    expect(cubit.state.bubbles.last.role, ChatRole.assistant);
    expect(cubit.state.bubbles.last.text, '산책을 했어요');
    expect(cubit.state.activeTool, isNull);
    expect(cubit.state.busy, isTrue);

    events.add(const ChatEvent.finished(citedEntryIds: []));
    await events.close();
    await sent;
    expect(cubit.state.busy, isFalse);
    expect(cubit.state.bubbles, hasLength(2));
  });

  test('빈 질문이나 답하는 중의 질문은 무시한다', () async {
    final events = StreamController<ChatEvent>();
    when(() => session.ask(any())).thenAnswer((_) => events.stream);
    await cubit.refresh();

    await cubit.send('   ');
    verifyNever(() => session.ask(any()));

    unawaited(cubit.send('하나'));
    await pumpEventQueue();
    await cubit.send('둘');
    verify(() => session.ask(any())).called(1);
    await events.close();
  });

  test('인용 기록 중 휴지통 · 없는 것은 뺀다', () async {
    when(() => diary.entry('live')).thenAnswer((_) async => Ok(_entry('live')));
    when(
      () => diary.entry('trashed'),
    ).thenAnswer((_) async => Ok(_entry('trashed', trashed: true)));
    when(
      () => diary.entry('gone'),
    ).thenAnswer((_) async => const Err(Failure.notFound()));
    when(() => session.ask(any())).thenAnswer(
      (_) => Stream.fromIterable(const [
        ChatEvent.text('기록이 있어요'),
        ChatEvent.finished(citedEntryIds: ['trashed', 'gone', 'live']),
      ]),
    );
    await cubit.refresh();

    await cubit.send('질문');

    final answer = cubit.state.bubbles.last;
    expect([for (final e in answer.cited) e.id], ['live']);
    expect(cubit.state.busy, isFalse);
  });

  test('실패하면 assistant 말풍선에 failure 가 붙는다', () async {
    when(() => session.ask(any())).thenAnswer(
      (_) => Stream.fromIterable(const [
        ChatEvent.text('반쯤'),
        ChatEvent.failed(ChatFailure.invalidKey),
      ]),
    );
    await cubit.refresh();

    await cubit.send('질문');

    final answer = cubit.state.bubbles.last;
    expect(answer.role, ChatRole.assistant);
    expect(answer.text, '반쯤');
    expect(answer.failure, ChatFailure.invalidKey);
    expect(cubit.state.busy, isFalse);
  });

  test('newConversation 은 session.reset 을 부르고 비운다', () async {
    final events = StreamController<ChatEvent>();
    when(() => session.ask(any())).thenAnswer((_) => events.stream);
    await cubit.refresh();
    final sent = cubit.send('질문');
    events
      ..add(const ChatEvent.toolStarted('search_diary'))
      ..add(const ChatEvent.text('답하는 중'));
    await pumpEventQueue();

    cubit.newConversation();
    await sent;

    verify(() => session.reset()).called(1);
    expect(cubit.state.bubbles, isEmpty);
    expect(cubit.state.busy, isFalse);
    expect(cubit.state.activeTool, isNull);
    expect(cubit.state.access, ChatAccess.ready);
    // 끊긴 질문의 이벤트는 더 들어오지 않는다.
    expect(events.hasListener, isFalse);
    await events.close();
  });

  test('refresh 는 hasApiKey 만 본다', () async {
    settings.key = null;
    await cubit.refresh();
    expect(cubit.state.access, ChatAccess.noKey);

    settings.key = 'sk-ant-test';
    await cubit.refresh();
    expect(cubit.state.access, ChatAccess.ready);

    expect(settings.apiKeyCalls, 0);
  });

  test('키를 읽다 실패하면 noKey 로 둔다', () async {
    settings.failWith = Exception('keystore');

    await cubit.refresh();

    expect(cubit.state.access, ChatAccess.noKey);
  });

  test('ready 가 아니면 send 는 아무것도 하지 않는다', () async {
    when(() => session.ask(any())).thenAnswer((_) => const Stream.empty());
    settings.consented = false;
    await cubit.refresh();
    expect(cubit.state.access, ChatAccess.needsConsent);

    await cubit.send('질문');

    verifyNever(() => session.ask(any()));
    expect(cubit.state.bubbles, isEmpty);
    expect(cubit.state.busy, isFalse);
  });

  test('답하는 중에 닫으면 session.reset 을 불러 세션이 묶이지 않는다', () async {
    final events = StreamController<ChatEvent>();
    when(() => session.ask(any())).thenAnswer((_) => events.stream);
    await cubit.refresh();
    unawaited(cubit.send('질문'));
    await pumpEventQueue();

    await cubit.close();

    verify(() => session.reset()).called(1);
    await events.close();
  });

  group('stop', () {
    late StreamController<ChatEvent> events;

    setUp(() async {
      events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      await cubit.refresh();
    });

    // 구독되지 않은 채 닫으면 close 의 Future 는 끝나지 않는다 — 기다리지 않는다.
    tearDown(() => unawaited(events.close()));

    /// send 가 돌려준 Future.
    late Future<void> sent;

    /// 질문 하나를 보내고 [phase] 까지 흘린다.
    Future<void> start(List<ChatEvent> phase) async {
      sent = cubit.send('질문');
      phase.forEach(events.add);
      await pumpEventQueue();
    }

    final phases = <String, List<ChatEvent>>{
      '보내는 중': const [],
      '도구 중': const [ChatEvent.toolStarted('search_diary')],
      '글 쓰는 중': const [ChatEvent.text('반쯤')],
    };
    for (final MapEntry(key: name, value: phase) in phases.entries) {
      test('$name stop 하면 같은 emit 에서 busy false', () async {
        when(() => session.stop()).thenReturn(
          phase.any((e) => e is ChatText)
              ? const ChatStopResult.kept(text: '반쯤', citedEntryIds: [])
              : const ChatStopResult.dropped(),
        );
        await start(phase);
        final emitted = <ChatState>[];
        final listening = cubit.stream.listen(emitted.add);

        cubit.stop();
        await pumpEventQueue();

        expect(emitted.first.busy, isFalse);
        expect(emitted.first.activeTool, isNull);
        expect(cubit.state.busy, isFalse);
        await listening.cancel();
      });
    }

    test('session.stop 을 구독을 끊기 전에 부른다 — 끊고 나면 받은 글을 잃을 수 있다', () async {
      bool? listeningAtStop;
      when(() => session.stop()).thenAnswer((_) {
        listeningAtStop = events.hasListener;
        return const ChatStopResult.kept(text: '반쯤', citedEntryIds: []);
      });
      await start(const [ChatEvent.text('반쯤')]);

      cubit.stop();

      expect(listeningAtStop, isTrue);
      expect(events.hasListener, isFalse);
    });

    test('글이 있으면 stopped 말풍선이 남고 그때까지의 인용이 붙는다', () async {
      final read = Completer<Result<DiaryEntry>>();
      when(() => diary.entry('e1')).thenAnswer((_) => read.future);
      when(() => session.stop()).thenReturn(
        const ChatStopResult.kept(text: '반쯤', citedEntryIds: ['e1']),
      );
      await start(const [ChatEvent.text('반쯤')]);

      cubit.stop();

      expect(cubit.state.bubbles, hasLength(2));
      expect(cubit.state.bubbles.last.text, '반쯤');
      expect(cubit.state.bubbles.last.stopped, isTrue);
      expect(cubit.state.bubbles.last.cited, isEmpty);
      expect(cubit.state.busy, isFalse);

      read.complete(Ok(_entry('e1')));
      await pumpEventQueue();
      expect([for (final e in cubit.state.bubbles.last.cited) e.id], ['e1']);
      expect(cubit.state.bubbles.last.stopped, isTrue);
    });

    test('멈춘 말풍선의 글은 세션이 남긴 kept.text 다', () async {
      when(() => session.stop()).thenReturn(
        const ChatStopResult.kept(text: '반쯤 받은 글', citedEntryIds: []),
      );
      await start(const [ChatEvent.text('반쯤')]);
      expect(cubit.state.bubbles.last.text, '반쯤');

      cubit.stop();

      expect(cubit.state.bubbles.last.text, '반쯤 받은 글');
      expect(cubit.state.bubbles.last.stopped, isTrue);
    });

    test('인용을 읽는 사이 다음 질문을 보내도 인용은 멈춘 말풍선에 붙는다', () async {
      final read = Completer<Result<DiaryEntry>>();
      when(() => diary.entry('e1')).thenAnswer((_) => read.future);
      when(() => session.stop()).thenReturn(
        const ChatStopResult.kept(text: '반쯤', citedEntryIds: ['e1']),
      );
      await start(const [ChatEvent.text('반쯤')]);
      cubit.stop();
      final next = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => next.stream);
      unawaited(cubit.send('다음'));

      read.complete(Ok(_entry('e1')));
      await pumpEventQueue();

      expect([for (final e in cubit.state.bubbles[1].cited) e.id], ['e1']);
      expect(cubit.state.bubbles.last.cited, isEmpty);
      await next.close();
    });

    test('글이 없으면 말풍선 둘이 사라지고 restoredDraft 가 질문이다', () async {
      when(() => session.stop()).thenReturn(const ChatStopResult.dropped());
      await start(const [ChatEvent.toolStarted('search_diary')]);

      cubit.stop();

      expect(cubit.state.bubbles, isEmpty);
      expect(cubit.state.restoredDraft, '질문');
      expect(cubit.state.busy, isFalse);

      cubit.consumeRestoredDraft();
      expect(cubit.state.restoredDraft, isNull);
    });

    test('멈춘 뒤 늦은 이벤트는 무시한다', () async {
      when(
        () => session.stop(),
      ).thenReturn(const ChatStopResult.kept(text: '반쯤', citedEntryIds: []));
      await start(const [ChatEvent.text('반쯤')]);

      cubit.stop();
      events
        ..add(const ChatEvent.text(' 늦은 글'))
        ..add(const ChatEvent.failed(ChatFailure.overloaded));
      await pumpEventQueue();

      expect(cubit.state.bubbles.last.text, '반쯤');
      expect(cubit.state.bubbles.last.failure, isNull);
      expect(cubit.state.busy, isFalse);
    });

    test('멈춘 직후 send 가 성공한다', () async {
      when(
        () => session.stop(),
      ).thenReturn(const ChatStopResult.kept(text: '반쯤', citedEntryIds: []));
      await start(const [ChatEvent.text('반쯤')]);
      cubit.stop();
      when(() => session.ask(any())).thenAnswer(
        (_) => Stream.fromIterable(const [
          ChatEvent.text('새 답'),
          ChatEvent.finished(citedEntryIds: []),
        ]),
      );

      await expectLater(cubit.send('다음'), completes);

      expect(cubit.state.bubbles, hasLength(4));
      expect(cubit.state.bubbles[2].text, '다음');
      expect(cubit.state.bubbles[3].text, '새 답');
      expect(cubit.state.bubbles[3].stopped, isFalse);
    });

    test('인용을 읽는 중(finished 뒤) stop 은 아무것도 바꾸지 않는다', () async {
      final read = Completer<Result<DiaryEntry>>();
      when(() => diary.entry('e1')).thenAnswer((_) => read.future);
      when(() => session.stop()).thenReturn(const ChatStopResult.idle());
      await start(const [
        ChatEvent.text('다 됐어요'),
        ChatEvent.finished(citedEntryIds: ['e1']),
      ]);
      final before = cubit.state;

      cubit.stop();

      expect(cubit.state, before);
      verifyNever(() => session.stop());
      read.complete(Ok(_entry('e1')));
      await events.close();
      await sent;
      expect(cubit.state.bubbles.last.stopped, isFalse);
      expect([for (final e in cubit.state.bubbles.last.cited) e.id], ['e1']);
    });

    test('세션이 이미 끝났으면(idle) 화면만 정리한다', () async {
      when(() => session.stop()).thenReturn(const ChatStopResult.idle());
      await start(const [ChatEvent.text('반쯤')]);

      cubit.stop();

      expect(cubit.state.busy, isFalse);
      expect(cubit.state.bubbles.last.text, '반쯤');
      expect(cubit.state.bubbles.last.stopped, isFalse);
    });

    test('stop 하면 send 가 돌려준 Future 가 끝난다', () async {
      when(() => session.stop()).thenReturn(const ChatStopResult.dropped());
      await start(const []);

      cubit.stop();

      await expectLater(sent, completes);
    });

    test('답하는 중이 아니면 stop 은 무시한다', () {
      cubit.stop();

      verifyNever(() => session.stop());
      expect(cubit.state.busy, isFalse);
    });
  });

  group('trace', () {
    late RecordingChatTrace trace;
    late List<VoidCallback> frames;
    late ChatCubit traced;

    setUp(() async {
      trace = RecordingChatTrace();
      frames = [];
      traced = ChatCubit(
        session,
        settings,
        diary,
        trace,
        verifier,
        history,
        open,
        schedulePostFrame: frames.add,
      );
      await traced.refresh();
    });

    tearDown(() => traced.close());

    /// 쌓인 프레임 콜백을 돌린다(프레임 하나가 지나간 셈).
    void pumpFrame() {
      final pending = List.of(frames);
      frames.clear();
      for (final cb in pending) {
        cb();
      }
    }

    test('send 는 begin · send, 끝나면 done · end', () async {
      when(() => session.ask(any())).thenAnswer(
        (_) =>
            Stream.fromIterable(const [ChatEvent.finished(citedEntryIds: [])]),
      );

      await traced.send('질문');

      expect(trace.labels, [
        'begin',
        ChatTraceMark.send,
        ChatTraceMark.done,
        'end',
      ]);
    });

    test('첫 글 emit 뒤 프레임에 firstGlyph 를 한 번만', () async {
      final events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      final sent = traced.send('질문');

      events.add(const ChatEvent.toolStarted('search_diary'));
      await pumpEventQueue();
      expect(trace.labels, ['begin', ChatTraceMark.send]);
      pumpFrame();
      expect(trace.labels.last, ChatTraceMark.firstVisible);

      events
        ..add(const ChatEvent.text('산책을 '))
        ..add(const ChatEvent.text('했어요'));
      await pumpEventQueue();
      pumpFrame();
      events.add(const ChatEvent.text('.'));
      await pumpEventQueue();
      pumpFrame();

      expect(
        trace.labels.where((l) => l == ChatTraceMark.firstGlyph),
        hasLength(1),
      );
      expect(
        trace.labels.where((l) => l == ChatTraceMark.firstVisible),
        hasLength(1),
      );

      events.add(const ChatEvent.finished(citedEntryIds: []));
      await events.close();
      await sent;
      expect(trace.labels, [
        'begin',
        ChatTraceMark.send,
        ChatTraceMark.firstVisible,
        ChatTraceMark.firstGlyph,
        ChatTraceMark.done,
        'end',
      ]);
    });

    test('글과 끝이 한 프레임 안에 오면 end 는 그 프레임 표시 뒤에', () async {
      when(() => session.ask(any())).thenAnswer(
        (_) => Stream.fromIterable(const [
          ChatEvent.text('짧은 답'),
          ChatEvent.finished(citedEntryIds: []),
        ]),
      );

      await traced.send('질문');
      expect(trace.labels, ['begin', ChatTraceMark.send, ChatTraceMark.done]);
      pumpFrame();

      expect(trace.labels, [
        'begin',
        ChatTraceMark.send,
        ChatTraceMark.done,
        ChatTraceMark.firstVisible,
        ChatTraceMark.firstGlyph,
        'end',
      ]);
    });

    test('답하는 중에 newConversation 하면 abort · done · end', () async {
      final events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      unawaited(traced.send('질문'));
      await pumpEventQueue();
      // 어댑터는 reset 이 모델 구독을 끊을 때 abort 를 찍는다.
      when(() => session.reset()).thenAnswer((_) {
        trace.mark(ChatTraceMark.abort);
      });

      traced.newConversation();
      when(() => session.reset()).thenReturn(null);
      traced.newConversation();

      expect(trace.labels, [
        'begin',
        ChatTraceMark.send,
        ChatTraceMark.abort,
        ChatTraceMark.done,
        'end',
      ]);
      await events.close();
    });

    test('답하는 중에 닫히면 abort · done · end', () async {
      final events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      unawaited(traced.send('질문'));
      await pumpEventQueue();
      when(() => session.reset()).thenAnswer((_) {
        trace.mark(ChatTraceMark.abort);
      });

      await traced.close();

      expect(trace.labels, [
        'begin',
        ChatTraceMark.send,
        ChatTraceMark.abort,
        ChatTraceMark.done,
        'end',
      ]);
      await events.close();
    });

    test('답하는 중에 멈추면 userStop · done · end', () async {
      final events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      when(() => session.stop()).thenReturn(const ChatStopResult.dropped());
      unawaited(traced.send('질문'));
      await pumpEventQueue();

      traced.stop();

      expect(trace.labels, [
        'begin',
        ChatTraceMark.send,
        ChatTraceMark.userStop,
        ChatTraceMark.done,
        'end',
      ]);
      await events.close();
    });

    test('trace 가 꺼져 있으면 아무것도 찍지 않고 프레임도 예약하지 않는다', () async {
      final off = RecordingChatTrace(enabled: false);
      final quiet = ChatCubit(
        session,
        settings,
        diary,
        off,
        verifier,
        history,
        open,
        schedulePostFrame: frames.add,
      );
      await quiet.refresh();
      when(() => session.ask(any())).thenAnswer(
        (_) => Stream.fromIterable(const [
          ChatEvent.text('답'),
          ChatEvent.finished(citedEntryIds: []),
        ]),
      );

      await quiet.send('질문');
      await quiet.close();

      expect(off.marks, isEmpty);
      expect(frames, isEmpty);
    });
  });

  group('대화 기록', () {
    setUp(() async {
      await cubit.refresh();
    });

    /// 답이 [answer] 로 끝나는 질문 하나를 보낸다.
    Future<void> turn(
      String question,
      String answer, {
      List<String> cited = const [],
    }) {
      when(() => session.ask(question)).thenAnswer(
        (_) => Stream.fromIterable([
          if (answer.isNotEmpty) ChatEvent.text(answer),
          ChatEvent.finished(citedEntryIds: cited),
        ]),
      );
      return cubit.send(question);
    }

    void verifyNoWrites() {
      verifyNever(
        () => history.appendTurn(
          conversationId: any(named: 'conversationId'),
          turn: any(named: 'turn'),
        ),
      );
      verifyNever(() => history.deleteTurn(any(), any()));
      verifyNever(() => history.delete(any()));
    }

    test('답이 끝나면 첫 턴에서 대화를 만들고 conversationId · 두 말풍선 seq 가 생긴다', () async {
      when(() => diary.entry('e1')).thenAnswer((_) async => Ok(_entry('e1')));

      await turn('질문', '답', cited: ['e1']);

      expect(appended, hasLength(1));
      final (id, draft) = appended.single;
      expect(id, isNull);
      expect(
        draft,
        const ChatTurnDraft(
          question: '질문',
          answer: '답',
          citedEntryIds: ['e1'],
          stopped: false,
          vendor: ChatVendor.openai,
          model: 'gpt-test',
        ),
      );
      expect(cubit.state.conversationId, 'c1');
      expect([for (final b in cubit.state.bubbles) b.seq], [1, 1]);
      expect([for (final e in cubit.state.bubbles.last.cited) e.id], ['e1']);
    });

    test('두 번째 턴은 같은 conversationId 로 저장한다', () async {
      await turn('하나', '답1');
      await turn('둘', '답2');

      expect([for (final (id, _) in appended) id], [null, 'c1']);
      expect([for (final b in cubit.state.bubbles) b.seq], [1, 1, 2, 2]);
    });

    test('앞 저장이 끝나기 전 다음 턴이 끝나도 같은 대화에 순서대로 저장한다', () async {
      final first = Completer<ChatTurnRef>();
      var calls = 0;
      final ids = <String?>[];
      when(
        () => history.appendTurn(
          conversationId: any(named: 'conversationId'),
          turn: any(named: 'turn'),
        ),
      ).thenAnswer((invocation) {
        calls++;
        ids.add(invocation.namedArguments[#conversationId] as String?);
        if (calls == 1) return first.future;
        return Future.value((conversationId: 'c1', seq: 2));
      });

      unawaited(turn('하나', '답1'));
      await pumpEventQueue();
      final second = turn('둘', '답2');
      await pumpEventQueue();
      expect(calls, 1);

      first.complete((conversationId: 'c1', seq: 1));
      await second;

      expect(ids, [null, 'c1']);
      expect([for (final b in cubit.state.bubbles) b.seq], [1, 1, 2, 2]);
    });

    group('멈춤', () {
      late StreamController<ChatEvent> events;

      setUp(() {
        events = StreamController<ChatEvent>();
        when(() => session.ask(any())).thenAnswer((_) => events.stream);
      });

      tearDown(() => unawaited(events.close()));

      test('글이 온 뒤 멈추면 stopped true 로 저장한다', () async {
        when(() => session.stop()).thenReturn(
          const ChatStopResult.kept(text: '반쯤', citedEntryIds: ['e1']),
        );
        when(
          () => diary.entry('e1'),
        ).thenAnswer((_) async => const Err(Failure.notFound()));
        unawaited(cubit.send('질문'));
        events.add(const ChatEvent.text('반쯤'));
        await pumpEventQueue();

        cubit.stop();
        await pumpEventQueue();

        final (id, draft) = appended.single;
        expect(id, isNull);
        expect(draft.stopped, isTrue);
        expect(draft.answer, '반쯤');
        expect(draft.question, '질문');
        expect(draft.citedEntryIds, ['e1']);
        expect(cubit.state.bubbles.last.stopped, isTrue);
        expect([for (final b in cubit.state.bubbles) b.seq], [1, 1]);
      });

      test('글 없이 멈추면 저장하지 않는다', () async {
        when(() => session.stop()).thenReturn(const ChatStopResult.dropped());
        unawaited(cubit.send('질문'));
        await pumpEventQueue();

        cubit.stop();
        await pumpEventQueue();

        verifyNoWrites();
      });
    });

    test('실패한 질문은 저장하지 않는다', () async {
      when(() => session.ask(any())).thenAnswer(
        (_) => Stream.fromIterable(const [
          ChatEvent.text('반쯤'),
          ChatEvent.failed(ChatFailure.network),
        ]),
      );

      await cubit.send('질문');

      verifyNoWrites();
      expect(cubit.state.conversationId, isNull);
    });

    test('답 글이 비면 저장하지 않는다', () async {
      await turn('질문', '');
      await turn('질문2', '  ');

      verifyNoWrites();
    });

    test('임시 대화는 끝 · 멈춤 · 턴 지우기 어디서도 저장소에 쓰지 않는다', () async {
      cubit.startTemporary();
      await turn('하나', '답1');

      final events = StreamController<ChatEvent>();
      when(() => session.ask('둘')).thenAnswer((_) => events.stream);
      when(
        () => session.stop(),
      ).thenReturn(const ChatStopResult.kept(text: '반쯤', citedEntryIds: []));
      unawaited(cubit.send('둘'));
      events.add(const ChatEvent.text('반쯤'));
      await pumpEventQueue();
      cubit.stop();
      await pumpEventQueue();

      await cubit.deleteTurn(0);

      verifyNoWrites();
      expect(cubit.state.temporary, isTrue);
      expect(cubit.state.conversationId, isNull);
      expect(open.id, isNull);
      expect([for (final b in cubit.state.bubbles) b.seq], [null, null]);
      unawaited(events.close());
    });

    test('저장이 던져도 답은 끝나고 busy false', () async {
      when(
        () => history.appendTurn(
          conversationId: any(named: 'conversationId'),
          turn: any(named: 'turn'),
        ),
      ).thenThrow(StateError('db'));

      await turn('질문', '답');

      expect(cubit.state.busy, isFalse);
      expect(cubit.state.bubbles, hasLength(2));
      expect(cubit.state.bubbles.last.text, '답');
      expect(cubit.state.conversationId, isNull);
    });

    test('저장이 끝나기 전에 새 대화를 시작하면 conversationId 가 붙지 않는다', () async {
      final saving = Completer<ChatTurnRef>();
      when(
        () => history.appendTurn(
          conversationId: any(named: 'conversationId'),
          turn: any(named: 'turn'),
        ),
      ).thenAnswer((_) => saving.future);

      final sent = turn('질문', '답');
      await pumpEventQueue();
      cubit.newConversation();
      saving.complete((conversationId: 'c1', seq: 1));
      await sent;
      await pumpEventQueue();

      expect(cubit.state.conversationId, isNull);
      expect(cubit.state.bubbles, isEmpty);
      expect(open.id, isNull);
    });

    test(
      'open 은 말풍선 · 근거 칩 · stopped · seq 를 복원하고 session.resume(turns 의 text, temporary: false)',
      () async {
        when(
          () => diary.entry('live'),
        ).thenAnswer((_) async => Ok(_entry('live')));
        when(
          () => diary.entry('trashed'),
        ).thenAnswer((_) async => Ok(_entry('trashed', trashed: true)));
        final records = [
          _record(1, cited: ['trashed', 'live']),
          _record(3, stopped: true),
        ];
        when(() => history.turns('c1')).thenAnswer((_) async => records);

        await cubit.open('c1');

        final bubbles = cubit.state.bubbles;
        expect([for (final b in bubbles) b.text], ['질문1', '답1', '질문3', '답3']);
        expect(
          [for (final b in bubbles) b.role],
          [
            ChatRole.user,
            ChatRole.assistant,
            ChatRole.user,
            ChatRole.assistant,
          ],
        );
        expect([for (final b in bubbles) b.seq], [1, 1, 3, 3]);
        expect([for (final e in bubbles[1].cited) e.id], ['live']);
        expect(bubbles[3].stopped, isTrue);
        expect(bubbles[1].stopped, isFalse);
        expect(cubit.state.conversationId, 'c1');
        expect(cubit.state.temporary, isFalse);
        expect(open.id, 'c1');
        verify(
          () => session.resume([
            for (final r in records) r.text,
          ], temporary: false),
        ).called(1);
      },
    );

    test('열린 대화에서 이어 묻는 턴은 그 대화에 저장한다', () async {
      when(
        () => history.turns('c9'),
      ).thenAnswer((_) async => [_record(1, conversationId: 'c9')]);
      await cubit.open('c9');

      await turn('이어서', '답');

      expect(appended.single.$1, 'c9');
    });

    test('답하는 중 open 하면 끊고 연다', () async {
      final events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      when(() => history.turns('c1')).thenAnswer((_) async => [_record(1)]);
      final sent = cubit.send('질문');
      events.add(const ChatEvent.text('답하는 중'));
      await pumpEventQueue();

      await cubit.open('c1');
      await sent;

      expect(events.hasListener, isFalse);
      expect(cubit.state.busy, isFalse);
      expect([for (final b in cubit.state.bubbles) b.text], ['질문1', '답1']);
      verifyNoWrites();
      await events.close();
    });

    test('임시 대화 중 open 하면 temporary false', () async {
      when(() => history.turns('c1')).thenAnswer((_) async => [_record(1)]);
      cubit.startTemporary();

      await cubit.open('c1');

      expect(cubit.state.temporary, isFalse);
      expect(cubit.state.conversationId, 'c1');
    });

    test('없는 대화를 open 하면 빈 새 대화', () async {
      when(() => history.turns('gone')).thenAnswer((_) async => const []);
      await turn('질문', '답');

      await cubit.open('gone');

      expect(cubit.state.bubbles, isEmpty);
      expect(cubit.state.conversationId, isNull);
      expect(cubit.state.temporary, isFalse);
      expect(open.id, isNull);
      verifyNever(
        () => session.resume(any(), temporary: any(named: 'temporary')),
      );
    });

    test(
      'startTemporary 는 말풍선을 비우고 temporary true, session.reset(temporary: true)',
      () async {
        await turn('질문', '답');

        cubit.startTemporary();

        expect(cubit.state.bubbles, isEmpty);
        expect(cubit.state.temporary, isTrue);
        expect(cubit.state.conversationId, isNull);
        expect(open.id, isNull);
        verify(() => session.reset(temporary: true)).called(1);
      },
    );

    test('newConversation 은 temporary false', () {
      cubit.startTemporary();

      cubit.newConversation();

      expect(cubit.state.temporary, isFalse);
      verify(() => session.reset(temporary: false)).called(1);
    });

    test(
      'deleteTurn(저장된 턴) 은 deleteTurn 뒤 남은 턴으로 resume 하고 말풍선을 다시 그린다',
      () async {
        await turn('질문1', '답1');
        await turn('질문2', '답2');
        when(() => history.deleteTurn('c1', 1)).thenAnswer((_) async {});
        final left = [_record(2)];
        when(() => history.turns('c1')).thenAnswer((_) async => left);

        await cubit.deleteTurn(0);

        verify(() => history.deleteTurn('c1', 1)).called(1);
        verify(
          () => session.resume([left.single.text], temporary: false),
        ).called(1);
        expect([for (final b in cubit.state.bubbles) b.text], ['질문2', '답2']);
        expect([for (final b in cubit.state.bubbles) b.seq], [2, 2]);
        expect(cubit.state.conversationId, 'c1');
      },
    );

    test('deleteTurn(저장된 마지막 턴) 이면 빈 새 대화', () async {
      await turn('질문', '답');
      when(() => history.deleteTurn('c1', 1)).thenAnswer((_) async {});
      when(() => history.turns('c1')).thenAnswer((_) async => const []);

      await cubit.deleteTurn(0);

      expect(cubit.state.bubbles, isEmpty);
      expect(cubit.state.conversationId, isNull);
      expect(open.id, isNull);
    });

    test(
      'deleteTurn(임시 대화) 은 화면에서 빼고 남은 쌍으로 resume(temporary: true)',
      () async {
        cubit.startTemporary();
        await turn('하나', '답1');
        await turn('둘', '답2');

        await cubit.deleteTurn(0);

        expect([for (final b in cubit.state.bubbles) b.text], ['둘', '답2']);
        verify(
          () => session.resume(const [
            ChatTurnText(question: '둘', answer: '답2'),
          ], temporary: true),
        ).called(1);
        verifyNoWrites();
      },
    );

    test('deleteTurn 실패 쌍은 화면에서만 뺀다(resume 안 부름)', () async {
      await turn('하나', '답1');
      when(() => session.ask('둘')).thenAnswer(
        (_) =>
            Stream.fromIterable(const [ChatEvent.failed(ChatFailure.network)]),
      );
      await cubit.send('둘');

      await cubit.deleteTurn(2);

      expect([for (final b in cubit.state.bubbles) b.text], ['하나', '답1']);
      verifyNever(
        () => session.resume(any(), temporary: any(named: 'temporary')),
      );
      verifyNever(() => history.deleteTurn(any(), any()));
    });

    test('deleteTurn 은 답하는 중이면 무시한다', () async {
      await turn('하나', '답1');
      final events = StreamController<ChatEvent>();
      when(() => session.ask('둘')).thenAnswer((_) => events.stream);
      unawaited(cubit.send('둘'));
      await pumpEventQueue();

      await cubit.deleteTurn(0);

      expect(cubit.state.bubbles, hasLength(4));
      verifyNever(() => history.deleteTurn(any(), any()));
      unawaited(events.close());
    });

    test('열린 대화가 밖에서 지워지면(watchExists false) 빈 새 대화가 된다', () async {
      final exists = StreamController<bool>();
      when(() => history.watchExists('c1')).thenAnswer((_) => exists.stream);
      await turn('질문', '답');
      exists.add(true);
      await pumpEventQueue();
      expect(cubit.state.conversationId, 'c1');

      exists.add(false);
      await pumpEventQueue();

      expect(cubit.state.bubbles, isEmpty);
      expect(cubit.state.conversationId, isNull);
      expect(open.id, isNull);
      verify(() => session.reset()).called(1);
      await exists.close();
    });

    test('conversationId 가 바뀌면 OpenConversation.id 도, close 하면 null', () async {
      when(
        () => history.turns('c2'),
      ).thenAnswer((_) async => [_record(1, conversationId: 'c2')]);
      await turn('질문', '답');
      expect(open.id, 'c1');

      await cubit.open('c2');
      expect(open.id, 'c2');

      await cubit.close();
      expect(open.id, isNull);
    });

    test('open 이 대화를 읽는 동안 보낸 질문은 무시하고 읽은 말풍선이 남는다', () async {
      final reading = Completer<List<ChatTurnRecord>>();
      when(() => history.turns('c1')).thenAnswer((_) => reading.future);
      when(() => session.ask(any())).thenAnswer((_) => const Stream.empty());

      final opening = cubit.open('c1');
      expect(cubit.state.loading, isTrue);
      await cubit.send('사이에 보낸 질문');
      reading.complete([_record(1)]);
      await opening;

      verifyNever(() => session.ask(any()));
      expect(cubit.state.loading, isFalse);
      expect([for (final b in cubit.state.bubbles) b.text], ['질문1', '답1']);
    });

    test('저장된 턴을 지우는 동안 보낸 질문은 무시하고 다시 읽은 말풍선이 남는다', () async {
      await turn('질문1', '답1');
      await turn('질문2', '답2');
      final deleting = Completer<void>();
      when(
        () => history.deleteTurn('c1', 1),
      ).thenAnswer((_) => deleting.future);
      when(() => history.turns('c1')).thenAnswer((_) async => [_record(2)]);
      clearInteractions(session);

      final removing = cubit.deleteTurn(0);
      await pumpEventQueue();
      expect(cubit.state.loading, isTrue);
      await cubit.send('사이에 보낸 질문');
      deleting.complete();
      await removing;

      verifyNever(() => session.ask(any()));
      expect(cubit.state.loading, isFalse);
      expect([for (final b in cubit.state.bubbles) b.text], ['질문2', '답2']);
    });

    test('저장 전 턴을 지우고 나면 loading 이 내려간다', () async {
      cubit.startTemporary();
      await turn('하나', '답1');

      await cubit.deleteTurn(0);

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.bubbles, isEmpty);
    });

    test('멈춘 말풍선의 인용을 읽는 사이 대화를 바꾸면 붙이지 않는다', () async {
      final events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      when(() => session.stop()).thenReturn(
        const ChatStopResult.kept(text: '반쯤', citedEntryIds: ['e1']),
      );
      final read = Completer<Result<DiaryEntry>>();
      when(() => diary.entry('e1')).thenAnswer((_) => read.future);
      // 다시 연 대화의 같은 자리에 글까지 같은 멈춘 말풍선이 있어도 붙이지 않는다.
      when(() => history.turns('c1')).thenAnswer(
        (_) async => [
          ChatTurnRecord(
            conversationId: 'c1',
            seq: 1,
            question: '질문',
            answer: '반쯤',
            citedEntryIds: const [],
            stopped: true,
            vendor: ChatVendor.anthropic,
            model: 'm',
            askedAt: diaryT0,
          ),
        ],
      );
      unawaited(cubit.send('질문'));
      events.add(const ChatEvent.text('반쯤'));
      await pumpEventQueue();
      cubit.stop();
      await pumpEventQueue();

      await cubit.open('c1');
      read.complete(Ok(_entry('e1')));
      await pumpEventQueue();

      expect(cubit.state.bubbles.every((b) => b.cited.isEmpty), isTrue);
      unawaited(events.close());
    });

    test('toString 에 질문 · 답 글이 없다', () {
      const bubble = ChatBubble(role: ChatRole.user, text: '비밀 질문', seq: 3);
      const state = ChatState(
        access: ChatAccess.ready,
        bubbles: [
          bubble,
          ChatBubble(role: ChatRole.assistant, text: '비밀 답'),
        ],
        restoredDraft: '되돌린 비밀',
      );

      expect(bubble.toString(), isNot(contains('비밀')));
      expect(bubble.toString(), contains('textLength: 5'));
      expect(state.toString(), isNot(contains('비밀')));
    });

    test('refresh 는 세션 target 의 vendor 를 state 에 둔다', () async {
      expect(cubit.state.vendor, ChatVendor.openai);
      when(
        () => session.target,
      ).thenReturn((vendor: ChatVendor.anthropic, model: 'claude'));

      await cubit.refresh(recheck: false);

      expect(cubit.state.vendor, ChatVendor.anthropic);
    });
  });
}
