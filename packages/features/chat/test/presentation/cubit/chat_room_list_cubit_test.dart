import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_chat/feature_chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatUseCase extends Mock implements ChatUseCase {}

ChatRoomSummary _room(String id, {int unread = 0}) => ChatRoomSummary(
  id: id,
  title: '방 $id',
  myNickname: '나',
  lastReadAt: DateTime.utc(2026, 8, 28),
  unreadCount: unread,
);

void main() {
  late _MockChatUseCase useCase;

  setUp(() => useCase = _MockChatUseCase());

  blocTest<ChatRoomListCubit, ChatRoomListState>(
    '조회에 성공하면 목록을 담는다',
    build: () {
      when(
        useCase.getMyRooms,
      ).thenAnswer((_) async => Ok([_room('a'), _room('b')]));
      return ChatRoomListCubit(useCase);
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ChatRoomListStatus.loaded);
      expect(cubit.state.items.length, 2);
    },
  );

  blocTest<ChatRoomListCubit, ChatRoomListState>(
    '조회에 실패하면 failure 를 담는다',
    build: () {
      when(
        useCase.getMyRooms,
      ).thenAnswer((_) async => const Err(Failure.network()));
      return ChatRoomListCubit(useCase);
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, ChatRoomListStatus.failure);
      expect(cubit.state.failure, isA<NetworkFailure>());
    },
  );

  test('안읽음 합계가 탭 배지의 근거다', () async {
    when(useCase.getMyRooms).thenAnswer(
      (_) async => Ok([_room('a', unread: 2), _room('b', unread: 3)]),
    );
    final cubit = ChatRoomListCubit(useCase);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.totalUnread, 5);
  });

  blocTest<ChatRoomListCubit, ChatRoomListState>(
    '방을 읽고 나오면 그 줄의 안읽음만 0 이 된다',
    build: () {
      when(useCase.getMyRooms).thenAnswer(
        (_) async => Ok([_room('a', unread: 2), _room('b', unread: 3)]),
      );
      return ChatRoomListCubit(useCase);
    },
    act: (cubit) async {
      await cubit.load();
      cubit.markRoomRead('a');
    },
    verify: (cubit) {
      expect(cubit.state.items.first.unreadCount, 0);
      expect(cubit.state.items.last.unreadCount, 3);
      // 목록을 다시 읽지 않는다 — 읽으면 스크롤 위치가 사라진다.
      verify(useCase.getMyRooms).called(1);
    },
  );

  blocTest<ChatRoomListCubit, ChatRoomListState>(
    '이미 다 읽은 방은 아무것도 바꾸지 않는다',
    build: () {
      when(useCase.getMyRooms).thenAnswer((_) async => Ok([_room('a')]));
      return ChatRoomListCubit(useCase);
    },
    act: (cubit) async {
      await cubit.load();
      cubit.markRoomRead('a');
    },
    // load 로 한 번만 emit 된다. 불필요한 리빌드를 만들지 않는다.
    expect: () => [isA<ChatRoomListState>()],
  );

  blocTest<ChatRoomListCubit, ChatRoomListState>(
    '방에서 나오면 목록에서 걷어낸다',
    build: () {
      when(
        useCase.getMyRooms,
      ).thenAnswer((_) async => Ok([_room('a'), _room('b')]));
      return ChatRoomListCubit(useCase);
    },
    act: (cubit) async {
      await cubit.load();
      cubit.removeRoom('a');
    },
    verify: (cubit) => expect(cubit.state.items.single.id, 'b'),
  );
}
