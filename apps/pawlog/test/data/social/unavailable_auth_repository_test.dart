import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/data/social/unavailable_auth_repository.dart';

void main() {
  const repository = UnavailableAuthRepository();

  test('로그인되지 않은 상태로 보이고 모든 동작은 네트워크 실패다', () async {
    expect(repository.current, isNull);
    expect(await repository.sessions.toList(), [null]);

    final result = await repository.signIn('a@b.com', 'password1');

    expect((result as Err).failure.failureCode, FailureCode.networkUnavailable);
    expect(await repository.signOut(), isA<Ok<void>>());
  });
}
