import 'package:core/core.dart';
import 'package:daylog/features/chat/domain/chat_policy.dart';
import 'package:daylog/features/chat/domain/repository/chat_repository.dart';
import 'package:daylog/features/chat/domain/usecase/scenario/send_message_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;
  late SendMessageScenario scenario;

  setUp(() {
    repository = _MockChatRepository();
    scenario = SendMessageScenario(repository);
    when(
      () => repository.sendMessage(
        id: any(named: 'id'),
        roomId: any(named: 'roomId'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) async => const Ok(null));
  });

  test('호출부가 만든 id 를 그대로 넘긴다', () async {
    // 여기서 id 를 새로 만들면 화면의 낙관적 버블과 서버 행의 id 가 갈려
    // 실시간으로 되돌아온 내 메시지가 중복으로 쌓인다.
    await scenario(id: 'msg-1', roomId: 'r1', content: '안녕');

    verify(
      () => repository.sendMessage(id: 'msg-1', roomId: 'r1', content: '안녕'),
    ).called(1);
  });

  test('앞뒤 공백을 제거한 본문으로 보낸다', () async {
    await scenario(id: 'msg-1', roomId: 'r1', content: '  안녕  ');

    verify(
      () => repository.sendMessage(id: 'msg-1', roomId: 'r1', content: '안녕'),
    ).called(1);
  });

  test('공백뿐인 본문은 보내지 않는다', () async {
    final result = await scenario(id: 'msg-1', roomId: 'r1', content: '   ');

    expect(result, isA<Err<void>>());
    verifyNever(
      () => repository.sendMessage(
        id: any(named: 'id'),
        roomId: any(named: 'roomId'),
        content: any(named: 'content'),
      ),
    );
  });

  test('DB CHECK 제약과 같은 길이에서 막고, 최대 길이는 허용한다', () async {
    final tooLong = 'ㄱ' * (ChatPolicy.messageMaxLength + 1);
    expect(
      await scenario(id: 'm', roomId: 'r1', content: tooLong),
      isA<Err<void>>(),
    );

    final exact = 'ㄱ' * ChatPolicy.messageMaxLength;
    expect(
      await scenario(id: 'm', roomId: 'r1', content: exact),
      isA<Ok<void>>(),
    );
  });
}
