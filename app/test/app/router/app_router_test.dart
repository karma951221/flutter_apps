import 'package:daylog/app/router/app_router.dart';
import 'package:daylog/app/router/routes.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

/// 화면을 짓지 않고 라우트 표만 본다.
///
/// `/trade/:sessionId` 와 `/trade/:sessionId/result` 는 앞 두 세그먼트가 같다.
/// 등록 순서나 패턴을 잘못 두면 `result` 가 sessionId 로 잡혀 결과 링크가
/// 진행 화면으로 열린다 — 공유 링크가 통째로 망가지는 종류의 실수라서,
/// 화면이 아니라 매칭 자체를 검사한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoRouter buildRouter() {
    final authBloc = _MockAuthBloc();
    when(() => authBloc.state).thenReturn(
      const AuthState.authenticated(
        AppUser(id: 'u1', email: 'me@example.com', nickname: '나'),
      ),
    );
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
    final router = createRouter(authBloc);
    addTearDown(router.dispose);
    return router;
  }

  String matchedPath(GoRouter router, String location) {
    final matches = router.configuration.findMatch(Uri.parse(location));
    expect(matches.isError, isFalse, reason: '$location 에 맞는 라우트가 없다');
    return (matches.matches.last as RouteMatch).route.path;
  }

  test('/trade/:sessionId 는 판 진행 화면 라우트로 간다', () {
    final router = buildRouter();

    expect(matchedPath(router, '/trade/abc'), Routes.tradeSession);
    expect(
      router.configuration
          .findMatch(Uri.parse('/trade/abc'))
          .pathParameters['sessionId'],
      'abc',
    );
  });

  test('/trade/:sessionId/result 는 여전히 결과 화면 라우트로 간다', () {
    final router = buildRouter();

    expect(matchedPath(router, '/trade/abc/result'), Routes.tradeResult);
    // 'result' 가 sessionId 로 잡히지 않는다.
    expect(
      router.configuration
          .findMatch(Uri.parse('/trade/abc/result'))
          .pathParameters['sessionId'],
      'abc',
    );
  });
}
