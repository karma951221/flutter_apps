import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/presentation/chat/cubit/chat_cubit.dart';
import 'package:walk/presentation/chat/cubit/chat_state.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_settings.dart';

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
    cubit = ChatCubit(session, settings, diary);
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
}
