import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/core/router/app_router.dart';
import 'package:pawlog/core/router/dogs_redirect.dart';
import 'package:pawlog/domain/backup/entity/backup_import_result.dart';
import 'package:pawlog/domain/dog/entity/dog.dart';
import 'package:pawlog/domain/tracking/entity/tracker_state.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/presentation/dog/cubit/dog_edit_cubit.dart';
import 'package:pawlog/presentation/dog/cubit/dog_list_cubit.dart';
import 'package:pawlog/presentation/dog/page/dog_edit_page.dart';
import 'package:pawlog/presentation/feed/cubit/walk_feed_cubit.dart';
import 'package:pawlog/presentation/feed/page/walk_feed_page.dart';
import 'package:pawlog/core/supabase/social_availability.dart';
import 'package:pawlog/presentation/social/cubit/auth_cubit.dart';
import 'package:pawlog/presentation/social/cubit/community_cubit.dart';
import 'package:pawlog/presentation/social/page/community_page.dart';
import 'package:pawlog/presentation/social/page/sign_in_page.dart';
import 'package:pawlog/presentation/stats/cubit/stats_cubit.dart';
import 'package:pawlog/presentation/stats/page/stats_page.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';
import 'package:pawlog/presentation/tracking/cubit/active_walk_cubit.dart';
import 'package:pawlog/presentation/walk/cubit/walk_detail_cubit.dart';
import 'package:pawlog/presentation/walk/cubit/walk_edit_cubit.dart';
import 'package:pawlog/presentation/walk/cubit/walk_share_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlog/presentation/walk/page/walk_detail_page.dart';
import 'package:pawlog/presentation/walk/page/walk_edit_page.dart';

import '../../support/mock_social_use_case.dart';
import '../../support/mock_walk_file_sharer.dart';
import '../../support/mock_walk_use_case.dart';
import '../../support/social_fakes.dart';
import '../../support/stub_tile_provider.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockWalkUseCase useCase;
  late MockSocialUseCase social;

  final now = DateTime(2026, 10, 3, 9);
  final dog = Dog(id: 'd1', name: '콩이', createdAt: now, updatedAt: now);
  final walk = Walk(
    id: 'w1',
    startedAt: now,
    endedAt: now.add(const Duration(minutes: 30)),
    duration: const Duration(minutes: 30),
    distanceMeters: 1200,
    dogs: [dog],
    photos: const [],
    previewPoints: const [],
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    useCase = MockWalkUseCase();
    when(
      () => useCase.watchWalks(),
    ).thenAnswer((_) => Stream.value(const Ok([])));
    registerFallbackValue(DateTime(2000));
    when(
      () => useCase.watchRecentWalks(
        limit: any(named: 'limit'),
        favoritesOnly: any(named: 'favoritesOnly'),
      ),
    ).thenAnswer((_) => Stream.value(const Ok([])));
    when(
      () => useCase.watchWalksSince(any()),
    ).thenAnswer((_) => Stream.value(const Ok([])));
    when(() => useCase.trackerState).thenReturn(const TrackerState.idle());
    when(() => useCase.trackerStates).thenAnswer((_) => const Stream.empty());
    when(() => useCase.getWalk('w1')).thenAnswer((_) async => Ok(walk));
    when(
      () => useCase.getWalkTrack('w1'),
    ).thenAnswer((_) async => const Ok([]));
    when(() => useCase.watchDogs()).thenAnswer((_) => Stream.value(Ok([dog])));
    when(() => useCase.getDogs()).thenAnswer((_) async => Ok([dog]));
    when(() => useCase.getDog(any())).thenAnswer((_) async => Ok(dog));
    when(() => useCase.photoFile(any())).thenReturn(File('/no/such/photo.jpg'));
    when(() => useCase.removePhoto(any())).thenAnswer((_) async {});
    social = MockSocialUseCase();
    final availability = SocialAvailability.available(_MockSupabaseClient());
    when(() => social.sessions).thenAnswer((_) => const Stream.empty());
    when(() => social.currentSession).thenReturn(null);
    when(
      () => social.isWalkShared(any()),
    ).thenAnswer((_) async => const Ok(false));
    when(
      () => social.fetchCommunityPage(),
    ).thenAnswer((_) async => Ok(CursorPage(items: [walkPost('p1')])));
    getIt
      ..registerFactory<WalkFeedCubit>(
        () => WalkFeedCubit(useCase, const Clock()),
      )
      ..registerFactory<WalkDetailCubit>(
        () => WalkDetailCubit(useCase, MockWalkFileSharer()),
      )
      ..registerFactory<WalkEditCubit>(() => WalkEditCubit(useCase))
      ..registerFactory<ActiveWalkCubit>(
        () => ActiveWalkCubit(useCase, const Clock()),
      )
      ..registerFactory<DogListCubit>(() => DogListCubit(useCase))
      ..registerFactory<DogEditCubit>(() => DogEditCubit(useCase))
      ..registerFactory<StatsCubit>(() => StatsCubit(useCase, const Clock()))
      ..registerFactory<AuthCubit>(() => AuthCubit(social))
      ..registerFactory<CommunityCubit>(
        () => CommunityCubit(social, availability),
      )
      ..registerFactory<WalkShareCubit>(
        () => WalkShareCubit(social, availability),
      )
      ..registerSingleton<TileProvider>(StubTileProvider());
  });
  tearDown(getIt.reset);

  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    bool hasDogs = true,
  }) async {
    final router = createRouter(hasDogs: hasDogs);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: PawlogTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  String path(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  /// 지도 애니메이션 · 타이머가 남지 않도록 화면을 내린다.
  Future<void> dispose(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('/walks/:id 로 가면 상세 화면이 뜬다', (tester) async {
    final router = await pumpRouter(tester);

    router.go('/walks/w1');
    await tester.pumpAndSettle();

    expect(find.byType(WalkDetailPage), findsOneWidget);
    expect(path(router), '/walks/w1');
    await dispose(tester);
  });

  testWidgets('/walks/:id/edit 로 가면 수정 화면이 뜬다', (tester) async {
    final router = await pumpRouter(tester);

    router.go('/walks/w1/edit');
    await tester.pumpAndSettle();

    expect(find.byType(WalkEditPage), findsOneWidget);
    expect(path(router), '/walks/w1/edit');
    await dispose(tester);
  });

  testWidgets('/walks 는 피드로 돌아간다', (tester) async {
    final router = await pumpRouter(tester);

    router.go('/walks');
    await tester.pumpAndSettle();

    expect(find.byType(WalkFeedPage), findsOneWidget);
    expect(path(router), '/');
    await dispose(tester);
  });

  testWidgets('반려견이 없으면 처음에 /dogs/new 로 간다', (tester) async {
    final router = await pumpRouter(tester, hasDogs: false);

    expect(find.byType(DogEditPage), findsOneWidget);
    expect(path(router), '/dogs/new');
    await dispose(tester);
  });

  testWidgets('첫 등록을 마치면 반려견 목록이 아니라 피드로 간다', (tester) async {
    final router = await pumpRouter(tester, hasDogs: false);

    tester.widget<DogEditPage>(find.byType(DogEditPage)).onDone();
    await tester.pumpAndSettle();

    expect(path(router), '/');
    expect(find.byType(WalkFeedPage), findsOneWidget);
    await dispose(tester);
  });

  testWidgets('목록에서 추가를 마치면 목록으로 돌아간다', (tester) async {
    final router = await pumpRouter(tester);
    router.go('/dogs');
    await tester.pumpAndSettle();
    unawaited(router.push('/dogs/new'));
    await tester.pumpAndSettle();

    tester.widget<DogEditPage>(find.byType(DogEditPage)).onDone();
    await tester.pumpAndSettle();

    expect(path(router), '/dogs');
    await dispose(tester);
  });

  testWidgets('/stats 로 가면 통계 화면이 뜬다', (tester) async {
    final router = await pumpRouter(tester);

    router.go('/stats');
    await tester.pumpAndSettle();

    expect(find.byType(StatsPage), findsOneWidget);
    expect(path(router), '/stats');
    await dispose(tester);
  });

  testWidgets('반려견이 없으면 /stats 도 /dogs/new 로 간다', (tester) async {
    final router = await pumpRouter(tester, hasDogs: false);

    router.go('/stats');
    await tester.pumpAndSettle();

    expect(find.byType(DogEditPage), findsOneWidget);
    expect(path(router), '/dogs/new');
    await dispose(tester);
  });

  group('첫 실행 백업 가져오기', () {
    testWidgets('반려견이 없을 때만 등록 화면에 가져오기 버튼이 보인다', (tester) async {
      final router = await pumpRouter(tester);
      router.go('/dogs');
      await tester.pumpAndSettle();
      unawaited(router.push('/dogs/new'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dog-edit-import-backup')), findsNothing);
      await dispose(tester);
    });

    testWidgets('/dogs/new 에서 가져오면 redirect 가 풀리고 피드로 간다', (tester) async {
      when(
        () => useCase.importBackup(),
      ).thenAnswer((_) async => const BackupImportResult.imported(1, 1));
      final router = await pumpRouter(tester, hasDogs: false);
      expect(path(router), '/dogs/new');

      await tester.tap(find.byKey(const Key('dog-edit-import-backup')));
      await tester.pumpAndSettle();

      expect(path(router), '/');
      expect(find.byType(WalkFeedPage), findsOneWidget);

      // redirect 가 풀렸다 — 다른 화면으로 가도 등록 화면으로 튕기지 않는다.
      router.go('/stats');
      await tester.pumpAndSettle();
      expect(path(router), '/stats');
      await dispose(tester);
    });
  });

  group('로그인 · 모두의 산책', () {
    testWidgets('/sign-in?from= 으로 열고 로그인하면 from 으로 간다', (tester) async {
      final router = await pumpRouter(tester);

      router.go(PawlogPaths.signInFrom('/stats'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInPage), findsOneWidget);

      tester.widget<SignInPage>(find.byType(SignInPage)).onSignedIn();
      await tester.pumpAndSettle();

      expect(path(router), '/stats');
      await dispose(tester);
    });

    testWidgets('push 로 열었으면 로그인 뒤 원래 화면으로 pop 한다', (tester) async {
      final router = await pumpRouter(tester);
      router.go('/stats');
      await tester.pumpAndSettle();
      unawaited(router.push(PawlogPaths.signInFrom('/stats')));
      await tester.pumpAndSettle();

      tester.widget<SignInPage>(find.byType(SignInPage)).onSignedIn();
      await tester.pumpAndSettle();

      expect(path(router), '/stats');
      expect(router.canPop(), isFalse);
      await dispose(tester);
    });

    testWidgets('from 이 앱 안 경로가 아니면 모두의 산책으로 간다', (tester) async {
      final router = await pumpRouter(tester);

      router.go('/sign-in?from=https://example.com');
      await tester.pumpAndSettle();
      tester.widget<SignInPage>(find.byType(SignInPage)).onSignedIn();
      await tester.pumpAndSettle();

      expect(path(router), '/community');
      expect(find.byType(CommunityPage), findsOneWidget);
      await dispose(tester);
    });

    testWidgets('반려견이 없어도 /sign-in 과 /community 는 열린다', (tester) async {
      final router = await pumpRouter(tester, hasDogs: false);

      router.go('/sign-in');
      await tester.pumpAndSettle();
      expect(path(router), '/sign-in');
      expect(find.byType(SignInPage), findsOneWidget);

      router.go('/community');
      await tester.pumpAndSettle();
      expect(path(router), '/community');
      await dispose(tester);
    });
    testWidgets('피드의 사람들 아이콘으로 모두의 산책을 연다', (tester) async {
      final router = await pumpRouter(tester);

      await tester.tap(find.byKey(const Key('walk-feed-community')));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/community');
      expect(find.byType(CommunityPage), findsOneWidget);
      expect(router.canPop(), isTrue);
      await dispose(tester);
    });

    testWidgets('로그아웃 상태로 하트를 누르면 from=/community 로 로그인을 연다', (tester) async {
      final router = await pumpRouter(tester);
      router.go('/community');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('community-like-p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('community-like-p1')));
      await tester.pumpAndSettle();

      final uri = router.state.uri;
      expect(uri.path, '/sign-in');
      expect(uri.queryParameters['from'], '/community');
      expect(router.canPop(), isTrue);
      await dispose(tester);
    });

    testWidgets('로그아웃 상태로 상세에서 공유하면 from=/walks/w1 로 로그인을 연다', (tester) async {
      final router = await pumpRouter(tester);
      router.go('/walks/w1');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('walk-detail-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('walk-detail-share')));
      await tester.pumpAndSettle();

      final uri = router.state.uri;
      expect(uri.path, '/sign-in');
      expect(uri.queryParameters['from'], '/walks/w1');
      await dispose(tester);
    });
  });
}
