import 'package:core/core.dart';
import 'package:feature_reaction/feature_reaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReactionRepository extends Mock implements ReactionRepository {}

void main() {
  late _MockReactionRepository repository;
  late ToggleReactionScenario scenario;

  const target = ReactionTarget.post('post-1');

  setUpAll(() {
    registerFallbackValue(const ReactionTarget.post('_'));
    registerFallbackValue(ReactionType.like);
  });

  setUp(() {
    repository = _MockReactionRepository();
    scenario = ToggleReactionScenario(repository);
  });

  test('새 감정은 setReaction 을 부르고 다음 상태를 돌려준다', () async {
    when(
      () => repository.setReaction(any(), any()),
    ).thenAnswer((_) async => const Ok(null));

    final result = await scenario(
      target: target,
      tapped: ReactionType.like,
      current: const ReactionSummary(),
    );

    verify(() => repository.setReaction(target, ReactionType.like)).called(1);
    verifyNever(() => repository.clearReaction(any()));
    expect((result as Ok).value.mine, ReactionType.like);
  });

  test('같은 감정을 다시 누르면 clearReaction 을 부른다', () async {
    when(
      () => repository.clearReaction(any()),
    ).thenAnswer((_) async => const Ok(null));

    final result = await scenario(
      target: target,
      tapped: ReactionType.like,
      current: const ReactionSummary(
        counts: {ReactionType.like: 1},
        mine: ReactionType.like,
      ),
    );

    verify(() => repository.clearReaction(target)).called(1);
    verifyNever(() => repository.setReaction(any(), any()));
    expect((result as Ok).value.mine, isNull);
  });

  test('전환은 삭제 없이 setReaction 한 번이다', () async {
    when(
      () => repository.setReaction(any(), any()),
    ).thenAnswer((_) async => const Ok(null));

    await scenario(
      target: target,
      tapped: ReactionType.dislike,
      current: const ReactionSummary(
        counts: {ReactionType.like: 1},
        mine: ReactionType.like,
      ),
    );

    verify(
      () => repository.setReaction(target, ReactionType.dislike),
    ).called(1);
    verifyNever(() => repository.clearReaction(any()));
  });

  test('실패하면 Err 를 그대로 올린다 (화면이 이전 상태로 되돌린다)', () async {
    when(
      () => repository.setReaction(any(), any()),
    ).thenAnswer((_) async => const Err(Failure.network()));

    final result = await scenario(
      target: target,
      tapped: ReactionType.like,
      current: const ReactionSummary(),
    );

    expect(result, isA<Err<ReactionSummary>>());
  });
}
