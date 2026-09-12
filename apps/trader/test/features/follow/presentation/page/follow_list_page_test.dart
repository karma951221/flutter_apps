import 'package:core/core.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/follow/domain/entity/follow_user.dart';
import 'package:daylog/features/follow/domain/usecase/follow_use_case.dart';
import 'package:daylog/features/follow/presentation/cubit/follow_list_cubit.dart';
import 'package:daylog/features/follow/presentation/cubit/follow_list_state.dart';
import 'package:daylog/features/follow/presentation/page/follow_list_page.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFollowUseCase extends Mock implements FollowUseCase {}

FollowUser _user(String id, String nickname) => FollowUser(
  id: id,
  nickname: nickname,
  followedAt: DateTime.utc(2026, 8, 30, 9),
);

void main() {
  late _MockFollowUseCase useCase;

  setUp(() {
    useCase = _MockFollowUseCase();
    getIt.registerFactory<FollowListCubit>(() => FollowListCubit(useCase));
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(
    WidgetTester tester, {
    FollowDirection direction = FollowDirection.followers,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다.
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FollowListPage(userId: 'u1', direction: direction),
      ),
    );
    await tester.pump();
  }

  testWidgets('팔로워 목록은 사람들을 그린다', (tester) async {
    when(
      () => useCase.getFollowers(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FollowUser>(items: [_user('a', '카르마')])),
    );

    await pumpPage(tester);

    expect(find.text('팔로워'), findsOneWidget);
    expect(find.text('카르마'), findsOneWidget);
  });

  testWidgets('방향에 따라 제목과 빈 안내가 달라진다', (tester) async {
    when(
      () => useCase.getFollowings(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FollowUser>(items: [])));

    await pumpPage(tester, direction: FollowDirection.followings);

    expect(find.text('팔로잉'), findsOneWidget);
    expect(find.text('아직 팔로우한 사람이 없습니다'), findsOneWidget);
  });

  testWidgets('비어 있으면 방향에 맞는 안내를 보여준다', (tester) async {
    when(
      () => useCase.getFollowers(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => const Ok(CursorPage<FollowUser>(items: [])));

    await pumpPage(tester);

    expect(find.text('아직 팔로워가 없습니다'), findsOneWidget);
  });

  testWidgets('실패하면 다시 시도할 수 있다', (tester) async {
    when(
      () => useCase.getFollowers(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => const Err(Failure.network(message: '연결 실패')));

    await pumpPage(tester);

    expect(find.text('다시 시도'), findsOneWidget);

    when(
      () => useCase.getFollowers(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => Ok(CursorPage<FollowUser>(items: [_user('a', '카르마')])),
    );
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    await tester.pump();

    expect(find.text('카르마'), findsOneWidget);
  });
}
