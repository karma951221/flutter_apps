import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/follow/domain/entity/follow_relation.dart';
import 'package:daylog/features/follow/domain/usecase/follow_use_case.dart';
import 'package:daylog/features/follow/presentation/cubit/follow_action_cubit.dart';
import 'package:daylog/features/follow/presentation/cubit/follow_action_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFollowUseCase extends Mock implements FollowUseCase {}

void main() {
  late _MockFollowUseCase useCase;

  setUp(() => useCase = _MockFollowUseCase());

  blocTest<FollowActionCubit, FollowActionState>(
    '프로필 조회 결과를 그대로 심는다',
    build: () => FollowActionCubit(useCase),
    act: (cubit) => cubit.seed(
      relation: const FollowRelation(isFollowing: true, isFollowedBy: true),
      followerCount: 12,
    ),
    expect: () => [
      isA<FollowActionState>()
          .having((s) => s.isFollowing, 'isFollowing', isTrue)
          .having((s) => s.isMutual, 'isMutual', isTrue)
          .having((s) => s.followerCount, 'followerCount', 12),
    ],
  );

  blocTest<FollowActionCubit, FollowActionState>(
    '팔로우하면 버튼과 팔로워 수가 함께 먼저 움직인다',
    build: () {
      when(
        () => useCase.followUser('u1'),
      ).thenAnswer((_) async => const Ok(null));
      return FollowActionCubit(useCase);
    },
    seed: () => const FollowActionState(followerCount: 3),
    act: (cubit) => cubit.toggle('u1'),
    expect: () => [
      isA<FollowActionState>()
          .having((s) => s.isFollowing, 'isFollowing', isTrue)
          .having((s) => s.followerCount, 'followerCount', 4)
          .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
      isA<FollowActionState>()
          .having((s) => s.isFollowing, 'isFollowing', isTrue)
          .having((s) => s.followerCount, 'followerCount', 4)
          .having((s) => s.isSubmitting, 'isSubmitting', isFalse),
    ],
  );

  blocTest<FollowActionCubit, FollowActionState>(
    '해제하면 수가 하나 줄어든다',
    build: () {
      when(
        () => useCase.unfollowUser('u1'),
      ).thenAnswer((_) async => const Ok(null));
      return FollowActionCubit(useCase);
    },
    seed: () => const FollowActionState(
      relation: FollowRelation(isFollowing: true),
      followerCount: 3,
    ),
    act: (cubit) => cubit.toggle('u1'),
    expect: () => [
      isA<FollowActionState>()
          .having((s) => s.isFollowing, 'isFollowing', isFalse)
          .having((s) => s.followerCount, 'followerCount', 2),
      isA<FollowActionState>().having(
        (s) => s.isSubmitting,
        'isSubmitting',
        isFalse,
      ),
    ],
    verify: (_) => verify(() => useCase.unfollowUser('u1')).called(1),
  );

  blocTest<FollowActionCubit, FollowActionState>(
    '실패하면 누르기 전 값으로 되돌리고 실패를 남긴다',
    build: () {
      when(
        () => useCase.followUser('u1'),
      ).thenAnswer((_) async => const Err(Failure.forbidden(message: '거부')));
      return FollowActionCubit(useCase);
    },
    seed: () => const FollowActionState(followerCount: 7),
    act: (cubit) => cubit.toggle('u1'),
    expect: () => [
      isA<FollowActionState>()
          .having((s) => s.isFollowing, 'isFollowing', isTrue)
          .having((s) => s.followerCount, 'followerCount', 8),
      isA<FollowActionState>()
          .having((s) => s.isFollowing, 'isFollowing', isFalse)
          .having((s) => s.followerCount, 'followerCount', 7)
          .having((s) => s.failure, 'failure', isA<ForbiddenFailure>()),
    ],
  );

  test('진행 중에는 다시 누르지 않는다', () async {
    when(
      () => useCase.followUser('u1'),
    ).thenAnswer((_) async => const Ok(null));
    final cubit = FollowActionCubit(useCase);
    addTearDown(cubit.close);

    final first = cubit.toggle('u1');
    final second = await cubit.toggle('u1');
    await first;

    expect(second, isFalse);
    verify(() => useCase.followUser('u1')).called(1);
  });

  test('수는 0 아래로 내려가지 않는다', () async {
    when(
      () => useCase.unfollowUser('u1'),
    ).thenAnswer((_) async => const Ok(null));
    final cubit = FollowActionCubit(useCase)
      ..seed(
        relation: const FollowRelation(isFollowing: true),
        followerCount: 0,
      );
    addTearDown(cubit.close);

    await cubit.toggle('u1');

    expect(cubit.state.followerCount, 0);
  });
}
