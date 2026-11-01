import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_trace.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/chat/cubit/chat_cubit.dart';
import 'package:walk/presentation/chat/cubit/chat_state.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/recording_chat_trace.dart';

class _MockSession extends Mock implements ChatSession {}

class _MockDiary extends Mock implements DiaryRepository {}

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
  late _MockSession session;
  late _MockDiary diary;
  late FakeChatSettings settings;
  late ChatCubit cubit;

  setUp(() {
    session = _MockSession();
    diary = _MockDiary();
    settings = FakeChatSettings('sk-ant-test')..consented = true;
    cubit = ChatCubit(session, settings, diary, const NoopChatTrace());
  });

  tearDown(() => cubit.close());

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

    test('답하는 중에 newConversation 하면 done · end', () async {
      final events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      unawaited(traced.send('질문'));
      await pumpEventQueue();

      traced.newConversation();
      traced.newConversation();

      expect(trace.labels, [
        'begin',
        ChatTraceMark.send,
        ChatTraceMark.done,
        'end',
      ]);
      await events.close();
    });

    test('답하는 중에 닫히면 done · end', () async {
      final events = StreamController<ChatEvent>();
      when(() => session.ask(any())).thenAnswer((_) => events.stream);
      unawaited(traced.send('질문'));
      await pumpEventQueue();

      await traced.close();

      expect(trace.labels, [
        'begin',
        ChatTraceMark.send,
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
}
