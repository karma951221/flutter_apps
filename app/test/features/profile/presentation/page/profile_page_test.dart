import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/feed/domain/entity/feed_post.dart';
import 'package:daylog/features/feed/domain/usecase/feed_use_case.dart';
import 'package:daylog/features/feed/presentation/cubit/feed_cubit.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:daylog/features/post/domain/usecase/post_use_case.dart';
import 'package:daylog/features/post/presentation/cubit/post_cubit.dart';
import 'package:daylog/features/profile/domain/entity/profile.dart';
import 'package:daylog/features/profile/domain/usecase/profile_use_case.dart';
import 'package:daylog/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:daylog/features/profile/presentation/page/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileUseCase extends Mock implements ProfileUseCase {}

class _MockFeedUseCase extends Mock implements FeedUseCase {}

class _MockPostUseCase extends Mock implements PostUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

Profile _profile(String id, String nickname) => Profile(
  id: id,
  nickname: nickname,
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 9),
);

FeedPost _item(String id, String authorId, String nickname) => FeedPost(
  post: Post(
    id: id,
    authorId: authorId,
    content: '기록 $id',
    createdAt: DateTime.utc(2026, 8, 22, 9),
    updatedAt: DateTime.utc(2026, 8, 22, 9),
  ),
  author: PostAuthor(id: authorId, nickname: nickname),
);

void main() {
  late _MockProfileUseCase profileUseCase;
  late _MockFeedUseCase feedUseCase;
  late _MockAuthBloc authBloc;

  setUp(() {
    profileUseCase = _MockProfileUseCase();
    feedUseCase = _MockFeedUseCase();
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );

    getIt
      ..registerFactory<ProfileCubit>(() => ProfileCubit(profileUseCase))
      ..registerFactory<FeedCubit>(() => FeedCubit(feedUseCase))
      ..registerFactory<PostCubit>(() => PostCubit(_MockPostUseCase()));
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester, {String? userId}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: ProfilePage(userId: userId),
        ),
      ),
    );
    // 프로필 조회 → 피드 조회 순으로 이어지므로 두 번 펌프한다.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('내 프로필은 편집 버튼을 보여주고 내 게시물만 읽는다', (tester) async {
    when(
      profileUseCase.getMyProfile,
    ).thenAnswer((_) async => Ok(_profile('me', '카르마')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('1', 'me', '카르마')])),
    );

    await pumpPage(tester);

    expect(find.text('프로필'), findsOneWidget);
    expect(find.text('프로필 편집'), findsOneWidget);
    expect(find.text('기록 1'), findsOneWidget);
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: 'me',
      ),
    ).called(1);
  });

  testWidgets('타인 프로필에는 편집 버튼이 없고 그 작성자의 게시물만 읽는다', (tester) async {
    when(
      () => profileUseCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile('other', '이웃')));
    when(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FeedPost>(items: [_item('2', 'other', '이웃')])),
    );

    await pumpPage(tester, userId: 'other');

    expect(find.text('사용자 프로필'), findsOneWidget);
    expect(find.text('프로필 편집'), findsNothing);
    expect(find.text('기록 2'), findsOneWidget);
    // 남의 프로필에서 내 프로필을 읽으면 화면 주인이 바뀐다.
    verifyNever(profileUseCase.getMyProfile);
    verify(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: null,
        authorId: 'other',
      ),
    ).called(1);
  });

  testWidgets('프로필 조회에 실패하면 다시 시도할 수 있다', (tester) async {
    when(
      profileUseCase.getMyProfile,
    ).thenAnswer((_) async => const Err(Failure.network()));

    await pumpPage(tester);

    expect(find.text('다시 시도'), findsOneWidget);
    // 프로필을 못 읽었으면 누구의 게시물인지도 모른다.
    verifyNever(
      () => feedUseCase.getFeedPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        authorId: any(named: 'authorId'),
      ),
    );
  });
}
