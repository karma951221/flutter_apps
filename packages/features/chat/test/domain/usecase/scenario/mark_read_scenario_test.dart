import 'package:core/core.dart';
import 'package:feature_chat/feature_chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;
  late MarkReadScenario scenario;

  setUp(() {
    repository = _MockChatRepository();
    scenario = MarkReadScenario(repository);
    when(
      () => repository.markRead(
        roomId: any(named: 'roomId'),
        at: any(named: 'at'),
      ),
    ).thenAnswer((_) async => const Ok(null));
  });

  test('받은 시각을 그대로 넘긴다', () async {
    final at = DateTime.now().subtract(const Duration(minutes: 1));
    await scenario(roomId: 'r1', at: at);

    verify(() => repository.markRead(roomId: 'r1', at: at)).called(1);
  });

  test('미래 시각은 지금으로 끌어내린다', () async {
    // 기기 시계가 앞서 있으면 아직 오지 않은 메시지까지 읽은 것으로 표시되어
    // 안읽음이 영영 0 이 된다.
    final future = DateTime.now().add(const Duration(days: 1));
    await scenario(roomId: 'r1', at: future);

    final captured =
        verify(
              () => repository.markRead(
                roomId: 'r1',
                at: captureAny(named: 'at'),
              ),
            ).captured.single
            as DateTime;
    expect(captured.isBefore(future), isTrue);
  });
}
