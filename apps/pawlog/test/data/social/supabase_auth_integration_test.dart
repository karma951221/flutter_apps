@Tags(['integration'])
library;

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/core/config/app_config.dart';
import 'package:pawlog/data/social/supabase_auth_gateway.dart';
import 'package:pawlog/data/social/supabase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 로컬 Supabase(`supabase start`)에 실제로 가입 · 로그인해 본다. 기본 `flutter test` 는
/// 건너뛴다(dart_test.yaml). 실행: `flutter test --run-skipped -t integration`.
///
/// `testWidgets` 바인딩은 HTTP 를 막으므로 plain `test` 만 쓴다.
void main() {
  late SupabaseClient client;
  late SupabaseAuthRepository repository;
  final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final email = 'pawlog_$stamp@example.com';
  final nickname = 'pw$stamp';

  setUp(() {
    client = SupabaseClient(
      'http://127.0.0.1:54321',
      AppConfig.localPublishableKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
      ),
    );
    repository = SupabaseAuthRepository(SupabaseClientAuthGateway(client));
  });
  tearDown(() => client.dispose());

  test('가입 → 로그아웃 → 로그인, 닉네임은 profiles 에서 온다', () async {
    final signUp = await repository.signUp(email, 'password123', nickname);
    expect(signUp, isA<Ok<void>>(), reason: '$signUp');
    expect(repository.current?.nickname, nickname);

    expect(await repository.signOut(), isA<Ok<void>>());
    expect(repository.current, isNull);

    final signIn = await repository.signIn(email, 'password123');
    expect(signIn, isA<Ok<void>>(), reason: '$signIn');
    expect(repository.current?.nickname, nickname);
  });

  test('대소문자만 다른 닉네임으로 가입하면 nicknameTaken', () async {
    final result = await repository.signUp(
      'other_$email',
      'password123',
      nickname.toUpperCase(),
    );

    expect(
      switch (result) {
        Err(:final failure) => failure.failureCode,
        Ok() => null,
      },
      FailureCode.nicknameTaken,
      reason: switch (result) {
        Err(:final failure) => '$failure',
        Ok() => 'ok',
      },
    );
  });

  test('틀린 비밀번호는 invalidCredentials', () async {
    final result = await repository.signIn(email, 'wrong-password');

    expect(
      switch (result) {
        Err(:final failure) => failure.failureCode,
        Ok() => null,
      },
      FailureCode.invalidCredentials,
      reason: switch (result) {
        Err(:final failure) => '$failure',
        Ok() => 'ok',
      },
    );
  });
}
