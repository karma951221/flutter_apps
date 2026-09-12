import 'package:daylog/app/router/auth_redirect.dart';
import 'package:core/core.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

void main() {
  String? redirect(AuthState state, String location) =>
      resolveAuthRedirect(authState: state, location: location);

  test('세션을 읽는 중에는 스플래시에 머문다', () {
    expect(redirect(const AuthState.unknown(), Routes.splash), isNull);
    expect(redirect(const AuthState.unknown(), Routes.home), Routes.splash);
  });

  test('미인증은 공개 경로만 허용하고 나머지는 로그인으로 보낸다', () {
    expect(redirect(const AuthState.unauthenticated(), Routes.signIn), isNull);
    expect(redirect(const AuthState.unauthenticated(), Routes.signUp), isNull);
    expect(redirect(const AuthState.unauthenticated(), Routes.explore), isNull);
    expect(
      redirect(const AuthState.unauthenticated(), Routes.home),
      Routes.signIn,
    );
    expect(
      redirect(const AuthState.unauthenticated(), Routes.profileSetup),
      Routes.signIn,
    );
  });

  test('가입 화면에서 인증되면 홈이 아니라 프로필 꾸미기로 간다', () {
    expect(
      redirect(const AuthState.authenticated(_me), Routes.signUp),
      Routes.profileSetup,
    );
  });

  test('판 결과는 로그인 여부와 무관하게 그대로 열린다', () {
    // 공유된 링크 하나가 게스트에게도 로그인 사용자에게도 같은 화면이어야
    // 한다. 공개 경로처럼 로그인 사용자를 홈으로 돌려보내지 않는다.
    const result = '/trade/6f1a2b3c-0000-4000-8000-000000000001/result';
    expect(redirect(const AuthState.unauthenticated(), result), isNull);
    expect(redirect(const AuthState.authenticated(_me), result), isNull);
    // 세션을 아직 모르는 동안은 여전히 스플래시다.
    expect(redirect(const AuthState.unknown(), result), Routes.splash);
  });

  test('판 진행 화면은 열린 경로가 아니다', () {
    // 진행 중인 판은 자기 것만 읽을 수 있다. 게스트는 로그인부터다.
    expect(
      redirect(
        const AuthState.unauthenticated(),
        Routes.tradeSessionPath('s1'),
      ),
      Routes.signIn,
    );
    // 결과 경로와 한 글자 다른 자리도 열리지 않는다.
    expect(
      redirect(const AuthState.unauthenticated(), '/trade/s1/results'),
      Routes.signIn,
    );
    expect(
      redirect(const AuthState.unauthenticated(), '/trade/s1/result/extra'),
      Routes.signIn,
    );
  });

  test('로그인·스플래시에서 인증되면 홈으로 가고, 보호 경로는 그대로 둔다', () {
    expect(
      redirect(const AuthState.authenticated(_me), Routes.signIn),
      Routes.home,
    );
    expect(
      redirect(const AuthState.authenticated(_me), Routes.explore),
      Routes.home,
    );
    expect(
      redirect(const AuthState.authenticated(_me), Routes.splash),
      Routes.home,
    );
    expect(redirect(const AuthState.authenticated(_me), Routes.home), isNull);
    expect(
      redirect(const AuthState.authenticated(_me), Routes.profileSetup),
      isNull,
    );
  });
}
