import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/presentation/chat/cubit/chat_history_cubit.dart';
import 'package:walk/presentation/chat/cubit/chat_history_state.dart';

class _MockHistory extends Mock implements ChatHistoryRepository {}

final _t0 = DateTime(2026, 11, 1, 9);

Conversation _conversation(String id, String title) => Conversation(
  id: id,
  title: title,
  titleEdited: false,
  createdAt: _t0,
  updatedAt: _t0,
  turnCount: 1,
);

void main() {
  late _MockHistory history;
  late StreamController<List<Conversation>> feed;

  setUp(() {
    history = _MockHistory();
    feed = StreamController<List<Conversation>>.broadcast();
    when(history.conversations).thenAnswer((_) => feed.stream);
  });

  tearDown(() => feed.close());

  test('저장소 스트림을 그대로 상태로(loading false)', () async {
    final cubit = ChatHistoryCubit(history);
    addTearDown(cubit.close);
    expect(cubit.state, const ChatHistoryState());
    expect(cubit.state.loading, isTrue);

    final list = [_conversation('b', '둘'), _conversation('a', '하나')];
    feed.add(list);
    await pumpEventQueue();
    expect(cubit.state, ChatHistoryState(loading: false, conversations: list));

    feed.add(const []);
    await pumpEventQueue();
    expect(cubit.state.conversations, isEmpty);
    expect(cubit.state.loading, isFalse);
  });

  test('rename · delete · deleteAll 은 저장소로 넘긴다', () async {
    when(() => history.rename(any(), any())).thenAnswer((_) async {});
    when(() => history.delete(any())).thenAnswer((_) async {});
    when(history.deleteAll).thenAnswer((_) async => 3);
    final cubit = ChatHistoryCubit(history);
    addTearDown(cubit.close);

    expect(await cubit.rename('a', '새 이름'), isTrue);
    expect(await cubit.delete('b'), isTrue);
    expect(await cubit.deleteAll(), isTrue);

    verify(() => history.rename('a', '새 이름')).called(1);
    verify(() => history.delete('b')).called(1);
    verify(history.deleteAll).called(1);
  });

  test('목록 스트림이 던지면 loading false · failed', () async {
    final cubit = ChatHistoryCubit(history);
    addTearDown(cubit.close);

    feed.addError(StateError('db'));
    await pumpEventQueue();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.failed, isTrue);
  });

  test('rename · delete · deleteAll 이 던지면 false 를 돌려준다(던지지 않는다)', () async {
    when(() => history.rename(any(), any())).thenThrow(StateError('db'));
    when(
      () => history.delete(any()),
    ).thenAnswer((_) async => throw StateError('db'));
    when(history.deleteAll).thenAnswer((_) async => throw StateError('db'));
    final cubit = ChatHistoryCubit(history);
    addTearDown(cubit.close);

    expect(await cubit.rename('a', '새 이름'), isFalse);
    expect(await cubit.delete('b'), isFalse);
    expect(await cubit.deleteAll(), isFalse);
  });
}
