import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/data/social/supabase_auth_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockClient extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

User _user(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-10-17T00:00:00Z',
);

Session _session(String id) =>
    Session(accessToken: 't', tokenType: 'bearer', user: _user(id));

void main() {
  late _MockClient client;
  late _MockAuth auth;
  late SupabaseClientAuthGateway gateway;

  setUp(() {
    client = _MockClient();
    auth = _MockAuth();
    when(() => client.auth).thenReturn(auth);
    gateway = SupabaseClientAuthGateway(client);
  });

  test('가입은 닉네임을 user metadata 로 넘긴다', () async {
    when(
      () => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => AuthResponse(session: _session('u1'), user: _user('u1')),
    );

    final id = await gateway.signUp(
      email: ' a@b.com ',
      password: 'password1',
      nickname: ' 콩이네 ',
    );

    expect(id, 'u1');
    verify(
      () => auth.signUp(
        email: 'a@b.com',
        password: 'password1',
        data: {'nickname': '콩이네'},
      ),
    ).called(1);
  });

  test('이메일 확인이 켜져 세션이 없으면 signUpFailed 를 던진다', () async {
    when(
      () => auth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => AuthResponse(user: _user('u1')));

    expect(
      () => gateway.signUp(email: 'a@b.com', password: 'p', nickname: 'nn'),
      throwsA(
        isA<Failure>().having(
          (f) => f.failureCode,
          'failureCode',
          FailureCode.signUpFailed,
        ),
      ),
    );
  });

  test('로그인은 사용자 id 를 돌려준다', () async {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => AuthResponse(session: _session('u2'), user: _user('u2')),
    );

    expect(await gateway.signIn(email: 'a@b.com', password: 'p'), 'u2');
  });

  test('userIdChanges 는 토큰 갱신 · 비밀번호 복구를 건너뛴다', () async {
    final states = StreamController<AuthState>();
    when(() => auth.onAuthStateChange).thenAnswer((_) => states.stream);

    final emitted = <String?>[];
    final sub = gateway.userIdChanges.listen(emitted.add);
    addTearDown(sub.cancel);

    states
      ..add(const AuthState(AuthChangeEvent.initialSession, null))
      ..add(AuthState(AuthChangeEvent.signedIn, _session('u1')))
      ..add(AuthState(AuthChangeEvent.tokenRefreshed, _session('u1')))
      ..add(AuthState(AuthChangeEvent.passwordRecovery, _session('u1')))
      ..add(const AuthState(AuthChangeEvent.signedOut, null));
    await pumpEventQueue();

    expect(emitted, [null, 'u1', null]);
  });

  test('currentUserId 는 GoTrue 의 현재 사용자다', () {
    when(() => auth.currentUser).thenReturn(_user('u3'));

    expect(gateway.currentUserId, 'u3');
  });
}
