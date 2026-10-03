import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/app/router/app_router.dart';

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
      ..registerFactory<WalkFeedCubit>(() => WalkFeedCubit(useCase))
      ..registerFactory<WalkDetailCubit>(() => WalkDetailCubit(useCase))
      ..registerFactory<WalkEditCubit>(() => WalkEditCubit(useCase))
      ..registerFactory<ActiveWalkCubit>(() => ActiveWalkCubit(useCase))
      ..registerFactory<DogListCubit>(() => DogListCubit(useCase))
      ..registerFactory<DogEditCubit>(() => DogEditCubit(useCase))
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
        theme: AppTheme.light(),
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
}
