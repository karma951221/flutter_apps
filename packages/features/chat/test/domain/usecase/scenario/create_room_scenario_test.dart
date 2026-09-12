import 'package:core/core.dart';
import 'package:feature_chat/feature_chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;
  late CreateRoomScenario scenario;

  final room = ChatRoom(
    id: 'r1',
    title: '방',
    createdAt: DateTime.utc(2026, 8, 28),
  );

  setUp(() {
    repository = _MockChatRepository();
    scenario = CreateRoomScenario(repository);
    when(
      () => repository.createRoom(
        title: any(named: 'title'),
        description: any(named: 'description'),
        memberLimit: any(named: 'memberLimit'),
      ),
    ).thenAnswer((_) async => Ok(room));
  });

  test('앞뒤 공백을 제거한 제목으로 저장을 요청한다', () async {
    await scenario(title: '  대화방  ', memberLimit: 10);

    verify(
      () => repository.createRoom(
        title: '대화방',
        description: null,
        memberLimit: 10,
      ),
    ).called(1);
  });

  test('공백뿐인 제목은 저장하지 않는다', () async {
    final result = await scenario(title: '   ', memberLimit: 10);

    expect(result, isA<Err<ChatRoom>>());
    verifyNever(
      () => repository.createRoom(
        title: any(named: 'title'),
        description: any(named: 'description'),
        memberLimit: any(named: 'memberLimit'),
      ),
    );
  });

  test('DB CHECK 제약과 같은 길이에서 막고, 최대 길이는 허용한다', () async {
    final tooLong = 'ㄱ' * (ChatPolicy.roomTitleMaxLength + 1);
    expect(
      await scenario(title: tooLong, memberLimit: 10),
      isA<Err<ChatRoom>>(),
    );

    final exact = 'ㄱ' * ChatPolicy.roomTitleMaxLength;
    expect(await scenario(title: exact, memberLimit: 10), isA<Ok<ChatRoom>>());
  });

  test('빈 소개는 빈 문자열이 아니라 null 로 보낸다', () async {
    await scenario(title: '방', description: '   ', memberLimit: 10);

    verify(
      () =>
          repository.createRoom(title: '방', description: null, memberLimit: 10),
    ).called(1);
  });

  test('소개도 앞뒤 공백을 제거한다', () async {
    await scenario(title: '방', description: '  소개  ', memberLimit: 10);

    verify(
      () =>
          repository.createRoom(title: '방', description: '소개', memberLimit: 10),
    ).called(1);
  });

  test('정원이 범위를 벗어나면 저장하지 않는다', () async {
    expect(
      await scenario(title: '방', memberLimit: ChatPolicy.memberLimitMin - 1),
      isA<Err<ChatRoom>>(),
    );
    expect(
      await scenario(title: '방', memberLimit: ChatPolicy.memberLimitMax + 1),
      isA<Err<ChatRoom>>(),
    );
    verifyNever(
      () => repository.createRoom(
        title: any(named: 'title'),
        description: any(named: 'description'),
        memberLimit: any(named: 'memberLimit'),
      ),
    );
  });

  test('실패는 field 를 달아 돌려준다', () async {
    final result = await scenario(title: '', memberLimit: 10);

    final failure = (result as Err<ChatRoom>).failure;
    expect(failure, isA<ValidationFailure>());
    expect((failure as ValidationFailure).field, 'title');
  });
}
