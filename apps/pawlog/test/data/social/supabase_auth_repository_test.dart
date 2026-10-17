import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/data/social/supabase_auth_repository.dart';
import 'package:pawlog/domain/social/entity/auth_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fake_auth_gateway.dart';

void main() {
  late FakeAuthGateway gateway;
  late SupabaseAuthRepository repository;

  setUp(() {
    gateway = FakeAuthGateway()..nicknames['u1'] = '콩이네';
    repository = SupabaseAuthRepository(gateway);
  });

  group('signIn', () {
    test('성공하면 profiles 의 닉네임으로 current 를 채운다', () async {
      final result = await repository.signIn('a@b.com', 'password1');

      expect(result, isA<Ok<void>>());
      expect(
        repository.current,
        const AuthSession(userId: 'u1', nickname: '콩이네'),
      );
    });

    test('틀린 자격은 invalidCredentials 로 바뀐다', () async {
      gateway.signInError = const AuthApiException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      );

      final result = await repository.signIn('a@b.com', 'wrong');

      expect(
        (result as Err).failure.failureCode,
        FailureCode.invalidCredentials,
      );
      expect(repository.current, isNull);
    });

    test('프로필 조회가 실패해도 로그인은 성공하고 닉네임만 비운다', () async {
      gateway.nicknameError = Exception('offline');

      final result = await repository.signIn('a@b.com', 'password1');

      expect(result, isA<Ok<void>>());
      expect(repository.current, const AuthSession(userId: 'u1', nickname: ''));
    });
  });

  group('signUp', () {
    test('닉네임을 넘기고 트리거가 만든 프로필 닉네임을 쓴다', () async {
      gateway.nicknames.clear();

      final result = await repository.signUp('a@b.com', 'password1', '콩이네');

      expect(result, isA<Ok<void>>());
      expect(gateway.calls, ['check 콩이네', 'signUp a@b.com 콩이네']);
      expect(repository.current?.nickname, '콩이네');
    });

    test('대소문자만 다른 닉네임이 이미 있으면 가입하지 않고 nicknameTaken', () async {
      gateway.nicknames['u0'] = 'Kong';

      final result = await repository.signUp('a@b.com', 'password1', 'kONG');

      expect((result as Err).failure.failureCode, FailureCode.nicknameTaken);
      expect(gateway.calls, ['check kONG']);
    });

    test('사전 확인이 실패해도 가입은 시도한다', () async {
      gateway
        ..nicknames.clear()
        ..nicknameCheckError = Exception('offline');

      final result = await repository.signUp('a@b.com', 'password1', '콩이네');

      expect(result, isA<Ok<void>>());
    });

    test('동시 가입 경합의 유일 위반도 nicknameTaken 으로 바뀐다', () async {
      gateway.nicknames.clear();
      // 로컬 GoTrue 는 트리거 실패를 500 + 본문 그대로 돌려주고, gotrue-dart 는
      // 그것을 AuthRetryableFetchException(message: 본문) 으로 던진다(2026-10-17 확인).
      gateway.signUpError = AuthRetryableFetchException(
        message:
            '{"code":"23505","message":"duplicate key value violates unique '
            'constraint \\"profiles_nickname_key\\""}',
        statusCode: '500',
      );

      final result = await repository.signUp('a@b.com', 'password1', '콩이네');

      expect((result as Err).failure.failureCode, FailureCode.nicknameTaken);
    });
  });

  test('signOut 하면 current 가 비워진다', () async {
    await repository.signIn('a@b.com', 'password1');

    final result = await repository.signOut();

    expect(result, isA<Ok<void>>());
    expect(repository.current, isNull);
  });

  test('current 는 세션만 있고 닉네임을 아직 못 읽었으면 빈 닉네임이다', () {
    gateway.currentUserId = 'u9';

    expect(repository.current, const AuthSession(userId: 'u9', nickname: ''));
  });

  test('sessions 는 사용자 변화를 닉네임이 붙은 세션으로 바꾼다', () async {
    final emitted = <AuthSession?>[];
    final sub = repository.sessions.listen(emitted.add);
    addTearDown(sub.cancel);

    gateway.userIds
      ..add('u1')
      ..add(null);
    await pumpEventQueue();

    expect(emitted, [const AuthSession(userId: 'u1', nickname: '콩이네'), null]);
  });
}
