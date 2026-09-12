import 'package:core/core.dart';
import 'package:daylog/features/chat/domain/repository/chat_repository.dart';
import 'package:daylog/features/chat/domain/usecase/scenario/open_direct_room_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;
  late OpenDirectRoomScenario scenario;

  setUp(() {
    repository = _MockChatRepository();
    scenario = OpenDirectRoomScenario(repository);
  });

  test('저장소가 돌려준 방 id 를 그대로 전달한다', () async {
    when(
      () => repository.openDirectRoom('partner-1'),
    ).thenAnswer((_) async => const Ok('room-1'));

    final result = await scenario('partner-1');

    expect(result, const Ok<String>('room-1'));
  });

  test('저장소 실패를 그대로 전달한다', () async {
    const failure = Failure.server(message: 'blocked');
    when(
      () => repository.openDirectRoom('partner-1'),
    ).thenAnswer((_) async => const Err(failure));

    final result = await scenario('partner-1');

    expect(result, const Err<String>(failure));
  });
}
