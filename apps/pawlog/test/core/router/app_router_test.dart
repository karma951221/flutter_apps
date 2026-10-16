import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/core/router/app_router.dart';
import 'package:pawlog/domain/dog/entity/dog.dart';
import 'package:pawlog/domain/tracking/entity/tracker_state.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/presentation/dog/cubit/dog_edit_cubit.dart';
import 'package:pawlog/presentation/dog/cubit/dog_list_cubit.dart';
import 'package:pawlog/presentation/dog/page/dog_edit_page.dart';
import 'package:pawlog/presentation/feed/cubit/walk_feed_cubit.dart';
import 'package:pawlog/presentation/feed/page/walk_feed_page.dart';
import 'package:pawlog/presentation/stats/cubit/stats_cubit.dart';
import 'package:pawlog/presentation/stats/page/stats_page.dart';
import 'package:pawlog/presentation/tracking/cubit/active_walk_cubit.dart';
import 'package:pawlog/presentation/walk/cubit/walk_detail_cubit.dart';
import 'package:pawlog/presentation/walk/cubit/walk_edit_cubit.dart';
import 'package:pawlog/presentation/walk/page/walk_detail_page.dart';
import 'package:pawlog/presentation/walk/page/walk_edit_page.dart';

import '../../support/mock_walk_file_sharer.dart';
import '../../support/mock_walk_use_case.dart';
import '../../support/stub_tile_provider.dart';

void main() {
  late MockWalkUseCase useCase;

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
    getIt
      ..registerFactory<WalkFeedCubit>(
        () => WalkFeedCubit(useCase, const Clock()),
      )
      ..registerFactory<WalkDetailCubit>(() => WalkDetailCubit(useCase, MockWalkFileSharer()))
      ..registerFactory<WalkEditCubit>(() => WalkEditCubit(useCase))
      ..registerFactory<ActiveWalkCubit>(
        () => ActiveWalkCubit(useCase, const Clock()),
      )
      ..registerFactory<DogListCubit>(() => DogListCubit(useCase))
      ..registerFactory<DogEditCubit>(() => DogEditCubit(useCase))
      ..registerFactory<StatsCubit>(() => StatsCubit(useCase, const Clock()))
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
}
