import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/core/supabase/social_availability.dart';
import 'package:pawlog/domain/social/entity/auth_session.dart';
import 'package:pawlog/presentation/social/cubit/community_cubit.dart';
import 'package:pawlog/presentation/social/page/community_page.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';
import 'package:pawlog/presentation/walk/widget/route_sketch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/mock_social_use_case.dart';
import '../../../support/pump_app.dart';
import '../../../support/social_fakes.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSocialUseCase useCase;
  late SocialAvailability availability;
  late StreamController<AuthSession?> sessions;
  AuthSession? session;

  final p1 = walkPost('p1');
  final p2 = walkPost('p2', likedByMe: true, memo: null, routePreview: []);

  setUp(() {
    useCase = MockSocialUseCase();
    sessions = StreamController<AuthSession?>.broadcast();
    availability = SocialAvailability.available(_MockSupabaseClient());
    session = null;
    when(() => useCase.sessions).thenAnswer((_) => sessions.stream);
    when(() => useCase.currentSession).thenAnswer((_) => session);
    when(
      () => useCase.fetchCommunityPage(),
    ).thenAnswer((_) async => Ok(CursorPage(items: [p1, p2])));
    getIt.registerFactory<CommunityCubit>(
      () => CommunityCubit(useCase, availability),
    );
  });
  tearDown(() async {
    await sessions.close();
    await getIt.reset();
  });

  /// 두 글이 한 화면에 다 보이도록 세로로 긴 화면을 쓴다.
  Future<void> pump(WidgetTester tester, {VoidCallback? onSignIn}) {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return pumpApp(tester, CommunityPage(onSignIn: onSignIn ?? () {}));
  }

  Finder like(String id) => find.byKey(Key('community-like-$id'));

  testWidgets('글마다 닉네임 · 반려견 · 거리 · 시간 · 메모 · 하트가 보인다', (tester) async {
    await pump(tester);

    expect(find.text('모두의 산책'), findsOneWidget);
    expect(find.text('산책러p1'), findsOneWidget);
    expect(find.text('콩이, 보리'), findsNWidgets(2));
    expect(find.text('1.2 km'), findsNWidgets(2));
    expect(find.text('30분'), findsNWidgets(2));
    expect(find.text('공원 한 바퀴'), findsOneWidget);
    expect(like('p1'), findsOneWidget);
    expect(like('p2'), findsOneWidget);
  });

  testWidgets('경로가 있는 글만 경로 그림을 그리고 메모는 손글씨다', (tester) async {
    await pump(tester);

    expect(find.byType(RouteSketch), findsOneWidget);
    final memo = find.text('공원 한 바퀴');
    expect(
      tester.widget<Text>(memo).style,
      PawlogTextStyles.of(tester.element(memo)).memo,
    );
  });

  testWidgets('하트는 남색이고 내가 누른 글은 꽉 찬 하트', (tester) async {
    await pump(tester);

    final liked = tester.widget<AppCountAction>(like('p2'));
    expect(liked.isActive, isTrue);
    expect(liked.icon, Icons.favorite);
    expect(liked.count, 3);
    expect(
      tester.widget<AppCountAction>(like('p1')).icon,
      Icons.favorite_border,
    );
    expect(liked.tooltip, '좋아요');
  });

  testWidgets('로그인하지 않고 하트를 누르면 로그인으로', (tester) async {
    var signIn = 0;
    await pump(tester, onSignIn: () => signIn++);

    await tester.tap(like('p1'));
    await tester.pumpAndSettle();

    expect(signIn, 1);
    verifyNever(() => useCase.likePost(any()));
  });

  testWidgets('로그인했으면 하트가 바로 켜지고 수가 는다', (tester) async {
    session = alice;
    when(() => useCase.likePost('p1')).thenAnswer((_) async => const Ok(null));
    await pump(tester);

    await tester.tap(like('p1'));
    await tester.pumpAndSettle();

    final button = tester.widget<AppCountAction>(like('p1'));
    expect(button.isActive, isTrue);
    expect(button.count, 4);
  });

  testWidgets('좋아요가 실패하면 되돌리고 스낵바', (tester) async {
    session = alice;
    when(
      () => useCase.likePost('p1'),
    ).thenAnswer((_) async => const Err(Failure.network()));
    await pump(tester);

    await tester.tap(like('p1'));
    await tester.pumpAndSettle();

    expect(tester.widget<AppCountAction>(like('p1')).isActive, isFalse);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('빈 목록은 안내 한 줄', (tester) async {
    when(
      () => useCase.fetchCommunityPage(),
    ).thenAnswer((_) async => const Ok(CursorPage(items: [])));
    await pump(tester);

    expect(find.text('아직 공유된 산책이 없어요'), findsOneWidget);
  });

  testWidgets('불러오기 실패는 안내와 다시 시도', (tester) async {
    when(
      () => useCase.fetchCommunityPage(),
    ).thenAnswer((_) async => const Err(Failure.network()));
    await pump(tester);

    expect(find.text('모두의 산책을 불러오지 못했어요'), findsOneWidget);
    when(
      () => useCase.fetchCommunityPage(),
    ).thenAnswer((_) async => Ok(CursorPage(items: [p1])));
    await tester.tap(find.byKey(const Key('community-retry')));
    await tester.pumpAndSettle();

    expect(find.text('산책러p1'), findsOneWidget);
  });

  testWidgets('Supabase 를 쓸 수 없으면 다시 시도 없이 안내만, 더보기도 없다', (tester) async {
    availability = const SocialAvailability.unavailable();
    await pump(tester);

    expect(find.text('모두의 산책을 불러오지 못했어요'), findsOneWidget);
    expect(find.byKey(const Key('community-retry')), findsNothing);
    expect(find.byKey(const Key('community-more')), findsNothing);
  });

  testWidgets('끝까지 내리면 다음 페이지를 읽고 끝 안내는 없다', (tester) async {
    final first = [for (var i = 0; i < 20; i++) walkPost('a$i')];
    when(
      () => useCase.fetchCommunityPage(),
    ).thenAnswer((_) async => Ok(CursorPage(items: first, nextCursor: 'c1')));
    when(
      () => useCase.fetchCommunityPage(after: 'c1'),
    ).thenAnswer((_) async => Ok(CursorPage(items: [walkPost('b0')])));
    await pump(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -20000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    verify(() => useCase.fetchCommunityPage(after: 'c1')).called(1);
    expect(find.text('산책러b0'), findsOneWidget);
    expect(find.text('모두 확인했습니다'), findsNothing);
  });

  testWidgets('더 읽기가 실패하면 스낵바 한 번 · 스크롤로는 다시 읽지 않고 "다시 시도" 로 읽는다', (
    tester,
  ) async {
    final first = [for (var i = 0; i < 20; i++) walkPost('a$i')];
    when(
      () => useCase.fetchCommunityPage(),
    ).thenAnswer((_) async => Ok(CursorPage(items: first, nextCursor: 'c1')));
    when(
      () => useCase.fetchCommunityPage(after: 'c1'),
    ).thenAnswer((_) async => const Err(Failure.network()));
    await pump(tester);

    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pump();
    }
    await tester.pump();

    verify(() => useCase.fetchCommunityPage(after: 'c1')).called(1);
    expect(find.byType(SnackBar), findsOneWidget);
    final retry = find.byKey(const Key('community-load-more-retry'));
    expect(retry, findsOneWidget);

    when(
      () => useCase.fetchCommunityPage(after: 'c1'),
    ).thenAnswer((_) async => Ok(CursorPage(items: [walkPost('b0')])));
    await tester.tap(retry);
    await tester.pumpAndSettle();

    verify(() => useCase.fetchCommunityPage(after: 'c1')).called(1);
    expect(find.text('산책러b0'), findsOneWidget);
    expect(retry, findsNothing);
  });

  testWidgets('당겨서 새로고침하면 첫 페이지를 다시 읽는다', (tester) async {
    await pump(tester);

    await tester.timedDrag(
      find.byType(ListView),
      const Offset(0, 600),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    verify(() => useCase.fetchCommunityPage()).called(2);
  });

  testWidgets('로그아웃 상태면 더보기에 "로그인", 누르면 로그인으로', (tester) async {
    var signIn = 0;
    await pump(tester, onSignIn: () => signIn++);

    await tester.tap(find.byKey(const Key('community-more')));
    await tester.pumpAndSettle();
    expect(find.text('로그아웃'), findsNothing);
    await tester.tap(find.byKey(const Key('community-sign-in')));
    await tester.pumpAndSettle();

    expect(signIn, 1);
  });

  testWidgets('로그인 상태면 더보기에 "로그아웃", 누르면 signOut', (tester) async {
    session = alice;
    when(() => useCase.signOut()).thenAnswer((_) async {
      session = null;
      sessions.add(null);
      return const Ok(null);
    });
    await pump(tester);

    await tester.tap(find.byKey(const Key('community-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('community-sign-out')));
    await tester.pumpAndSettle();

    verify(() => useCase.signOut()).called(1);
    await tester.tap(find.byKey(const Key('community-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('community-sign-in')), findsOneWidget);
  });
}
