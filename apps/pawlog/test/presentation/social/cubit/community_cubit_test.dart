import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/core/supabase/social_availability.dart';
import 'package:pawlog/domain/social/entity/auth_session.dart';
import 'package:pawlog/domain/social/entity/walk_post.dart';
import 'package:pawlog/presentation/social/cubit/community_cubit.dart';
import 'package:pawlog/presentation/social/cubit/community_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/mock_social_use_case.dart';
import '../../../support/social_fakes.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSocialUseCase useCase;
  late StreamController<AuthSession?> sessions;
  late SocialAvailability available;
  AuthSession? current;

  const networkError = Failure.network();
  final p1 = walkPost('p1');
  final p2 = walkPost('p2', likedByMe: true);
  final p3 = walkPost('p3');

  setUp(() {
    useCase = MockSocialUseCase();
    sessions = StreamController<AuthSession?>.broadcast();
    available = SocialAvailability.available(_MockSupabaseClient());
    current = null;
    when(() => useCase.sessions).thenAnswer((_) => sessions.stream);
    when(() => useCase.currentSession).thenAnswer((_) => current);
    when(() => useCase.fetchCommunityPage()).thenAnswer(
      (_) async => Ok(CursorPage(items: [p1, p2], nextCursor: 'c1')),
    );
    when(
      () => useCase.fetchCommunityPage(after: 'c1'),
    ).thenAnswer((_) async => Ok(CursorPage(items: [p3])));
  });
  tearDown(() => sessions.close());

  CommunityCubit build({SocialAvailability? social}) =>
      CommunityCubit(useCase, social ?? available);

  CommunityLoaded loadedOf(CommunityCubit cubit) =>
      cubit.state as CommunityLoaded;

  group('start', () {
    blocTest<CommunityCubit, CommunityState>(
      '첫 페이지를 읽는다',
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => [
        const CommunityState.loading(isSignedIn: false),
        CommunityState.loaded(
          posts: [p1, p2],
          nextCursor: 'c1',
          isSignedIn: false,
        ),
      ],
    );

    blocTest<CommunityCubit, CommunityState>(
      '로그인해 있으면 isSignedIn',
      setUp: () => current = alice,
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => [
        const CommunityState.loading(isSignedIn: true),
        CommunityState.loaded(
          posts: [p1, p2],
          nextCursor: 'c1',
          isSignedIn: true,
        ),
      ],
    );

    blocTest<CommunityCubit, CommunityState>(
      '실패하면 failure, retry 로 다시 읽는다',
      setUp: () => when(
        () => useCase.fetchCommunityPage(),
      ).thenAnswer((_) async => const Err(networkError)),
      build: build,
      act: (cubit) async {
        await cubit.start();
        when(
          () => useCase.fetchCommunityPage(),
        ).thenAnswer((_) async => Ok(CursorPage(items: [p1])));
        await cubit.retry();
      },
      expect: () => [
        const CommunityState.loading(isSignedIn: false),
        const CommunityState.failure(networkError, isSignedIn: false),
        const CommunityState.loading(isSignedIn: false),
        CommunityState.loaded(posts: [p1], isSignedIn: false),
      ],
    );

    blocTest<CommunityCubit, CommunityState>(
      'Supabase 를 쓸 수 없으면 unavailable 이고 서버에 묻지 않는다',
      build: () => build(social: const SocialAvailability.unavailable()),
      act: (cubit) => cubit.start(),
      expect: () => [const CommunityState.unavailable()],
      verify: (_) {
        verifyNever(
          () => useCase.fetchCommunityPage(after: any(named: 'after')),
        );
        verifyNever(() => useCase.sessions);
      },
    );
  });

  group('loadMore', () {
    blocTest<CommunityCubit, CommunityState>(
      '다음 페이지를 이어 붙이고 끝이면 nextCursor 가 null',
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.loadMore();
      },
      skip: 2,
      expect: () => [
        CommunityState.loaded(
          posts: [p1, p2],
          nextCursor: 'c1',
          isSignedIn: false,
          isLoadingMore: true,
        ),
        CommunityState.loaded(posts: [p1, p2, p3], isSignedIn: false),
      ],
    );

    blocTest<CommunityCubit, CommunityState>(
      '읽는 중이거나 더 없으면 다시 읽지 않는다',
      build: build,
      act: (cubit) async {
        await cubit.start();
        final first = cubit.loadMore();
        await cubit.loadMore();
        await first;
        await cubit.loadMore();
      },
      verify: (_) {
        verify(() => useCase.fetchCommunityPage(after: 'c1')).called(1);
      },
    );

    blocTest<CommunityCubit, CommunityState>(
      '실패하면 목록을 두고 failure 를 싣는다',
      setUp: () => when(
        () => useCase.fetchCommunityPage(after: 'c1'),
      ).thenAnswer((_) async => const Err(networkError)),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.loadMore();
      },
      skip: 3,
      expect: () => [
        CommunityState.loaded(
          posts: [p1, p2],
          nextCursor: 'c1',
          isSignedIn: false,
          failure: networkError,
        ),
      ],
    );
  });

  group('refresh', () {
    blocTest<CommunityCubit, CommunityState>(
      '목록을 둔 채 첫 페이지로 바꾼다',
      build: build,
      act: (cubit) async {
        await cubit.start();
        when(
          () => useCase.fetchCommunityPage(),
        ).thenAnswer((_) async => Ok(CursorPage(items: [p3])));
        await cubit.refresh();
      },
      skip: 2,
      expect: () => [
        CommunityState.loaded(posts: [p3], isSignedIn: false),
      ],
    );

    blocTest<CommunityCubit, CommunityState>(
      '실패하면 목록을 두고 failure 를 싣는다',
      build: build,
      act: (cubit) async {
        await cubit.start();
        when(
          () => useCase.fetchCommunityPage(),
        ).thenAnswer((_) async => const Err(networkError));
        await cubit.refresh();
      },
      skip: 2,
      expect: () => [
        CommunityState.loaded(
          posts: [p1, p2],
          nextCursor: 'c1',
          isSignedIn: false,
          failure: networkError,
        ),
      ],
    );

    test('새로고침 중에 받은 이전 더 읽기 결과는 버린다', () async {
      final more = Completer<Result<CursorPage<WalkPost>>>();
      when(
        () => useCase.fetchCommunityPage(after: 'c1'),
      ).thenAnswer((_) => more.future);
      final cubit = build();
      await cubit.start();

      final loading = cubit.loadMore();
      when(
        () => useCase.fetchCommunityPage(),
      ).thenAnswer((_) async => Ok(CursorPage(items: [p3])));
      await cubit.refresh();
      more.complete(Ok(CursorPage(items: [walkPost('old')])));
      await loading;

      expect(loadedOf(cubit).posts, [p3]);
      expect(loadedOf(cubit).isLoadingMore, isFalse);
      await cubit.close();
    });
  });

  group('세션', () {
    test('로그인하면 isSignedIn 을 켜고 목록을 다시 읽는다', () async {
      final cubit = build();
      await cubit.start();
      current = alice;

      sessions.add(alice);
      await pumpEventQueue();

      expect(loadedOf(cubit).isSignedIn, isTrue);
      verify(() => useCase.fetchCommunityPage()).called(2);
      await cubit.close();
    });

    test('같은 사용자의 세션이 다시 오면(프로필 읽기 뒤) 다시 읽지 않는다', () async {
      current = alice;
      final cubit = build();
      await cubit.start();

      sessions
        ..add(const AuthSession(userId: 'u1', nickname: ''))
        ..add(alice);
      await pumpEventQueue();

      verify(() => useCase.fetchCommunityPage()).called(1);
      await cubit.close();
    });

    test('로그아웃하면 isSignedIn 을 끄고 다시 읽는다', () async {
      current = alice;
      final cubit = build();
      await cubit.start();
      current = null;

      sessions.add(null);
      await pumpEventQueue();

      expect(loadedOf(cubit).isSignedIn, isFalse);
      verify(() => useCase.fetchCommunityPage()).called(2);
      await cubit.close();
    });

    test('signOut 은 use case 에 맡긴다', () async {
      when(() => useCase.signOut()).thenAnswer((_) async => const Ok(null));
      final cubit = build();

      expect(await cubit.signOut(), isA<Ok<void>>());
      verify(() => useCase.signOut()).called(1);
      await cubit.close();
    });
  });

  group('toggleLike', () {
    test('누르면 바로 하트와 수가 바뀐다', () async {
      current = alice;
      final like = Completer<Result<void>>();
      when(() => useCase.likePost('p1')).thenAnswer((_) => like.future);
      final cubit = build();
      await cubit.start();

      final pending = cubit.toggleLike('p1');
      expect(loadedOf(cubit).posts.first.likedByMe, isTrue);
      expect(loadedOf(cubit).posts.first.likeCount, 4);

      like.complete(const Ok(null));
      expect(await pending, isA<Ok<void>>());
      expect(loadedOf(cubit).posts.first.likedByMe, isTrue);
      await cubit.close();
    });

    test('누른 하트를 다시 누르면 좋아요를 취소한다', () async {
      current = alice;
      when(
        () => useCase.unlikePost('p2'),
      ).thenAnswer((_) async => const Ok(null));
      final cubit = build();
      await cubit.start();

      await cubit.toggleLike('p2');

      expect(loadedOf(cubit).posts[1].likedByMe, isFalse);
      expect(loadedOf(cubit).posts[1].likeCount, 2);
      verify(() => useCase.unlikePost('p2')).called(1);
      await cubit.close();
    });

    test('실패하면 되돌리고 실패를 돌려준다', () async {
      current = alice;
      when(
        () => useCase.likePost('p1'),
      ).thenAnswer((_) async => const Err(networkError));
      final cubit = build();
      await cubit.start();

      final result = await cubit.toggleLike('p1');

      expect(result, const Err<void>(networkError));
      expect(loadedOf(cubit).posts.first, p1);
      await cubit.close();
    });

    test('로그인하지 않았으면 바꾸지 않고 authenticationRequired', () async {
      final cubit = build();
      await cubit.start();

      final result = await cubit.toggleLike('p1');

      expect(
        result,
        isA<Err<void>>().having(
          (e) => e.failure.failureCode,
          'failureCode',
          FailureCode.authenticationRequired,
        ),
      );
      expect(loadedOf(cubit).posts.first, p1);
      verifyNever(() => useCase.likePost(any()));
      await cubit.close();
    });

    test('보내는 중에 다시 누르면 무시한다', () async {
      current = alice;
      final like = Completer<Result<void>>();
      when(() => useCase.likePost('p1')).thenAnswer((_) => like.future);
      final cubit = build();
      await cubit.start();

      final first = cubit.toggleLike('p1');
      await cubit.toggleLike('p1');
      like.complete(const Ok(null));
      await first;

      expect(loadedOf(cubit).posts.first.likedByMe, isTrue);
      verify(() => useCase.likePost('p1')).called(1);
      verifyNever(() => useCase.unlikePost(any()));
      await cubit.close();
    });
  });
}
