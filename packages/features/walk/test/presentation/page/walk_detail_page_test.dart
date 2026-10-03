import 'dart:io';

import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';
import '../../support/pump_app.dart';
import '../../support/stub_tile_provider.dart';

void main() {
  late MockWalkUseCase useCase;

  final fullWalk = walk(
    dogs: [dog('d1'), dog('d2')],
    photos: const [WalkPhoto(id: 'p0', path: 'a.jpg', position: 0)],
  ).copyWith(memo: '공원을 한 바퀴 돌았다');

  setUp(() {
    useCase = MockWalkUseCase();
    when(() => useCase.getWalk('w1')).thenAnswer((_) async => Ok(fullWalk));
    when(
      () => useCase.getWalkTrack('w1'),
    ).thenAnswer((_) async => Ok([trackPoint(37.5), trackPoint(37.501)]));
    when(() => useCase.photoFile(any())).thenReturn(File('/no/such/photo.jpg'));
    getIt
      ..registerFactory<WalkDetailCubit>(() => WalkDetailCubit(useCase))
      ..registerSingleton<TileProvider>(StubTileProvider());
  });
  tearDown(getIt.reset);

  /// 지도 애니메이션이 남지 않도록 페이지를 내린다.
  Future<void> disposePage(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('지도 · 통계 · 반려견 · 메모가 보인다', (tester) async {
    await pumpApp(
      tester,
      WalkDetailPage(walkId: 'w1', onEdit: (_) async {}, onDeleted: () {}),
    );

    expect(find.byKey(const Key('walk-detail-map')), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('2026.10.03 09:00'), findsOneWidget);
    expect(find.text('1.2 km'), findsOneWidget);
    expect(find.text('30:00'), findsOneWidget);
    expect(find.text('콩이d1, 콩이d2'), findsOneWidget);
    expect(find.byKey(const Key('walk-detail-photo-0')), findsOneWidget);
    expect(find.text('공원을 한 바퀴 돌았다'), findsOneWidget);
    await disposePage(tester);
  });

  testWidgets('점이 없으면 경로 없음 안내를 보인다', (tester) async {
    when(
      () => useCase.getWalkTrack('w1'),
    ).thenAnswer((_) async => const Ok([]));
    await pumpApp(
      tester,
      WalkDetailPage(walkId: 'w1', onEdit: (_) async {}, onDeleted: () {}),
    );

    expect(find.text('기록된 경로가 없습니다'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('메모와 사진이 없으면 그 절을 생략한다', (tester) async {
    when(() => useCase.getWalk('w1')).thenAnswer((_) async => Ok(walk()));
    await pumpApp(
      tester,
      WalkDetailPage(walkId: 'w1', onEdit: (_) async {}, onDeleted: () {}),
    );

    expect(find.byKey(const Key('walk-detail-memo')), findsNothing);
    expect(find.byKey(const Key('walk-detail-photo-0')), findsNothing);
    await disposePage(tester);
  });

  testWidgets('불러오기 실패는 안내와 다시 시도를 보인다', (tester) async {
    when(() => useCase.getWalk('w1')).thenAnswer((_) async => const Ok(null));
    await pumpApp(
      tester,
      WalkDetailPage(walkId: 'w1', onEdit: (_) async {}, onDeleted: () {}),
    );

    expect(find.text('산책 기록을 찾을 수 없습니다'), findsOneWidget);
    expect(find.byKey(const Key('walk-detail-menu')), findsNothing);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    verify(() => useCase.getWalk('w1')).called(2);
  });

  testWidgets('더보기 → 삭제 → 확인하면 deleteWalk 후 onDeleted', (tester) async {
    when(
      () => useCase.deleteWalk('w1'),
    ).thenAnswer((_) async => const Ok(null));
    var deleted = 0;
    await pumpApp(
      tester,
      WalkDetailPage(
        walkId: 'w1',
        onEdit: (_) async {},
        onDeleted: () => deleted++,
      ),
    );

    await tester.tap(find.byKey(const Key('walk-detail-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('산책 기록을 삭제할까요?'), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('삭제')),
    );
    await tester.pumpAndSettle();

    verify(() => useCase.deleteWalk('w1')).called(1);
    expect(deleted, 1);
  });

  testWidgets('삭제를 취소하면 deleteWalk 를 부르지 않는다', (tester) async {
    var deleted = 0;
    await pumpApp(
      tester,
      WalkDetailPage(
        walkId: 'w1',
        onEdit: (_) async {},
        onDeleted: () => deleted++,
      ),
    );

    await tester.tap(find.byKey(const Key('walk-detail-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    verifyNever(() => useCase.deleteWalk(any()));
    expect(deleted, 0);
    await disposePage(tester);
  });

  testWidgets('삭제가 실패하면 내용을 두고 스낵바를 보인다', (tester) async {
    when(() => useCase.deleteWalk('w1')).thenAnswer(
      (_) async =>
          const Err(Failure.notFound(failureCode: FailureCode.walkNotFound)),
    );
    var deleted = 0;
    await pumpApp(
      tester,
      WalkDetailPage(
        walkId: 'w1',
        onEdit: (_) async {},
        onDeleted: () => deleted++,
      ),
    );

    await tester.tap(find.byKey(const Key('walk-detail-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('삭제')),
    );
    await tester.pumpAndSettle();

    expect(find.text('산책 기록을 찾을 수 없습니다'), findsOneWidget);
    expect(find.byKey(const Key('walk-detail-map')), findsOneWidget);
    expect(deleted, 0);
    await disposePage(tester);
  });

  testWidgets('수정 뒤 돌아오면 다시 읽는다', (tester) async {
    final ids = <String>[];
    await pumpApp(
      tester,
      WalkDetailPage(
        walkId: 'w1',
        onEdit: (id) async => ids.add(id),
        onDeleted: () {},
      ),
    );

    await tester.tap(find.byKey(const Key('walk-detail-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();

    expect(ids, ['w1']);
    verify(() => useCase.getWalk('w1')).called(2);
    await disposePage(tester);
  });
}
