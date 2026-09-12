import 'package:core/core.dart';
import 'package:daylog/features/chat/domain/entity/chat_room.dart';
import 'package:daylog/features/chat/domain/usecase/chat_use_case.dart';
import 'package:daylog/features/chat/presentation/cubit/chat_explore_cubit.dart';
import 'package:daylog/features/chat/presentation/cubit/chat_explore_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatUseCase extends Mock implements ChatUseCase {}

ChatRoom _room(String id) =>
    ChatRoom(id: id, title: '방 $id', createdAt: DateTime.utc(2026, 8, 28));

void main() {
  late _MockChatUseCase useCase;

  setUp(() {
    useCase = _MockChatUseCase();
    when(
      () => useCase.getOpenRooms(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage(items: [_room('a')])));
  });

  test('검색은 입력이 멎은 뒤 마지막 값 하나만 조회한다', () async {
    final cubit = ChatExploreCubit(useCase);
    addTearDown(cubit.close);

    cubit.search('가');
    cubit.search('가나');
    cubit.search('가나다');
    await Future<void>.delayed(
      ChatExploreCubit.searchDebounce + const Duration(milliseconds: 60),
    );

    verify(
      () => useCase.getOpenRooms(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        query: '가나다',
      ),
    ).called(1);
    verifyNever(
      () => useCase.getOpenRooms(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        query: '가',
      ),
    );
  });

  test('빈 검색어는 query 없이 전체를 읽는다', () async {
    final cubit = ChatExploreCubit(useCase);
    addTearDown(cubit.close);

    await cubit.load();

    verify(
      () => useCase.getOpenRooms(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        query: null,
      ),
    ).called(1);
  });

  test('더 읽기는 커서를 이어 붙인다', () async {
    when(
      () => useCase.getOpenRooms(
        limit: any(named: 'limit'),
        cursor: null,
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage(items: [_room('a')], nextCursor: 'c1')),
    );
    when(
      () => useCase.getOpenRooms(
        limit: any(named: 'limit'),
        cursor: 'c1',
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage(items: [_room('b')])));

    final cubit = ChatExploreCubit(useCase);
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.loadMore();

    expect(cubit.state.items.map((r) => r.id), ['a', 'b']);
    expect(cubit.state.canLoadMore, isFalse);
  });

  test('더 읽기에 실패해도 이미 읽은 목록과 커서를 지키다', () async {
    when(
      () => useCase.getOpenRooms(
        limit: any(named: 'limit'),
        cursor: null,
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage(items: [_room('a')], nextCursor: 'c1')),
    );
    when(
      () => useCase.getOpenRooms(
        limit: any(named: 'limit'),
        cursor: 'c1',
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => const Err(Failure.network()));

    final cubit = ChatExploreCubit(useCase);
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.loadMore();

    expect(cubit.state.items.single.id, 'a');
    expect(cubit.state.nextCursor, 'c1');
  });

  test('조회에 실패하면 failure 를 담는다', () async {
    when(
      () => useCase.getOpenRooms(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => const Err(Failure.network()));

    final cubit = ChatExploreCubit(useCase);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, ChatExploreStatus.failure);
  });
}
