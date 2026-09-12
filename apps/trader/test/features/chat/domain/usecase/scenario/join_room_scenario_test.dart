import 'package:core/core.dart';
import 'package:daylog/features/chat/domain/chat_policy.dart';
import 'package:daylog/features/chat/domain/repository/chat_repository.dart';
import 'package:daylog/features/chat/domain/usecase/scenario/join_room_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;
  late JoinRoomScenario scenario;

  setUp(() {
    repository = _MockChatRepository();
    scenario = JoinRoomScenario(repository);
    when(
      () => repository.joinRoom(
        roomId: any(named: 'roomId'),
        nickname: any(named: 'nickname'),
      ),
    ).thenAnswer((_) async => const Ok(null));
  });

  test('앞뒤 공백을 제거한 닉네임으로 입장한다', () async {
    await scenario(roomId: 'r1', nickname: '  카르마  ');

    verify(() => repository.joinRoom(roomId: 'r1', nickname: '카르마')).called(1);
  });

  test('DB 제약과 같은 최소 길이에서 막는다', () async {
    final result = await scenario(roomId: 'r1', nickname: 'ㄱ');

    expect(result, isA<Err<void>>());
    verifyNever(
      () => repository.joinRoom(
        roomId: any(named: 'roomId'),
        nickname: any(named: 'nickname'),
      ),
    );
  });

  test('공백을 걷어내면 최소 길이에 못 미치는 값도 막는다', () async {
    // 공백으로 길이를 채운 닉네임은 DB 의 btrim 제약에도 걸린다.
    final result = await scenario(roomId: 'r1', nickname: ' ㄱ ');

    expect(result, isA<Err<void>>());
    verifyNever(
      () => repository.joinRoom(
        roomId: any(named: 'roomId'),
        nickname: any(named: 'nickname'),
      ),
    );
  });

  test('최대 길이는 허용하고 넘으면 막는다', () async {
    final exact = 'ㄱ' * ChatPolicy.nicknameMaxLength;
    expect(await scenario(roomId: 'r1', nickname: exact), isA<Ok<void>>());

    final tooLong = 'ㄱ' * (ChatPolicy.nicknameMaxLength + 1);
    expect(await scenario(roomId: 'r1', nickname: tooLong), isA<Err<void>>());
  });
}
