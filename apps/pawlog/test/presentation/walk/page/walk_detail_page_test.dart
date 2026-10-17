import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/core/supabase/social_availability.dart';
import 'package:pawlog/domain/social/entity/auth_session.dart';
import 'package:pawlog/domain/walk/entity/walk_photo.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';
import 'package:pawlog/presentation/walk/cubit/walk_detail_cubit.dart';
import 'package:pawlog/presentation/walk/cubit/walk_share_cubit.dart';
import 'package:pawlog/presentation/walk/page/walk_detail_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fakes.dart';
import '../../../support/mock_social_use_case.dart';
import '../../../support/mock_walk_file_sharer.dart';
import '../../../support/mock_walk_use_case.dart';
import '../../../support/pump_app.dart';
import '../../../support/social_fakes.dart';
import '../../../support/stub_tile_provider.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockWalkUseCase useCase;
  late MockWalkFileSharer sharer;
  late MockSocialUseCase social;
  late SocialAvailability availability;
  AuthSession? session;

  final fullWalk = walk(
    dogs: [dog('d1'), dog('d2')],
    photos: const [WalkPhoto(id: 'p0', path: 'a.jpg', position: 0)],
  ).copyWith(memo: '공원을 한 바퀴 돌았다');

  setUp(() {
    useCase = MockWalkUseCase();
    sharer = MockWalkFileSharer();
    when(() => useCase.getWalk('w1')).thenAnswer((_) async => Ok(fullWalk));
    when(
      () => useCase.getWalkTrack('w1'),
    ).thenAnswer((_) async => Ok([trackPoint(37.5), trackPoint(37.501)]));
    when(() => useCase.photoFile(any())).thenReturn(File('/no/such/photo.jpg'));
    social = MockSocialUseCase();
    availability = SocialAvailability.available(_MockSupabaseClient());
    session = alice;
    when(() => social.sessions).thenAnswer((_) => const Stream.empty());
    when(() => social.currentSession).thenAnswer((_) => session);
    when(
      () => social.isWalkShared('w1'),
    ).thenAnswer((_) async => const Ok(false));
    getIt
      ..registerFactory<WalkDetailCubit>(() => WalkDetailCubit(useCase, sharer))
      ..registerFactory<WalkShareCubit>(
        () => WalkShareCubit(social, availability),
      )
      ..registerSingleton<TileProvider>(StubTileProvider());
  });
  tearDown(getIt.reset);

  /// 지도 애니메이션이 남지 않도록 페이지를 내린다.
  Future<void> disposePage(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('지도 · 통계 · 반려견 · 메모가 보인다', (tester) async {
    await pumpApp(
      tester,
      WalkDetailPage(
        onSignIn: () {},
        walkId: 'w1',
        onEdit: (_) async {},
        onDeleted: () {},
      ),
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

  testWidgets('지도의 OSM 출처 표시가 지도 안에 보인다', (tester) async {
    await pumpApp(
      tester,
      WalkDetailPage(
        onSignIn: () {},
        walkId: 'w1',
        onEdit: (_) async {},
        onDeleted: () {},
      ),
    );

    final attribution = find.byType(SimpleAttributionWidget);
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);
    final label = tester.getRect(
      find.descendant(of: attribution, matching: find.byType(ColoredBox)),
    );
    final map = tester.getRect(find.byKey(const Key('walk-detail-map')));
    expect(map.contains(label.topLeft), isTrue);
    expect(label.bottom, lessThanOrEqualTo(map.bottom));
    await disposePage(tester);
  });

  testWidgets('메모는 손글씨, 사진은 본문 폭 4:3 · 모서리 4 다', (tester) async {
    await pumpApp(
      tester,
      WalkDetailPage(
        onSignIn: () {},
        walkId: 'w1',
        onEdit: (_) async {},
        onDeleted: () {},
      ),
    );

    expect(
      tester.widget<Text>(find.byKey(const Key('walk-detail-memo'))).style,
      PawlogTextStyles.of(
        tester.element(find.byKey(const Key('walk-detail-memo'))),
      ).memo,
    );
    final photo = find.byKey(const Key('walk-detail-photo-0'));
    expect(
      tester
          .widget<AspectRatio>(
            find.ancestor(of: photo, matching: find.byType(AspectRatio)),
          )
          .aspectRatio,
      PawlogSize.photoAspect,
    );
    expect(
      tester
          .widget<ClipRRect>(
            find.ancestor(of: photo, matching: find.byType(ClipRRect)).first,
          )
          .borderRadius,
      PawlogRadius.photoAll,
    );
    await disposePage(tester);
  });

  testWidgets('점이 없으면 경로 없음 안내를 보인다', (tester) async {
    when(
      () => useCase.getWalkTrack('w1'),
    ).thenAnswer((_) async => const Ok([]));
    await pumpApp(
      tester,
      WalkDetailPage(
        onSignIn: () {},
        walkId: 'w1',
        onEdit: (_) async {},
        onDeleted: () {},
      ),
    );

    expect(find.text('기록된 경로가 없습니다'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('메모와 사진이 없으면 그 절을 생략한다', (tester) async {
    when(() => useCase.getWalk('w1')).thenAnswer((_) async => Ok(walk()));
    await pumpApp(
      tester,
      WalkDetailPage(
        onSignIn: () {},
        walkId: 'w1',
        onEdit: (_) async {},
        onDeleted: () {},
      ),
    );

    expect(find.byKey(const Key('walk-detail-memo')), findsNothing);
    expect(find.byKey(const Key('walk-detail-photo-0')), findsNothing);
    await disposePage(tester);
  });

  testWidgets('불러오기 실패는 안내와 다시 시도를 보인다', (tester) async {
    when(() => useCase.getWalk('w1')).thenAnswer((_) async => const Ok(null));
    await pumpApp(
      tester,
      WalkDetailPage(
        onSignIn: () {},
        walkId: 'w1',
        onEdit: (_) async {},
        onDeleted: () {},
      ),
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
        onSignIn: () {},
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
        onSignIn: () {},
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
        onSignIn: () {},
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
        onSignIn: () {},
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

  group('GPX로 내보내기', () {
    void stubSharer(Result<void> result) => when(
      () => sharer.shareFile(
        fileName: any(named: 'fileName'),
        contents: any(named: 'contents'),
        mimeType: any(named: 'mimeType'),
      ),
    ).thenAnswer((_) async => result);

    Future<void> tapExport(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('walk-detail-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('walk-detail-export')));
      await tester.pumpAndSettle();
    }

    testWidgets('더보기 메뉴에 수정 · 내보내기 · 삭제가 차례로 있다', (tester) async {
      await pumpApp(
        tester,
        WalkDetailPage(
          onSignIn: () {},
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () {},
        ),
      );

      await tester.tap(find.byKey(const Key('walk-detail-menu')));
      await tester.pumpAndSettle();

      expect(find.text('GPX로 내보내기'), findsOneWidget);
      final edit = tester.getTopLeft(find.text('수정')).dy;
      final export = tester.getTopLeft(find.text('GPX로 내보내기')).dy;
      final delete = tester.getTopLeft(find.text('삭제')).dy;
      expect(edit < export && export < delete, isTrue);
      await disposePage(tester);
    });

    testWidgets('경로가 없으면 스낵바만 띄우고 공유하지 않는다', (tester) async {
      when(
        () => useCase.getWalkTrack('w1'),
      ).thenAnswer((_) async => const Ok([]));
      await pumpApp(
        tester,
        WalkDetailPage(
          onSignIn: () {},
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () {},
        ),
      );

      await tapExport(tester);

      expect(find.text('경로가 없어 내보낼 수 없어요'), findsOneWidget);
      verifyZeroInteractions(sharer);
      await disposePage(tester);
    });

    testWidgets('경로가 있으면 GPX 를 공유하고 스낵바는 없다', (tester) async {
      stubSharer(const Ok(null));
      await pumpApp(
        tester,
        WalkDetailPage(
          onSignIn: () {},
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () {},
        ),
      );

      await tapExport(tester);

      verify(
        () => sharer.shareFile(
          fileName: any(named: 'fileName', that: endsWith('.gpx')),
          contents: any(named: 'contents', that: contains('<trkpt')),
          mimeType: 'application/gpx+xml',
        ),
      ).called(1);
      expect(find.byType(SnackBar), findsNothing);
      await disposePage(tester);
    });

    testWidgets('공유가 실패하면 실패 스낵바를 보인다', (tester) async {
      stubSharer(const Err(Failure.unknown()));
      await pumpApp(
        tester,
        WalkDetailPage(
          onSignIn: () {},
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () {},
        ),
      );

      await tapExport(tester);

      expect(find.text('내보내지 못했어요'), findsOneWidget);
      expect(find.byKey(const Key('walk-detail-map')), findsOneWidget);
      await disposePage(tester);
    });
  });

  group('즐겨찾기 별', () {
    Finder star() => find.byKey(const Key('walk-detail-favorite'));
    IconButton starButton(WidgetTester tester) =>
        tester.widget<IconButton>(star());

    testWidgets('즐겨찾기가 아니면 빈 별 · 추가 툴팁', (tester) async {
      await pumpApp(
        tester,
        WalkDetailPage(
          onSignIn: () {},
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () {},
        ),
      );

      expect(
        find.descendant(of: star(), matching: find.byIcon(Icons.star_border)),
        findsOneWidget,
      );
      expect(starButton(tester).tooltip, '즐겨찾기에 추가');
      await disposePage(tester);
    });

    testWidgets('즐겨찾기면 꽉 찬 별 · 빼기 툴팁', (tester) async {
      when(
        () => useCase.getWalk('w1'),
      ).thenAnswer((_) async => Ok(fullWalk.copyWith(isFavorite: true)));
      await pumpApp(
        tester,
        WalkDetailPage(
          onSignIn: () {},
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () {},
        ),
      );

      expect(
        find.descendant(of: star(), matching: find.byIcon(Icons.star)),
        findsOneWidget,
      );
      expect(starButton(tester).tooltip, '즐겨찾기에서 빼기');
      await disposePage(tester);
    });

    testWidgets('누르면 setWalkFavorite(id, true) 후 별이 켜진다', (tester) async {
      when(
        () => useCase.setWalkFavorite('w1', true),
      ).thenAnswer((_) async => const Ok(null));
      await pumpApp(
        tester,
        WalkDetailPage(
          onSignIn: () {},
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () {},
        ),
      );

      await tester.tap(star());
      await tester.pumpAndSettle();

      verify(() => useCase.setWalkFavorite('w1', true)).called(1);
      expect(
        find.descendant(of: star(), matching: find.byIcon(Icons.star)),
        findsOneWidget,
      );
      await disposePage(tester);
    });

    testWidgets('실패하면 스낵바를 보이고 별은 그대로', (tester) async {
      when(
        () => useCase.setWalkFavorite('w1', true),
      ).thenAnswer((_) async => const Err(Failure.network()));
      await pumpApp(
        tester,
        WalkDetailPage(
          onSignIn: () {},
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () {},
        ),
      );

      await tester.tap(star());
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(of: star(), matching: find.byIcon(Icons.star_border)),
        findsOneWidget,
      );
      await disposePage(tester);
    });

    testWidgets('저장 중에 다시 누르면 무시한다', (tester) async {
      final pending = Completer<Result<void>>();
      when(
        () => useCase.setWalkFavorite('w1', true),
      ).thenAnswer((_) => pending.future);
      await pumpApp(
        tester,
        WalkDetailPage(
          onSignIn: () {},
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () {},
        ),
      );

      await tester.tap(star());
      await tester.pump();
      await tester.tap(star());
      await tester.pump();
      pending.complete(const Ok(null));
      await tester.pumpAndSettle();

      verify(() => useCase.setWalkFavorite('w1', true)).called(1);
      expect(
        find.descendant(of: star(), matching: find.byIcon(Icons.star)),
        findsOneWidget,
      );
      await disposePage(tester);
    });

    testWidgets('삭제 중에는 별이 흐린 색이라 꺼진 것으로 보인다', (tester) async {
      final pending = Completer<Result<void>>();
      when(() => useCase.deleteWalk('w1')).thenAnswer((_) => pending.future);
      await pumpApp(
        tester,
        WalkDetailPage(
          onSignIn: () {},
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () {},
        ),
      );
      Color? starColor() => tester
          .widget<Icon>(
            find.descendant(of: star(), matching: find.byType(Icon)),
          )
          .color;
      final colors = PawlogColors.of(tester.element(star()));
      expect(starColor(), colors.primary);

      await tester.tap(find.byKey(const Key('walk-detail-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('삭제'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(starButton(tester).onPressed, isNull);
      expect(starColor(), colors.textMuted);
      pending.complete(const Err(Failure.unknown()));
      await tester.pumpAndSettle();
      await disposePage(tester);
    });
  });

  group('모두에게 공유', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('walk-detail-menu')));
      await tester.pumpAndSettle();
    }

    Future<void> tapShare(WidgetTester tester) async {
      await openMenu(tester);
      await tester.tap(find.byKey(const Key('walk-detail-share')));
      await tester.pumpAndSettle();
    }

    Future<void> pumpDetail(WidgetTester tester, {VoidCallback? onSignIn}) =>
        pumpApp(
          tester,
          WalkDetailPage(
            walkId: 'w1',
            onEdit: (_) async {},
            onDeleted: () {},
            onSignIn: onSignIn ?? () {},
          ),
        );

    testWidgets('공유 안 된 산책은 내보내기와 삭제 사이에 "모두에게 공유"', (tester) async {
      await pumpDetail(tester);
      await openMenu(tester);

      final export = tester.getTopLeft(find.text('GPX로 내보내기')).dy;
      final share = tester.getTopLeft(find.text('모두에게 공유')).dy;
      final delete = tester.getTopLeft(find.text('삭제')).dy;
      expect(export < share && share < delete, isTrue);
      await disposePage(tester);
    });

    testWidgets('공유된 산책은 "공유 취소"', (tester) async {
      when(
        () => social.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(true));
      await pumpDetail(tester);
      await openMenu(tester);

      expect(find.text('공유 취소'), findsOneWidget);
      expect(find.text('모두에게 공유'), findsNothing);
      await disposePage(tester);
    });

    testWidgets('로그인하지 않았어도 "모두에게 공유" 가 보이고 누르면 로그인으로', (tester) async {
      session = null;
      var signIn = 0;
      await pumpDetail(tester, onSignIn: () => signIn++);

      await tapShare(tester);

      expect(signIn, 1);
      verifyNever(() => social.shareWalk(any()));
      await disposePage(tester);
    });

    testWidgets('Supabase 를 쓸 수 없으면 공유 항목이 없다', (tester) async {
      availability = const SocialAvailability.unavailable();
      await pumpDetail(tester);
      await openMenu(tester);

      expect(find.byKey(const Key('walk-detail-share')), findsNothing);
      expect(find.text('GPX로 내보내기'), findsOneWidget);
      await disposePage(tester);
    });

    testWidgets('공유하면 스낵바를 보이고 라벨이 "공유 취소" 로 바뀐다', (tester) async {
      when(
        () => social.shareWalk('w1'),
      ).thenAnswer((_) async => const Ok('p1'));
      await pumpDetail(tester);

      await tapShare(tester);

      expect(find.text('공유했어요'), findsOneWidget);
      expect(find.byType(WalkDetailPage), findsOneWidget);
      await openMenu(tester);
      expect(find.text('공유 취소'), findsOneWidget);
      await disposePage(tester);
    });

    testWidgets('공유 취소하면 스낵바를 보인다', (tester) async {
      when(
        () => social.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(true));
      when(
        () => social.unshareWalk('w1'),
      ).thenAnswer((_) async => const Ok(null));
      await pumpDetail(tester);

      await tapShare(tester);

      expect(find.text('공유를 취소했어요'), findsOneWidget);
      verify(() => social.unshareWalk('w1')).called(1);
      await disposePage(tester);
    });

    testWidgets('실패하면 실패 스낵바', (tester) async {
      when(
        () => social.shareWalk('w1'),
      ).thenAnswer((_) async => const Err(Failure.network()));
      await pumpDetail(tester);

      await tapShare(tester);

      expect(find.text('공유하지 못했어요'), findsOneWidget);
      await disposePage(tester);
    });

    testWidgets('공유 여부를 읽지 못하면 공유 항목을 숨긴다', (tester) async {
      when(
        () => social.isWalkShared('w1'),
      ).thenAnswer((_) async => const Err(Failure.network()));
      await pumpDetail(tester);
      await openMenu(tester);

      expect(find.byKey(const Key('walk-detail-share')), findsNothing);
      expect(find.text('삭제'), findsOneWidget);
      await disposePage(tester);
    });
  });

  group('공유한 산책 삭제', () {
    Future<int> deleteFromMenu(WidgetTester tester) async {
      var deleted = 0;
      await pumpApp(
        tester,
        WalkDetailPage(
          walkId: 'w1',
          onEdit: (_) async {},
          onDeleted: () => deleted++,
          onSignIn: () {},
        ),
      );
      await tester.tap(find.byKey(const Key('walk-detail-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('삭제'),
        ),
      );
      await tester.pumpAndSettle();
      return deleted;
    }

    setUp(() {
      when(
        () => useCase.deleteWalk('w1'),
      ).thenAnswer((_) async => const Ok(null));
      when(
        () => social.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(true));
    });

    testWidgets('공유한 산책을 지우면 공유를 먼저 취소하고 지운다', (tester) async {
      when(
        () => social.unshareWalk('w1'),
      ).thenAnswer((_) async => const Ok(null));

      final deleted = await deleteFromMenu(tester);

      verifyInOrder([
        () => social.unshareWalk('w1'),
        () => useCase.deleteWalk('w1'),
      ]);
      expect(deleted, 1);
      expect(find.text('산책은 지웠지만 공유를 취소하지 못했어요'), findsNothing);
      await disposePage(tester);
    });

    testWidgets('공유 취소가 실패해도 지우고 스낵바로 알린다', (tester) async {
      when(
        () => social.unshareWalk('w1'),
      ).thenAnswer((_) async => const Err(Failure.network()));

      final deleted = await deleteFromMenu(tester);

      verify(() => useCase.deleteWalk('w1')).called(1);
      expect(deleted, 1);
      expect(find.text('산책은 지웠지만 공유를 취소하지 못했어요'), findsOneWidget);
      await disposePage(tester);
    });

    testWidgets('로그인하지 않았으면 서버에 묻지 않고 지운다', (tester) async {
      session = null;

      final deleted = await deleteFromMenu(tester);

      verifyNever(() => social.unshareWalk(any()));
      verify(() => useCase.deleteWalk('w1')).called(1);
      expect(deleted, 1);
      await disposePage(tester);
    });
  });
}
