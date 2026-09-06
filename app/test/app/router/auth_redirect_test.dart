import 'package:daylog/app/router/auth_redirect.dart';
import 'package:daylog/app/router/routes.dart';
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
    expect(redirect(const AuthState.unauthenticated(), Routes.home), Routes.signIn);
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

  test('로그인·스플래시에서 인증되면 홈으로 가고, 보호 경로는 그대로 둔다', () {
    expect(redirect(const AuthState.authenticated(_me), Routes.signIn), Routes.home);
    expect(redirect(const AuthState.authenticated(_me), Routes.explore), Routes.home);
    expect(redirect(const AuthState.authenticated(_me), Routes.splash), Routes.home);
    expect(redirect(const AuthState.authenticated(_me), Routes.home), isNull);
    expect(redirect(const AuthState.authenticated(_me), Routes.profileSetup), isNull);
  });
}
